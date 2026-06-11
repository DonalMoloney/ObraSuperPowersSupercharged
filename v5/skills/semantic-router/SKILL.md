---
name: semantic-router
description: Use at the start of any request — embeds the task and does semantic kNN over the Pinecone skill index with cross-encoder reranking, asking instead of guessing on low-confidence ties. Replaces keyword matching in skill-router.
author: Donal Moloney
track: entry
type: process
chains-to: ~
---

## Not this skill if
- Pinecone index isn't built — run `index-skills` first
- A greeting / one-word ack — skip routing entirely
- The request names a skill directly ("run map-reduce-sweep") — dispatch it without routing overhead

# semantic-router — match by meaning, not keywords

## Purpose

Stop missing the right skill on keyword mismatch. Embed the request, retrieve the nearest skills by
meaning, rerank, and only act when confident — otherwise ask.

## Core rule

> **Rule:** If the top two candidates are within ε, surface a disambiguation question instead of
> guessing.

## Triggers

**Use when:**
- The request is non-trivial and no explicit skill name appears in it
- Keyword routing returned no match or a low-confidence match
- The request is phrased in domain language that doesn't map neatly to skill names
- Two or more skills feel plausible and the distinction matters for the user's outcome
- You are operating at the entry track and need to route before doing any real work

**Don't use when:**
- The Pinecone skill index has not been built — `index-skills` must run first
- The request is a one-word acknowledgement, greeting, or trivially out-of-scope
- The user explicitly names a skill — trust the explicit name and skip the router
- The context window is already exhausted — a lightweight keyword fallback is safer than an embed round-trip

## Algorithm

Embed `name + description + trigger phrases` per skill (via `index-skills`). At request time: embed
the task → **kNN over cosine similarity** → **cross-encoder rerank** the top-k → **confidence
threshold + margin check**.

## Steps

### 1. Embed the request

Convert the full user request to a dense vector using the same embedding model used to build the
skill index (consistency is mandatory — a mismatch between index-time and query-time models silently
degrades recall). Strip filler words but keep domain nouns and verb phrases; they carry the most
semantic weight.

- If the request is multi-sentence, embed the whole text as one unit; do not split into per-sentence
  queries and merge scores manually.
- Record the raw request text alongside the embedding so the disambiguation question (step 4) can
  quote it back accurately.

### 2. Query Pinecone for top-k nearest skills

Issue a `search-records` call against the skill index, requesting the top-k results by cosine
similarity (k = 5 is a safe default; raise to 8 for wide, ambiguous requests). Each result returns
the skill name, its stored description, and a raw similarity score.

- Use the namespace that matches the current repo's skill set; do not query a stale namespace from a
  previous build.
- Retain the full top-k list for the rerank step; do not discard lower-ranked results yet — the
  cross-encoder frequently inverts the bi-encoder ordering.

### 3. Rerank the top-k with a cross-encoder

Pass the original request text and each candidate skill's concatenated `name + description +
trigger phrases` through `rerank-documents`. The cross-encoder reads both texts jointly, producing
a calibrated relevance score that corrects for surface similarity traps.

- Replace the bi-encoder scores with the cross-encoder scores; use cross-encoder ranks exclusively
  from this point forward.
- If fewer than two candidates survive above a minimum cross-encoder score (0.10 is a reasonable
  floor), treat the result set as empty and proceed to the "no skill applies" branch in step 4.

### 4. Apply threshold and margin checks, then route

Evaluate the reranked list with two checks in order:

**Threshold check:** If `top-1 score < threshold` (default 0.40), conclude no skill applies.
Return a structured "no skill applies" signal and optionally fall back to a direct answer without a
skill wrapper.

**Margin check:** If `top-1 score >= threshold` but `(top-1 score − top-2 score) < ε` (default
0.08), the two candidates are too close to choose safely. Surface a disambiguation question that
names both candidates and their distinguishing triggers, then wait for the user's answer before
routing.

**Confident route:** If `top-1 score >= threshold` and the margin is clear, dispatch to the top-1
skill. Log the chosen skill name and its score so the session trace is auditable.

Decision matrix:

| top-1 score | margin (top-1 − top-2) | Action |
|---|---|---|
| < threshold | any | "No skill applies" signal |
| >= threshold | < ε | Disambiguation question |
| >= threshold | >= ε | Route to top-1 skill |

## Common mistakes / Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Using a different embedding model at query time than at index time | Lock the model name in the index metadata and assert a match before querying |
| Discarding lower bi-encoder ranks before reranking | Keep the full top-k list; cross-encoder frequently promotes a rank-3 or rank-4 result |
| Setting ε too large — nearly every tie triggers a question | Start ε at 0.08; only widen it if users report repeated unnecessary disambiguation prompts |
| Setting threshold too low — garbage matches route confidently | Keep threshold >= 0.40; below that the match is noise, not signal |
| Embedding only the first sentence of a multi-sentence request | Embed the full request as one unit; domain verbs and object nouns often appear late |
| Routing silently without logging the chosen skill and score | Always log `routed → <skill> (score: 0.XX)` so the session trace is auditable |

## Verification / Proof

After routing, confirm the outcome is auditable before closing the entry step.

The output must contain:
- The original request text (verbatim, not paraphrased)
- The top-k candidates with their cross-encoder scores
- The threshold and ε values used
- The routing decision: routed skill name, disambiguation question text, or "no skill applies"
- If routed: the score and margin that cleared the threshold

```
PROVEN BY:
  request: "<verbatim request text>"
  top candidates: [<skill-name> (<score>), <skill-name> (<score>), ...]
  threshold: 0.40 | ε: 0.08
  decision: routed → <skill-name> | disambiguation | no skill applies
  margin: <top-1 score> − <top-2 score> = <margin>
```

## Adapt from
- **`sentence-transformers`** semantic-search (embed corpus, kNN by meaning) + Pinecone
  `rerank-documents`. <https://www.sbert.net>
