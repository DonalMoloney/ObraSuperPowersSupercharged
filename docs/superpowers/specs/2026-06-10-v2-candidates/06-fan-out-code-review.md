# fan-out-code-review — v2 candidate spec

| Field | Value |
|---|---|
| Type | **skill** |
| Theme | Parallelization |
| Tier | v2 |
| Supports (v1) | requesting-code-review, receiving-code-review, dispatching-parallel-agents |
| Composes with (v2) | merge-parallel-results, red-team-spec (sibling pattern), review-clarification-gate |
| Status | proposed |

## Problem

v1 `requesting-code-review` gets one generalist review. A single reviewer pass
blends concerns and dilutes depth — security issues hide behind style nits. The
existing v2 `red-team-spec` proved the pattern of parallel adversarial lenses,
but only for *specs*. There is no code-diff counterpart.

## What it does

Runs N specialist review agents concurrently on one diff — each with a single
lens — then merges findings with provenance and severity into one review
artifact.

## Parts

### `SKILL.md`

**Frontmatter**
- `name: fan-out-code-review`
- `description`: "Use when a diff is ready for review and warrants more than a
  single generalist pass (security-sensitive, large, or pre-merge) — runs
  parallel single-lens review agents and merges findings…"
- `tier: v2`, `supports:` as above, `pairs-with: red-team-spec`.

**Section: Not this skill if**
- Small/low-risk diff — one v1 `requesting-code-review` pass is proportionate.
- Reviewing a spec, not code — v2 `red-team-spec`.

**Section: The lens roster (core content)**
Default four lenses, each a one-shot subagent with ONLY its lens:
1. **Correctness & logic** — bugs, edge cases, off-by-ones.
2. **Silent failures** — swallowed errors, bad fallbacks, empty catches.
3. **Test adequacy** — does coverage actually pin the new behavior?
4. **Simplification** — unnecessary complexity, duplication, dead code.
Optional lenses by diff profile: security (auth/input/crypto touched),
performance (hot paths), API design (public surface changed).
Rule: 3–5 lenses; beyond 5, merge cost exceeds marginal findings.

**Section: Dispatch protocol**
- All lenses dispatched in ONE message (concurrent), same diff + same context
  block, differing only in lens instruction.
- Each returns findings in a fixed shape: `file:line`, severity
  (blocker/should/nit), claim, evidence.
- Read-only agents — reviewers never edit.

**Section: Merge**
- Via v2 `merge-parallel-results`: dedupe cross-lens duplicates (same file:line,
  same claim), keep highest severity; contradictions (one lens says extract, the
  other says inline) surfaced explicitly, not silently resolved.
- Output: single review doc ordered blockers → should → nits, each finding
  tagged with its lens (provenance).

**Section: Acting on it**
Hand the merged artifact to v1 `receiving-code-review` (with v2
`review-clarification-gate` for ambiguous items). Findings are claims to verify,
not orders.

## Workflow

diff ready → lens selection by profile → concurrent dispatch → merge with
provenance → v1 receiving-code-review.

## Interfaces

- **v1 requesting-code-review**: this is its heavyweight mode; the v1 skill
  remains the default path.
- **v2 red-team-spec**: same architecture, different artifact — keep section
  structures parallel so users transfer intuition.

## Success criteria

- On a seeded diff with 3 planted bugs of different kinds, the matching lenses
  find their planted bug and the merge contains no duplicate findings.
- Merged output is actionable without reading any individual agent transcript.

## Risks / open questions

- Token cost: 4–5 agents × full diff. Needs a stated size threshold (e.g.,
  diff > ~150 lines or risk-sensitive paths) before the fan-out is justified.
- Overlap with installed pr-review-toolkit agents — this skill should define
  lens *content* generically rather than depend on any specific plugin's agents.
