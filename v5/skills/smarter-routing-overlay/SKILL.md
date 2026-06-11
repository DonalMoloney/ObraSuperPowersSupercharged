---
name: smarter-routing-overlay
description: Use alongside semantic-router — a cheap BM25 keyword prefilter narrows the field before the semantic check, skills can rule themselves out, the router prints why it fired, and confidence tiers decide act-vs-ask.
author: Donal Moloney
track: entry
type: process
chains-to: semantic-router
---

## Not this skill if
- `semantic-router` isn't in place — this is its speed/explainability layer
- You have fewer than 10 registered skills — the prefilter overhead exceeds its savings at that scale
- The routing problem is purely keyword-based with no semantic ambiguity — skip the overlay and match directly

# smarter-routing-overlay — fast, explainable routing

## Purpose

Make routing cheap and debuggable: don't embed every skill every turn, let skills opt out, and never
fire silently. BM25 keyword scoring cuts the candidate pool before the embedding pass runs, so the
expensive semantic step only sees a short shortlist. Every decision is traceable: one printed line
names the winning skill and the confidence tier that drove the choice.

## Core rule

> **Rule:** Every routing decision prints one line saying *why*. Sure → act; somewhat → say so and
> act; unsure → ask.

## Triggers

**Use when:**
- Routing latency is noticeable because every skill is embedded on every turn
- A routing decision fired the wrong skill and you need an audit trail
- You want skills to self-exclude using declarative `skip-when` guards rather than inline conditionals
- The skill registry has grown past ~15 entries and recall is degrading
- You are building or tuning `semantic-router` and need an explainability wrapper

**Don't use when:**
- `semantic-router` is not installed — this overlay wraps it, it does not replace it
- The skill set is small and static; embedding cost is negligible
- You need routing by capability graph rather than text similarity — use `skill-dependency-graph` instead

## Algorithm

**BM25/TF-IDF** keyword prefilter selects a candidate shortlist → `semantic-router` reranks only
those candidates. `skip-when` frontmatter rules drop self-excluded skills before the semantic pass.
Confidence tiers gate act-vs-ask behaviour on the final ranked result.

The full pipeline:

```
request
  → BM25 score all skill descriptions
  → keep top-N candidates (N ≤ 8 recommended)
  → apply skip-when guards on each candidate
  → hand shortlist to semantic-router
  → receive ranked result + score
  → map score to confidence tier
  → print decision line
  → act / ask / escalate
```

## Steps

### 1. BM25 prefilter

Score the incoming request text against every registered skill's `description` field using BM25 (prefer `bm25s` for throughput; fall back to `rank_bm25` if already installed). Rank all skills by BM25 score. Take the top-N candidates — **default N = 8**; raise only if the skill set is unusually dense. Log how many skills were dropped and why before the semantic pass starts. No silent caps.

> Example drop-log: `BM25 prefilter: 31 skills scored, 23 dropped, 8 forwarded to semantic-router.`

### 2. Apply skip-when guards

For each candidate in the shortlist, read its `skip-when` frontmatter field (a list of plain-English conditions). Evaluate each guard against the current request context. Drop any candidate whose guard fires. Record which guards triggered — this forms part of the decision trail. A skill with no `skip-when` field passes through unchanged.

Sub-steps:
- Parse `skip-when` as a YAML list; treat a missing field as an empty list.
- Evaluate guards in order; short-circuit on the first match.
- Append each dropped skill and the guard that fired to the decision log.

### 3. Hand shortlist to semantic-router

Pass the surviving candidates (skill names + descriptions) to `semantic-router` as its restricted search scope. Let `semantic-router` perform its normal embedding-based reranking. Receive back the top-ranked skill and its similarity score. Do not second-guess the semantic result at this stage — the BM25 stage already filtered; trust the reranker output.

### 4. Map score to confidence tier

Convert the similarity score to one of three tiers using fixed thresholds (adjust per deployment):

| Score range | Tier | Behaviour |
|---|---|---|
| ≥ 0.85 | **Sure** | Act immediately; no confirmation |
| 0.65 – 0.84 | **Likely** | State the chosen skill and act; user can interrupt |
| < 0.65 | **Unsure** | Ask: "Did you mean X? Or were you thinking of Y?" |

If the shortlist is empty after guards (all candidates excluded), skip to Unsure regardless of score.

### 5. Print the decision line

Before acting, print exactly one structured line:

```
[routing] → skill-name | tier: Sure | score: 0.91 | BM25-shortlist: 8 | guards-fired: 1
```

Fields required: `skill-name`, `tier`, `score`, `BM25-shortlist` count, `guards-fired` count. Never omit this line. It is the audit trail for every future debug session.

### 6. Act, ask, or escalate

- **Sure / Likely:** invoke the routed skill. Pass along the decision line as context if the skill uses it.
- **Unsure:** surface the top-2 candidates to the user with their scores. Ask which applies. Do not guess.
- **Empty shortlist:** tell the user no skill matched the request and ask them to rephrase or list available skills.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Silent top-N cap — BM25 stage quietly drops skills without logging | Print a drop-log line before the semantic pass: count forwarded, count dropped |
| skip-when guards evaluated as code instead of context | Evaluate guards as plain-English conditions against request context, not as executable predicates |
| Confidence thresholds hardcoded without documenting them | Record thresholds in skill config or a comment block; make them visible so tuning is explicit |
| Semantic-router invoked on the full skill registry when BM25 shortlist is empty | On empty shortlist, skip to Unsure immediately — do not fall back to full-registry embedding |
| Decision line omitted when tier is Sure | Always print the decision line regardless of tier; Sure decisions are the most useful audit points |
| BM25 scores compared across different tokenisation runs | Normalise scores within the same run only; never compare raw BM25 scores across separate batches |

## Verification / Proof

Hand off to `semantic-router` once routing fires, and record the full decision trail for review.

A valid `PROVEN BY:` block for this skill must contain:

- The BM25 drop-log line (skills scored, dropped, forwarded)
- The list of `skip-when` guards that fired (skill name + guard text), or "none" if none fired
- The printed decision line (skill-name, tier, score, shortlist count, guards-fired count)
- Confirmation that the routed skill was invoked or the user was asked (Unsure path)

```
PROVEN BY:
  BM25 prefilter: <total> skills scored, <dropped> dropped, <forwarded> forwarded
  Guards fired: <list or "none">
  Decision: [routing] → <skill-name> | tier: <tier> | score: <score> | BM25-shortlist: <n> | guards-fired: <n>
  Action taken: <invoked skill-name | asked user with candidates X, Y>
```

## Adapt from
- **`dorianbrown/rank_bm25`** or **`xhluca/bm25s`** (faster, numpy/numba) for the prefilter.
  <https://github.com/dorianbrown/rank_bm25> · <https://github.com/xhluca/bm25s>
