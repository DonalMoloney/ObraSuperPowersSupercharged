---
name: semantic-router
description: Use experimentally at the start of a non-trivial request that names no skill — embeds the task and does semantic nearest-neighbor search over a skill-description index (optionally reranked) to suggest which skills to invoke, as an overlay on v1 using-superpowers' keyword-trigger routing. Requires an embedding index that may not exist yet.
tier: v3
status: experimental
---

# semantic-router

v1 `using-superpowers` routes by keyword triggers: a request reaches a skill
only if its words happen to match that skill's trigger phrases. Requests phrased
in domain language ("the page jank gets worse after a deploy") slide past skills
whose triggers say "performance" or "regression." This skill proposes routing by
*meaning* instead.

**Mechanism (speculative):** at the start of a request, embed the task text into
a dense vector, then do k-nearest-neighbor search over an index of every skill's
`name + description + trigger phrases`, also embedded. The nearest skills by
cosine similarity are the candidates. Optionally rerank the top-k with a
cross-encoder, which reads request and candidate jointly and often corrects the
bi-encoder's surface-similarity mistakes.

**Confidence-gated, not blind:** never route silently on a weak match.

- top-1 below a similarity floor (~0.40) → "no skill applies," answer directly.
- top-1 clears the floor but top-1 and top-2 are within a small margin (~0.08) →
  surface a disambiguation question naming both candidates and their
  distinguishing triggers; wait for the user.
- top-1 clears the floor with a clear margin → suggest that skill, logging the
  name and score so the route is auditable.

**Boundary:** this is an *overlay* on v1 `using-superpowers`, not a replacement.
`using-superpowers` stays the source of truth for keyword routing and for the
explicit-skill-name fast path; semantic-router only adds a meaning-based second
opinion when keyword routing returns nothing or a low-confidence match. When the
user names a skill directly, skip the router entirely.

## Why this might be crazy enough to work

Keyword routing fails exactly where it matters most — when the user describes a
problem instead of naming a tool, which is the normal case. Embeddings collapse
the gap between "the request" and "the skill that solves it" into a distance you
can threshold on, and the disambiguation gate means the cost of a near-tie is a
clarifying question rather than a wrong skill. The whole thing is a retrieval
problem that the search literature already solves well; the bet is only that
skill descriptions are rich enough to embed usefully.

## Depends on infrastructure that may not exist yet

- **An embedding index of skill descriptions.** There is no such index in this
  repo today. It would need to be built and rebuilt whenever skills change, and
  the query-time embedding model must match the index-time model exactly or
  recall silently degrades. Until that index exists, this skill is a design, not
  a runnable router.
- **A reranker is optional.** The cross-encoder step improves precision but is
  not required for a first cut; bi-encoder kNN alone is a usable baseline.
- The original Forge version pinned this to a specific vector DB and reranker.
  This rewrite keeps the index/reranker generic on purpose — the concept does
  not depend on any one vendor.

## Known risks / open questions

- Thresholds (0.40 floor, 0.08 margin) are guesses; they need tuning against
  real routing logs and will drift as the skill set grows.
- Embedding round-trips cost latency and tokens on every request — a keyword
  fallback is probably safer when context is already exhausted.
- Open: does meaning-based routing actually beat keyword triggers often enough
  to justify the index maintenance, or only on rare oddly-phrased requests?

## Likely graduation criteria (v3 → v2)

- A real skill-description index exists and rebuilds automatically on skill
  changes, with the model pinned in index metadata.
- Measured against a corpus of real requests, semantic routing recovers correct
  skills that keyword routing missed, with an acceptably low false-route rate.
- Disambiguation prompts fire rarely enough not to annoy, and tuned thresholds
  hold steady across at least two skill-set revisions.
- Defined contract with v1 `using-superpowers` for when the overlay runs vs. when
  keyword routing alone decides.
