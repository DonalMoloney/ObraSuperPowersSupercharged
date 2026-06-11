# unattended-loop — v2 candidate spec

| Field | Value |
|---|---|
| Type | **skill** |
| Theme | Loops |
| Tier | v2 |
| Supports (v1) | executing-plans, verification-before-completion |
| Composes with (v2) | loop-until-green, session-handoff |
| Status | proposed |

## Problem

v2 `loop-until-green` governs fix→verify cycles *inside* one attended session.
Nothing governs the unattended case: "keep working through this plan overnight."
Unattended loops without discipline produce the known failure modes — infinite
thrash on a stuck task, silent drift off-spec, burned budget, and an
unreconstructable mess in the morning.

## What it does

Defines the contract for running work loops without a human watching: explicit
stop conditions, iteration budgets, per-iteration state checkpoints, and a
morning-readable log.

## Parts

### `SKILL.md`

**Frontmatter**
- `name: unattended-loop`
- `description`: "Use when work will continue across iterations without a human
  watching (overnight runs, scheduled loops, long autonomous plan execution) —
  sets stop conditions, budgets, and per-iteration checkpoints before the first
  unattended iteration."
- `tier: v2`, `supports: [executing-plans, verification-before-completion]`,
  `pairs-with: loop-until-green`.

**Section: Not this skill if**
- Human is present and responsive — v2 `loop-until-green` (attended) suffices.
- One-shot scheduled task, no iteration — plain scheduling, no loop contract.

**Section: The pre-flight contract (core content)**
No unattended iteration starts until ALL four are written down:
1. **Goal predicate** — a checkable condition for "done" (command + expected
   output), not a vibe.
2. **Stop conditions** — done; OR same task failed N times (default 3 — chains
   to v2 `architecture-stall-detector` reasoning); OR iteration budget hit
   (default 10); OR any action outside the declared scope is needed (new deps,
   schema changes, deletions → STOP, never improvise unattended).
3. **Scope fence** — directories/files the loop may touch; anything else is a
   stop condition, not a judgment call.
4. **Checkpoint cadence** — every iteration ends with a state block (see below)
   BEFORE the next begins.

**Section: Per-iteration checkpoint**
Reuses v2 `session-handoff`'s state-block format: iteration #, task attempted,
result + evidence, next intent, budget remaining. Appended to a single log file
so a crashed/interrupted loop is resumable from the last checkpoint and the
human can replay the night in one read.

**Section: Pacing mechanics**
- In-session loops: continue directly.
- Cross-session: scheduled wakeups/cron — pick intervals matched to what's
  being waited on; never wake just to poll something the harness reports anyway.

**Section: Morning report**
On any stop: summary block — stop reason, iterations used, goal predicate
status, checkpoint log location, and (if stopped on failure) what was tried,
mirroring `architecture-stall-detector`'s escalation questions.

## Workflow

write contract → iterate: work → verify → checkpoint → check stop conditions →
… → stop → morning report.

## Interfaces

- **v2 loop-until-green**: the inner cycle within one iteration; this skill is
  the outer governor.
- **v2 session-handoff**: checkpoint format reused verbatim — reference, don't
  duplicate.
- **v2 architecture-stall-detector**: the N-failures stop condition imports its
  verdict logic.

## Success criteria

- A deliberately impossible goal stops at the failure cap with a coherent
  morning report, instead of looping to budget exhaustion.
- A killed-mid-iteration loop resumes correctly from the last checkpoint.

## Risks / open questions

- Interaction with the existing ralph-loop plugin (user has it installed): is
  this skill the *discipline layer* that any loop runner (ralph, /loop, cron)
  should follow? Recommend yes — mechanics-agnostic contract, named runners as
  examples.
- Default budgets (10 iterations, 3 failures) are guesses; mark as tunable.
