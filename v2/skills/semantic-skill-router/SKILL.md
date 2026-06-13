---
name: semantic-skill-router
description: Use at the start of a request when the right workflow is not obvious and keyword matching against the routing table would be fragile — embeds the task and does kNN-plus-rerank over the skill catalog to pick the best-fitting skill, emits an honest "no skill applies" when nothing clears threshold, and asks the human instead of guessing when the top two candidates are within margin. The explicit, uncertainty-aware dispatcher behind the v1 routing table.
author: Donal Moloney
tier: v2
supports: [using-superpowers, dispatching-parallel-agents]
type: entry
pairs-with: skill-graph
---

## Not this skill if

- **The v1 routing table already gives an unambiguous match** — v1 **using-superpowers** has an
  explicit trigger → skill table; if one row clearly fits, route there directly. This skill earns its
  keep only when several skills compete or no keyword fires.
- **The user named the skill explicitly** — invoke it; do not re-route.
- **It is a greeting or a one-word ack** — skip routing entirely.
- **The skill index has not been built** — run the v5 `index-skills` companion first, or fall back to
  v1 **using-superpowers** keyword routing.
- **You want to dispatch 2+ tasks at once** — route each task here individually, then hand the chosen
  skills to v1 **dispatching-parallel-agents**; this router picks *one* skill per task.

# semantic-skill-router — "which workflow fits this task?"

## Purpose

v1 **using-superpowers** routes by an explicit keyword trigger table. That table is fast and right when
a trigger phrase matches — but it is fragile at the edges: many skills compete on overlapping keywords,
near-misses get silently skipped, and there is no principled "nothing applies" signal. This skill makes
the routing decision in embedding space and is honest about its own uncertainty.

It implements **CHAINING-OPTIONS.md option D — routing entry skill**: a first-class, testable
dispatcher promoted out of v5 prose into v2.

It supports two v1 skills:

- v1 **using-superpowers** — this is the semantic backstop to that skill's keyword table. The skill
  priority and announce convention there still govern (process skills before implementation skills;
  announce "Using [skill] to [purpose]"). This router only changes *how the match is found* when the
  table is ambiguous — it does not override v1's instruction-priority rules.
- v1 **dispatching-parallel-agents** — when a batch of independent tasks needs the right skill each,
  this router classifies them one at a time, producing the per-task skill assignment that
  dispatching-parallel-agents then fans out.

**Core rule:** Never guess on a near-tie. A confident wrong route is worse than a question. If the top
two candidates are within margin ε, surface both and ask — do not pick one silently.

## How it consumes the v5 companions

This skill owns the *decision logic*; the *index* is the v5 `index-skills` companion. It does not
re-build or re-embed the catalog:

| Concern | v5 companion this skill drives | What this skill adds |
|---|---|---|
| Embed `name + description + trigger phrases` for every skill, upsert to the vector index | `index-skills` | Nothing — it queries the index `index-skills` maintains |
| Confirm the relation graph behind the routing target is intact (no orphan / dangling chain) | v2 `skill-graph` | Pairs with it: route to a skill, then trust its outbound chain is unbroken |

If the index is empty or unavailable, **STOP** and run `index-skills`, or fall back to the v1
**using-superpowers** keyword table for this turn.

## Algorithm

1. **Index** — each skill is stored as an embedding of `name + description + trigger phrases`, built and
   kept current by the v5 `index-skills` companion. This skill does not own the index.
2. **Embed the task** — on a routing request, embed the user's task text.
3. **kNN retrieve** — cosine-similarity search over the index → top-k candidate skills.
4. **Cross-encoder rerank** — rerank the top-k for the precision the bi-encoder kNN misses; the
   reranked order is the decision input.
5. **Threshold + margin check** — the decision logic this skill owns:
   - If `score(top-1) < threshold` → emit **"no skill applies"**. This is a real signal, not a silent
     wrong pick — fall through to default behavior or ask the user what they want.
   - If `score(top-1) − score(top-2) < ε` → **near-tie**: surface both candidates with their scores and
     **ask the human** which fits. Do not pick.
   - Otherwise → route to top-1. Announce it in v1 **using-superpowers** form: "Using [skill] to
     [purpose]", then follow that skill exactly.

The `threshold` and `ε` margin live here in the router. The embeddings live in the index.

## Steps

1. Confirm the index is populated (the v5 `index-skills` companion has run since the last skill change).
   If not, stop and run it, or fall back to the v1 keyword table.
2. Embed the task; retrieve top-k by cosine similarity; rerank with the cross-encoder.
3. Apply the threshold + margin check above to the reranked list.
4. **Output one of three outcomes, explicitly:**
   - **Route** — name the skill, its score, and the announce string.
   - **No skill applies** — say so, with the top-1 score that fell below threshold.
   - **Ask** — present top-1 and top-2 with scores and the margin, and ask the human to choose.
5. For a multi-task batch, repeat 2–4 per task, then hand the per-task assignments to v1
   **dispatching-parallel-agents**.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Picking top-1 on a near-tie | If `top-1 − top-2 < ε`, ask the human; a confident wrong route costs more than a question |
| Treating a low top-1 score as "route anyway" | Below threshold means **no skill applies** — say so; do not force a match |
| Re-embedding the catalog inside this skill | The index is owned by `index-skills`; this skill only queries it |
| Routing where the v1 keyword table already matches cleanly | Use v1 **using-superpowers** directly; reserve the router for ambiguous or keyword-cold tasks |
| Overriding v1 skill-priority rules | This skill changes only *how the match is found*; process-before-implementation and the announce convention still come from v1 |
| Routing to a skill with a broken outbound chain | Pair with v2 **skill-graph** so the chosen skill's `chains-to` edges are known intact |

## Verification

The router's decision is testable: for a labeled set of task → expected-skill pairs, confirm the chosen
outcome matches, and confirm that deliberately ambiguous tasks produce an **ask**, not a silent pick,
and that off-catalog tasks produce **no skill applies**.

PROVEN BY: a terminal block of the form

```
PROVEN BY:
- index queried: <N records> in <index-name>
- task embedded, top-k retrieved: <k>, reranked
- decision: route <skill> (score <s>, margin <m>) | no-skill-applies (top-1 <s> < threshold) | ask (top-1 <s>, top-2 <s>, margin <m> < ε)
- announce string emitted (if routed): "Using <skill> to <purpose>"
```
