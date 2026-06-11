# watch-and-resume — v2 candidate spec

| Field | Value |
|---|---|
| Type | **skill** |
| Theme | Loops |
| Tier | v2 |
| Supports (v1) | executing-plans, systematic-debugging |
| Composes with (v2) | unattended-loop (#7), background-verify (#2) |
| Status | proposed |

## Problem

Some waits are on *external* state the harness cannot notify about: a CI
pipeline, a deploy, a remote job queue, a rate-limit window. The model's default
behaviors are both wrong — busy-poll every 30 seconds (waste) or fire-and-forget
(never comes back). Local background tasks are covered by `background-verify`
(#2); the external case has different mechanics and no skill.

## What it does

Defines the watch loop for external state: what to check, how often, what to do
between checks, and when to declare the wait failed and escalate.

## Parts

### `SKILL.md`

**Frontmatter**
- `name: watch-and-resume`
- `description`: "Use when blocked on external state the harness cannot track —
  CI runs, deploys, remote queues — sets check cadence, between-check behavior,
  and a give-up condition before the first poll."
- `tier: v2`, `supports: [executing-plans, systematic-debugging]`.

**Section: Not this skill if**
- Waiting on a local background command — v2 `background-verify` (#2); the
  harness notifies you, polling is waste.
- The external system has a webhook/notification path — set that up instead of
  polling.

**Section: The watch contract (core content)**
Before the first poll, write down:
1. **The probe** — exact command (e.g., `gh run view <id> --json status`) and
   the terminal states it can return.
2. **Cadence rule** — interval ≈ expected-duration / 4, floor 60s. An ~8-minute
   CI run gets ~2-minute checks, not 30-second ones. Long waits: do useful
   independent work between checks rather than idling (cadence table included).
3. **Give-up condition** — max wait = 2× expected duration; on breach, stop
   watching and report "stuck, here's the probe output" rather than waiting
   forever.

**Section: Between checks**
Priority order: (1) independent plan tasks that don't depend on the awaited
result — the #4 independence test decides what qualifies; (2) review/cleanup of
completed work; (3) genuinely idle → schedule the next check and end turn; never
spin.

**Section: On resolution**
- Success → resume the dependent task, citing the probe evidence.
- Failure → this is a bug report from the external system: enter v1
  `systematic-debugging` with the probe output as the first evidence, don't
  blind-retry the pipeline.

**Section: Repeated watch (loop case)**
Watching recurrently (e.g., every push) → that's a standing loop: apply the #7
`unattended-loop` contract on top; this skill defines only a single wait.

## Workflow

blocked on external state → write watch contract → poll at cadence, useful work
between → resolved: resume with evidence / breached: escalate with probe output.

## Interfaces

- **#2 background-verify**: strict complement — local/notified vs.
  external/polled. Each skill's "Not this skill if" points at the other.
- **#7 unattended-loop**: governs the recurring case.
- **v1 systematic-debugging**: the mandatory path on external failure.

## Success criteria

- Given "wait for this CI run", the session shows ≤ expected/4 cadence polling,
  productive work between checks, and a clean resume or escalation — no
  30-second poll spam, no abandoned waits.

## Risks / open questions

- Cadence heuristic (÷4, floor 60s) is opinionated — good default, mark
  tunable.
- Should the probe + give-up state be written into the `session-handoff` block
  if context runs out mid-wait? Yes — add one line referencing it.
