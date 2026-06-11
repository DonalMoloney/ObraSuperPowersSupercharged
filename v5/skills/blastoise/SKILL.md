---
name: blastoise
description: Use before review or merge — for a diff, trace every caller, dependent, and test that could break, then emit a blast radius score and risk level (LOW/MED/HIGH/CRITICAL) so review depth and reviewer choice scale with actual impact. Named after Blastoise (the Pokémon) — a blast-radius skill with serious defensive power.
author: Donal Moloney
track: A
type: support
chains-to: request-review
---

## Not this skill if
- No diff yet — there's nothing to score
- Single isolated file with no dependents and full coverage — risk is trivially LOW

# blastoise — measured change risk (blast radius)

## Purpose

Replace "this feels low-risk" with a measured number: how far a change's effects reach, used to route
review effort appropriately. Gut feel produces inconsistent review depth; this skill produces a
repeatable, traceable score that determines reviewer count, review mode, and whether to invoke
`devils-advocate` before merging.

## Core rule

> **Rule:** The risk level must come from the dependency trace, not intuition. Attach the trace as
> `PROVEN BY:`.

## Triggers

**Use when:**
- "How risky is this change?" — before any review or merge decision
- Preparing to invoke `request-review` — run this first to calibrate review depth
- Before `finish-branch` — verify the blast radius has not grown since the last trace
- Per wave in `parallel-layer-orchestrator` — each wave's output should carry a blast-radius score before the next wave starts
- The diff touches a shared utility, base class, public API, or configuration entry point — any symbol many callers import
- The diff changes behavior for callers that cannot self-report breakage (e.g., dynamic dispatch, interface implementations)

**Don't use when:**
- No committed or staged diff exists — there is no graph input
- The change is documentation-only with zero symbol exports touched
- A trivially isolated new file has zero inbound edges and its own dedicated test file — skip scoring and proceed directly to `request-review`

## Algorithm

Build a symbol/import dependency graph (via `graph-algorithms`). **Reverse reachability** from changed
symbols = direct + transitive dependents. Score from `(dependents × fan-in) ÷ diff-test-coverage` →
LOW/MED/HIGH/CRITICAL. High → deeper review + more `devils-advocate` reviewers; low → fast-path.

### Risk level thresholds

| Level | Criterion |
|---|---|
| LOW | ≤ 5 direct dependents, ≥ 80 % diff-line coverage |
| MED | 6–20 direct dependents, or 50–79 % coverage |
| HIGH | 21–50 direct dependents, or < 50 % coverage |
| CRITICAL | > 50 direct dependents, or a public interface/config entry changed with any coverage gap |

These are defaults; adjust thresholds in the graph-algorithms config when the codebase has established norms.

## Steps

### Step 1 — Parse the diff and identify changed symbols

Extract the diff from `git diff HEAD` (or the staged diff via `git diff --cached`). For each changed
hunk, identify the exported or callable symbols: function names, class names, method signatures,
re-exported identifiers, and configuration keys. Group them by file. Discard changed lines that are
purely comments, blank lines, or internal private helpers with no inbound edges — these cannot
propagate breakage. Record the total changed-symbol list before proceeding; this list is the graph
seed.

### Step 2 — Build or load the dependency graph and compute reverse reachability

Load the dependency graph via `graph-algorithms`. If a cached graph is available and the repo has not
changed since it was built, reuse it; building from scratch on large monorepos is expensive. From the
graph, run a reverse-reachability walk starting at each changed symbol:

- **Direct dependents** — nodes with a direct import or call edge to any changed symbol.
- **Transitive dependents** — all nodes reachable by following edges backward from the direct set.
  Cap the transitive walk at depth 5 to avoid unbounded traversal in deeply coupled codebases; note
  the cap explicitly in the output if it fires.

Produce three counts: `direct_count`, `transitive_count`, and `fan_in` (the maximum inbound-edge count
across all changed symbols — a proxy for interface centrality). If `graph-algorithms` is unavailable,
fall back to a grep-based callers search (`git grep -rn <symbol>`) and note the fallback in the trace.

### Step 3 — Pull diff test coverage

