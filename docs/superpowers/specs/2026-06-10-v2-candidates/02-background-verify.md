# background-verify — v2 candidate spec

| Field | Value |
|---|---|
| Type | **skill** |
| Theme | Harness |
| Tier | v2 |
| Supports (v1) | executing-plans, verification-before-completion |
| Composes with (v2) | loop-until-green, session-handoff |
| Status | proposed |

## Problem

Long verification (full test suites, builds, integration runs) creates a bad
choice during plan execution: sit idle for 10 minutes, or skip ahead without
evidence. Claude Code supports background Bash tasks and monitoring, but v1
`executing-plans` and `verification-before-completion` are written as if all
verification is synchronous.

## What it does

Teaches when and how to run verification in the background while continuing
plan work, and — critically — the rule for which results MUST block progress vs.
which may trail behind.

## Parts

### `SKILL.md`

**Frontmatter**
- `name: background-verify`
- `description`: "Use when a verification step takes longer than ~2 minutes and
  there is independent plan work that could proceed meanwhile…"
- `tier: v2`, `supports: [executing-plans, verification-before-completion]`

**Section: Not this skill if**
- Verification is fast (< ~2 min) — just run it inline.
- The next task depends on the verified code — blocking is correct; waiting is
  the work.

**Section: The blocking rule (core content)**
A decision table:
| Next task touches… | Verification may run in background? |
|---|---|
| Same files/module as the change being verified | NO — block |
| Independent plan task, no shared files | YES |
| A "done" claim or commit | NEVER — all background results must be in first |

**Section: Mechanics**
- Launch: `run_in_background` Bash with a named description.
- Track: check task output when the harness notifies; never busy-poll.
- The "fan-in before done" invariant: before any completion claim or commit,
  every outstanding background verification must be collected and green.

**Section: Failure handling**
- Background failure arrives mid-task: finish the current atomic edit, then
  switch to the failure (it invalidates work in flight). Chain to v1
  `systematic-debugging`.

**Section: Supercharged-by relationship**
References v1 verification-before-completion for *what counts* as verification;
this skill only changes *when it runs*.

## Workflow

1. Plan task N done → start suite in background → begin task N+1 (only if
   independent per the blocking rule).
2. Harness notifies on completion → triage result immediately.
3. Before claiming the plan (or any task whose deps were backgrounded) complete:
   collect all results; any red → stop and debug.

## Interfaces

- **v1 executing-plans**: slots into the per-task verify step.
- **v2 loop-until-green**: a red background result enters the loop.
- **v2 session-handoff**: handoff block must list outstanding background tasks.

## Success criteria

- Total plan wall-clock time drops on plans with ≥2 independent tasks and slow
  suites, with zero "claimed done while a background task was still running"
  incidents.

## Risks / open questions

- Models tend to forget outstanding background work; should the fan-in invariant
  also be enforced by the `verification-gate` plugin (#1)? Likely yes — note the
  pairing in both specs.
- Resource contention: two suites writing to the same test DB. Needs a "shared
  mutable resources" caveat in the blocking rule.
