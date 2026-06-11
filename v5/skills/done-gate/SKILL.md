---
name: done-gate
description: Use before any "done" claim — one gate that runs the whole battery (tests, lint, proof-gate, expired-assumption check) and risk-scores the change to route it to the right reviewer agent. Replaces remembering five separate checks.
author: Donal Moloney
track: proof
type: decision
chains-to: request-review
---

## Not this skill if
- Mid-task, not claiming completion — gates fire at the "done" boundary only
- You are running a partial check on one subsystem only — run that subsystem's own checks directly
- You have already run done-gate and are re-verifying after a trivial one-line typo fix — re-run only the failing check, not the full battery

# done-gate — one "are we done?" gate

## Purpose

Bundle the completion checks into a single gate and use a risk score to scale review depth and pick
the right specialist reviewer automatically. One call replaces remembering to run tests, lint,
`proof-gate`, and `expiring-assumptions` separately, and ensures the routing decision is always
data-driven rather than a guess.

## Core rule

> **Rule:** No "done" without a green battery and an attached `PROVEN BY:`. High-risk changes get
> mandatory deeper review; low-risk changes fast-path.

## Triggers

**Use when:**
- About to say "done", "this is ready", or "complete" on any task
- Before invoking `request-review` or `finish-branch`
- Before opening a PR or marking a ticket resolved
- Any time the question "is this actually done?" arises

**Don't use when:**
- You are mid-task and checking intermediate progress — gates are boundary events, not progress checks
- The change is a documentation-only edit with zero code delta — skip the full battery; a lint + proof check is sufficient
- You are inside a subagent spawned by a parent that will run done-gate itself — defer to the parent gate

## Algorithm

Run tests + lint + `proof-gate` + `expiring-assumptions` check. Get the **risk score** from
`blast-radius`. Route: high → `code-reviewer` + extra `devils-advocate` reviewers; type-heavy →
`type-design-analyzer`; error-handling → `silent-failure-hunter`.

## Steps

### 1. Run the full battery

Execute all four checks in order. Collect a pass/fail result for each. Do not short-circuit on the first failure — run every check so the full picture is visible in the gate result.

- **Tests** — run the project's test suite. Record total count, pass count, fail count, and any skipped tests. A skipped test is not a pass; flag it explicitly.
- **Lint** — run the configured linter. Zero warnings allowed unless the project's baseline explicitly suppresses a category. New suppressions introduced by this change are a flag, not a pass.
- **`proof-gate`** — invoke the `proof-gate` skill. Confirm the current task has a `PROVEN BY:` block attached and that the evidence cited is real and traceable. An empty or placeholder `PROVEN BY:` is a hard fail.
- **`expiring-assumptions`** — check the active assumption log for entries whose expiry date has passed or whose test condition is now falsifiable. Stale assumptions attached to this change are a fail; stale assumptions in unrelated files are a warning, not a blocker.

If any check fails, stop and report the specific failures before proceeding to step 2. Do not produce a risk score or reviewer recommendation for a failed battery — the gate result is already FAIL.

### 2. Score blast-radius

Call `blast-radius` on the diff to get a numeric risk score. The score reflects how many callers, dependents, and shared-state paths the change touches.

Interpret the score as follows:

- **Low (0–2):** Isolated change; affects only the immediate file or module with no shared-state spillover.
- **Medium (3–5):** Cross-module change; affects a defined interface or shared utility touched by multiple callers.
- **High (6+):** Cross-cutting change; touches a public API, shared data schema, global config, or critical path.

If `blast-radius` is unavailable, estimate manually: count the number of distinct modules importing or calling the changed symbol. Use that count as a proxy score.

### 3. Choose reviewer(s) by change shape and risk score

Apply the routing table below. A change may match more than one shape; assign all matching reviewers.

| Risk / Change shape | Assigned reviewer(s) |
|---|---|
| Low — any shape | Fast-path: `request-review` with standard reviewer |
| Medium — any shape | `code-reviewer` |
| High — any shape | `code-reviewer` + `devils-advocate` |
| Any — type-heavy (new interfaces, renamed types, generic changes) | Add `type-design-analyzer` |
| Any — error-handling (new error paths, silent returns, swallowed exceptions) | Add `silent-failure-hunter` |
| Any — security-adjacent (auth, permissions, data access) | Add security reviewer explicitly noted in the gate result |

When risk is High and the change is also type-heavy, assign all three: `code-reviewer`, `devils-advocate`, and `type-design-analyzer`. Do not collapse the list — each reviewer has a distinct scope.

### 4. Emit the gate result

Produce a single structured output block containing:

- **Battery result:** PASS or FAIL with per-check breakdown
- **Risk score:** numeric value + Low/Medium/High label + one-line rationale
- **Reviewer recommendation:** named reviewer(s) from the routing table, one per line
- **PROVEN BY:** block (see Proof section below)

If the battery is FAIL, the gate result is FAIL regardless of risk score. Emit the full output block so the caller can see which checks failed and why.

If the battery is PASS, hand off to `request-review` with the gate result attached.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Short-circuiting the battery on the first failure | Run all four checks regardless; the full picture matters for the gate result |
| Treating a skipped test as a pass | Flag all skipped tests explicitly; skipped is not green |
| Accepting a placeholder `PROVEN BY:` as valid | Require real, traceable evidence; an empty or template block is a hard fail |
| Producing a reviewer recommendation before the battery is green | Battery must be PASS before routing logic runs |
| Assigning only one reviewer when multiple shapes match | Apply all rows from the routing table that match the change shape |
| Using done-gate as a mid-task progress check | Gates fire at the "done" boundary only; use per-subsystem checks for intermediate validation |
| Letting an expired assumption pass silently | Flag stale assumptions attached to this change as a battery fail, not a warning |

## Proof

Hand off to `request-review` once the gate result is PASS and the routing recommendation is attached.

The output block must contain:

- Battery result: PASS with explicit per-check line (tests: N/N passed, lint: clean, proof-gate: PASS, expiring-assumptions: none stale)
- Risk score: numeric value, Low/Medium/High label, one-sentence rationale citing the blast-radius output or manual proxy count
- Reviewer list: named reviewer(s) matched from the routing table
- `PROVEN BY:` — test run output reference or CI run ID; lint output reference; proof-gate confirmation line with task name; assumption log scan result with date

A gate result that omits any of the four battery lines, the risk score rationale, or the reviewer list is incomplete and must be regenerated before handing off to `request-review`.

## Adapt from
- **`moonrunnerkc/swarm-orchestrator`** — gates merges on automated quality checks.
  <https://github.com/moonrunnerkc/swarm-orchestrator>
