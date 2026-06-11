---
name: task-dag-planner
description: Use after a plan exists — converts the task list into a dependency DAG, validates ordering, and surfaces the critical path so the orchestrator knows the minimum completion time and what to parallelize.
author: Donal Moloney
track: A
type: process
chains-to: conflict-graph-scheduler
---

## Not this skill if
- Fewer than ~5 tasks with no dependencies — a flat list is fine
- No plan yet — run `outline-plan` first
- The deciding factor is file collisions, not ordering — tasks have no prerequisites but may touch the same files → use `conflict-graph-scheduler` for a provable non-colliding batch
- You have one large task to decompose, not a list yet → use `split-task-for-parallel` first; this skill assumes the list already exists and orders it by dependency
- You just need a quick parallel-vs-sequence call → use `parallel-or-sequential` (three questions); come here when ordering and critical path actually matter

# task-dag-planner — schedule, not just a checklist

## Purpose

Give `outline-plan` output real structure: a dependency DAG with a validated order, computed
parallel layers, and the critical path (the longest chain that bounds completion time).

## Core rule

> **Rule:** Tasks declare explicit dependencies; waves are *computed* from the graph, never declared
> by hand. A cycle is a planning error — surface it, don't run.

## Triggers

**Use when:**
- A plan with more than five tasks exists and you need to know the minimum time to completion
- Someone asks "what's the fastest this can finish?" or "what can run in parallel?"
- `outline-plan` has produced a task list and the next step is scheduling, not just ordering
- Any multi-phase feature build where some tasks are blocked on others and wasted sequential waits are costly
- Post-`split-task-for-parallel` — the subtasks now need a verified execution order before dispatch

**Don't use when:**
- The list has no inter-task dependencies — every task is independent → dispatch directly via `run-agents-in-parallel`
- You already have a validated DAG from a previous run and only need to re-batch writes → go straight to `conflict-graph-scheduler`
- The task list is still being defined — settle scope with `scope-feature` or `challenge-spec` first

## Algorithm

**Topological sort** validates order and detects cycles; **Critical Path Method** (longest weighted
path) finds the bounding chain; off-path tasks are slack to parallelize. (Uses `graph-algorithms`.)

## Steps

### 1. Parse the task list

Read the `outline-plan` output or the caller-provided task list. For each task extract:
- A stable identifier (number, slug, or short name)
- An estimated duration (in abstract units — story points, minutes, or relative weight; use 1 if unknown)
- A `depends_on` list — the identifiers of tasks that must finish before this one starts

If `depends_on` is missing for any task, treat it as having no prerequisites. Do not invent dependencies. If a task's dependencies reference an identifier that does not exist in the list, surface that as a broken reference error before continuing.

### 2. Build the DAG and validate it

Construct a directed graph: each task is a node; each dependency edge points from the prerequisite to the dependent. Then run a topological sort.

- If the sort succeeds, the graph is a valid DAG. Record the topological order as the strict execution sequence of last resort (used only when wave scheduling is impossible).
- If the sort fails — a cycle is present — stop. Print the cycle path (`A → B → C → A`) and the names of the tasks involved. Do not proceed to scheduling. Ask the caller to break the cycle by removing or reversing one dependency.

### 3. Compute parallel layers (waves)

Walk the topological order and assign each task to the earliest wave in which all of its prerequisites are in an earlier wave.

- Wave 0: all tasks with no prerequisites.
- Wave k: all tasks whose every prerequisite is in waves 0 through k-1.

Print the wave assignment as a table:

```
Wave 0 (parallel): task-A, task-B, task-C
Wave 1 (parallel): task-D, task-E
Wave 2 (sequential): task-F
```

Label each wave as `parallel` if it contains more than one task, `sequential` if it contains exactly one.

### 4. Compute the critical path

For each node compute two values: earliest start (ES) and earliest finish (EF = ES + duration). Walk forward through the topological order:
- A task's ES is the maximum EF of all its predecessors (0 if it has none).
- The project's minimum completion time is the maximum EF across all terminal tasks.

Walk backward to compute latest start (LS) and latest finish (LF). Total float for each task = LS - ES. Tasks with zero float are on the critical path.

Mark critical-path tasks clearly in the output. State the minimum completion time explicitly.

### 5. Identify slack tasks

List all tasks with positive float as "parallelizable slack." These are candidates for background dispatch — they do not block completion as long as they finish before their latest finish time.

Order the slack list by float descending so the orchestrator knows which tasks have the most scheduling freedom.

### 6. Emit the output and hand off

Produce three artifacts:
1. A Mermaid `graph TD` DAG with critical-path edges highlighted (`:::crit` class or bold annotation).
2. The wave table from step 3.
3. A critical-path summary: task names in order, total minimum duration, and slack task list.

Then hand the wave table to `conflict-graph-scheduler` to check each wave for file-write collisions before dispatch. Do not dispatch any wave until `conflict-graph-scheduler` signs off on it.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Declaring waves by hand instead of computing them from the graph | Always derive waves from topological sort; hand-declared waves silently skip dependency validation |
| Running when a cycle is detected instead of stopping | Surface the full cycle path and halt; a cycle means the plan has a logical error that must be resolved before any execution |
| Treating missing `depends_on` as an error | Default to no prerequisites; only flag broken references (a named dependency that doesn't exist in the list) |
| Skipping `conflict-graph-scheduler` after building the DAG | Wave membership controls *ordering*; file-collision safety within a wave requires a separate graph pass |
| Using abstract wave order as wall-clock time | Critical path duration is only meaningful in the same units the caller used for task estimates; label units explicitly |
| Assigning duration = 0 to unknown tasks silently | Use duration = 1 as the default; log which tasks were defaulted so the caller can supply real estimates later |

## Verification / Proof

After producing the DAG and wave table, run `verify-before-done` before handing control to `conflict-graph-scheduler`.

The `PROVEN BY:` block must contain:
- Confirmation that topological sort completed without a cycle (or the cycle was surfaced and halted)
- Total task count, wave count, and layer membership list
- Named critical-path tasks in order with total minimum-duration value
- Slack task list with float values
- Confirmation that `conflict-graph-scheduler` handoff packet (wave table) was produced

```
PROVEN BY:
- Topological sort: success, no cycle detected
- Tasks: <N> parsed, <W> waves computed
- Critical path: <task-A> → <task-C> → <task-F>, minimum duration: <X> units
- Slack tasks: <task-B> (float: 2), <task-D> (float: 1)
- Handoff: wave table emitted to conflict-graph-scheduler
```

## Adapt from
- **`networkx`** (`topological_sort`, `dag_longest_path`) · **`Wlodarski/cpm.py`** (CPM via topo sort)
  · **`sounakmondal/ProjectScheduler`** (CPM in Python). <https://github.com/Wlodarski/cpm.py>