Run the coverage tool for the repo (e.g., `diff_cover`, `coverage.py --diff`, or the CI coverage
artifact) against the diff to get the percentage of changed lines covered by an existing test. If no
coverage data exists, treat coverage as 0 % and escalate the risk level one tier. Record
`covered_lines`, `total_diff_lines`, and `coverage_pct`.

### Step 4 — Compute the score and risk level

Apply the formula:

```
raw_score = (direct_count + transitive_count) × fan_in / max(coverage_pct, 1)
```

Map `raw_score` to LOW/MED/HIGH/CRITICAL using the threshold table above. If any changed symbol is a
public interface, config entry point, or exported default, apply a minimum of MED regardless of the
numeric score.

### Step 5 — Recommend review depth and reviewer

Translate the risk level to a concrete review routing decision:

- **LOW** — single reviewer, async review, no `devils-advocate` required.
- **MED** — single reviewer, synchronous review, flag the highest-fan-in symbol for focus.
- **HIGH** — two reviewers, one of whom should be the owner of the most-impacted module; invoke
  `devils-advocate` on the core logic change before requesting review.
- **CRITICAL** — full team review, block merge until coverage gap is closed or an explicit
  risk-acceptance comment is recorded; `devils-advocate` required.

Emit the recommendation as a structured block alongside the risk level.

### Step 6 — Emit output and attach proof

Produce the complete output block (see Output section) and attach the dependency trace as the
`PROVEN BY:` block. Hand off to `request-review` with the risk level and reviewer recommendation
pre-populated.

## Output

```
blastoise: <risk level>
changed symbols: <N>
direct dependents: <N>
transitive dependents: <N> (depth cap: <N or "none">)
max fan-in: <N>
diff coverage: <N>%
uncovered diff lines: <N>
reviewer recommendation: <routing decision>
PROVEN BY: <dependency trace — tool output, graph node list, or grep results>
```

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Risk level set by intuition without running the trace | Always compute from the dependency graph; attach the trace or the score is invalid |
| Treating 0 % coverage as "unknown" and skipping the escalation | Treat missing coverage data as 0 % and escalate risk one tier; note the absence explicitly |
| Stopping the walk at direct dependents only | Include transitive dependents; a broken helper can cascade through layers that never directly import the changed symbol |
| Ignoring interface or config changes because they look "small" | Any public interface or config entry point carries a minimum risk of MED regardless of numeric score |
| Reusing a stale dependency graph after unrelated merges | Check the graph build timestamp against the last commit on the target branch; rebuild if stale |
| Emitting a risk level without a `PROVEN BY:` block | The Core rule requires the trace; a bare label with no evidence is not a valid output |

## Proof

Hand off to `request-review` once the score and recommendation are produced.

The `PROVEN BY:` block must contain:
- The tool or method used to build the dependency graph (e.g., `graph-algorithms`, `git grep` fallback, `codeindex` CLI)
- The full list of changed symbols used as the graph seed
- Direct dependent count and transitive dependent count (with depth-cap note if applicable)
- Coverage tool and `coverage_pct` value (or explicit "no coverage data — treated as 0 %")
- The computed `raw_score` and the threshold mapping that produced the risk level
- Reviewer routing recommendation derived from the level

Example spec (not an actual evidence block — replace with real run output):

```
PROVEN BY:
  graph tool: graph-algorithms v0.4.1 (reverse-reachability walk)
  seed symbols: [parseConfig, loadSchema] (2 symbols, src/config.ts)
  direct dependents: 14
  transitive dependents: 38 (depth cap: none)
  max fan-in: 9 (parseConfig)
  coverage tool: diff_cover 8.0.2
  coverage_pct: 43 %
  uncovered diff lines: 12 of 21
  raw_score: (14 + 38) × 9 / 43 = 10.9 → HIGH
  reviewer recommendation: two reviewers, invoke devils-advocate before request-review
```

## Adapt from
- **`scheidydude/codeindex`** (blast-radius scoring + riskiest-files CLI) · **`tirth8205/code-review-graph`**
  (callers/dependents/tests, 30+ langs) · **`alperhankendi/Ctxo`** (`get_blast_radius` MCP) ·
  **`SallahBoussettah/vibe-diff`** (risk level, zero-LLM) · **`Bachmann1234/diff_cover`** (uncovered diff lines).
  <https://github.com/scheidydude/codeindex>
