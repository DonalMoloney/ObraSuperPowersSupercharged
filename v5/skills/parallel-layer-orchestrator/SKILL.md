---
name: parallel-layer-orchestrator
description: Use to run the full dev loop with parallelism — fans out each topological layer of non-conflicting tasks to the agent pool, joins at a barrier, verifies before advancing, with saga-style rollback on hard gate failure. The parallel upgrade to orchestrate-feature step 5.
author: Donal Moloney
track: A
type: orchestration
chains-to: task-dag-planner
---

## Not this skill if
- **Superseded by `wave-runner`.** `wave-runner` is the canonical, promoted fork/join wave executor for the parallel dev loop / `orchestrate-feature` step 5 — same fork-each-layer → barrier-join → verify-before-advance engine, plus the saga-style compensation rollback this draft pioneered (now folded into `wave-runner`). For any new work, use `wave-runner`. This file is kept only as the design note / adaptation source.
- The plan is a single serial chain — `execute-plan` is enough.
- `task-dag-planner` + `conflict-graph-scheduler` aren't available — build those first.
- You have fewer than two independent tasks in any layer — serial execution costs less than dispatch overhead.

# parallel-layer-orchestrator — fork/join DAG executor

> **Superseded-by:** `wave-runner`. Its unique saga-style rollback technique has been folded into `wave-runner` ("Saga-style rollback (compensation)" section). Do not start new work here.

## Purpose

Replace the serial chain inside `orchestrate-feature` with a wave executor: run everything that can run now, verify the wave, then advance — with clean rollback when a gate fails hard.

## Core rule

> **Rule:** Verify a wave (with `PROVEN BY:`) before advancing. A hard gate failure unwinds via the registered compensation — never loop a gate unboundedly.

## Triggers

**Use when:**
- Running `orchestrate-feature` with a plan that `task-dag-planner` has split into two or more independent layers.
- Asked to "run the whole feature autonomously" and the plan has no total ordering constraint.
- A prior serial run of `execute-plan` was slow and the task graph has parallelizable width.
- Recovering a failed wave where compensation is needed before retrying a layer.

**Don't use when:**
- The plan is a linear chain with every task depending on the previous — `execute-plan` is simpler and carries no dispatch overhead.
- `task-dag-planner` is not available or has not been run — you must have layer data before dispatching.
- The task set is exploratory or open-ended rather than a concrete implementation plan — use `see-big-picture` first to produce a scope, then come back.
- Any two tasks in the same layer write to the same file and `conflict-graph-scheduler` has not resolved that conflict — dispatching them in parallel causes a merge hazard.

## Algorithm

**Fork/join over topological layers** (from `task-dag-planner`) + **conflict-graph batching** (from `conflict-graph-scheduler`) within each layer + **saga compensation** for rollback + **circuit breaker** on the verify loop.

## Steps

### 1. Ingest the layer plan

Receive the ordered layer list from `task-dag-planner`. Each layer is a set of tasks with no dependency edges between them. Confirm the layer count and print a summary before dispatching anything:

```
Layer 0: [task-A, task-B, task-C]   (3 tasks, no deps between them)
Layer 1: [task-D]                   (depends on A, B, C)
Layer 2: [task-E, task-F]           (depends on D)
```

Register a compensation action for each task at this point. Do not start a task whose compensation is undefined — if rollback fires you need something to undo.

### 2. Split each layer by conflict graph

Pass the task set for the current layer through `conflict-graph-scheduler`. It returns one or more non-conflicting batches. Tasks that write to overlapping files end up in different batches within the same layer; dispatch batches sequentially within the layer, but dispatch all tasks in each batch in parallel.

If `conflict-graph-scheduler` is not available, fall back to single-file isolation per task by adding `isolation: 'worktree'` per item. This is slower but safe.

### 3. Dispatch the batch to the agent pool

Dispatch all tasks in the current batch to the agent pool simultaneously. Cap concurrent agent calls at 5–6 for raw parallel Agent calls; use the Workflow tool for higher concurrency with back-pressure (up to ~16). Do not hand-roll a dispatcher that ignores back-pressure — unbounded concurrent dispatch degrades throughput.

Attach a batch ID to every dispatched task so the barrier join can match responses to tasks unambiguously. Record start time.

### 4. Join at the barrier

Wait for all tasks in the batch to return before proceeding. Do not begin verification while any task in the batch is still running. If a task times out, mark it `status: timeout`, collect whatever partial output it produced, and include it in the verification payload anyway — the gate will catch incomplete results.

### 5. Verify the wave

Run the wave's combined diffs through `done-gate` and `blast-radius`. Produce a per-task result table:

```
task-A | pass  | <evidence line>
task-B | pass  | <evidence line>
task-C | fail  | <reason>
```

Attach a `PROVEN BY:` block to the wave result before deciding whether to advance. See the Proof section for what the block must contain.

### 6. Decide: advance or compensate

- **All tasks pass** — advance to the next layer. Reset the oscillation counter.
- **Soft failure** (one task fails, retryable) — re-dispatch only the failed task, increment the oscillation counter. If the counter reaches N (default 2), treat it as a hard failure.
- **Hard failure** — do not advance. Execute the registered compensation actions for every task in the current batch in reverse dispatch order. After compensation, trip the circuit breaker and halt. Surface the failure with the full wave log so a human can intervene.

Never silently swallow a gate failure and advance anyway. Never loop a compensation more than once per task — if the compensation itself fails, halt immediately.

### 7. Repeat for remaining layers

Once a layer passes verification, move to the next layer and return to step 2. After all layers pass, emit the full execution log (see Output).

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Dispatching tasks before compensation actions are registered | Register compensations in step 1 before any dispatch; if a compensation is undefined, do not start the task |
| Advancing to the next layer without a verified `PROVEN BY:` block | Gate advancement on the verify result; a missing proof block is treated the same as a gate failure |
| Looping a failing gate indefinitely hoping it self-heals | Increment the oscillation counter; trip the circuit breaker after N retries and surface the failure to a human |
| Dispatching tasks from different conflict batches in the same round | Split by `conflict-graph-scheduler` first; parallel dispatch only tasks within a single non-conflicting batch |
| Ignoring a timed-out task and proceeding | Include the timeout result in the verification payload; the gate catches it as an incomplete result |
| Running compensation in arbitrary order | Execute compensations in reverse dispatch order (last dispatched undone first) to respect any implicit ordering |

## Output

Emit a structured execution log at the end of all layers:

- Layer-by-layer summary: tasks dispatched, batch IDs, pass/fail per task.
- Per-wave barrier join results and verify outcome.
- Compensation/rollback record: which tasks were compensated, compensation result.
- Circuit-breaker state: tripped or clear, oscillation count.

## Proof

Hand off to `task-dag-planner` (via `chains-to`) for any plan re-structuring needed after a rollback. Hand off to `verify-before-done` after all layers pass for final end-to-end confirmation.

A valid `PROVEN BY:` block for a wave must contain:
- Batch ID and layer index for the wave being verified.
- Per-task status (pass / fail / timeout) with one evidence line per task.
- `done-gate` result (pass or hard-fail with reason).
- `blast-radius` result (scope confirmed or out-of-scope files listed).
- Oscillation counter value at time of verification.
- Disposition: advance / compensate / circuit-breaker-tripped.

**PROVEN BY: spec**
```
PROVEN BY:
  wave: layer=<N> batch=<batch-id>
  tasks: [<task-id> <pass|fail|timeout> — <evidence>]
  done-gate: <pass|fail — reason>
  blast-radius: <in-scope|out-of-scope files listed>
  oscillations: <count>
  disposition: <advance|compensate|circuit-breaker-tripped>
```

## Adapt from
- **`am-will/swarms`** (MIT) — dependency-ordered plan + parallel waves + verify-between-waves. Lift
  the `depends_on` plan schema and wave executor; add conflict-graph splitting + saga rollback.
  <https://github.com/am-will/swarms>
