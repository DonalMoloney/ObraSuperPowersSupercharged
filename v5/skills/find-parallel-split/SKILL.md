---
name: find-parallel-split
description: Use when preparing to dispatch 4 or more tasks in parallel — applies min-cut reasoning to a dependency DAG to find the partition with maximum independent streams before run-agents-in-parallel fires.
author: Donal Moloney
track: A
type: process
chains-to: run-agents-in-parallel
---

## Not this skill if
- Fewer than 4 tasks — direct dispatch via `run-agents-in-parallel` is sufficient
- No dependency information exists — run `task-dag-planner` first to build the DAG
- You need an execution ordering, not a parallel grouping — use `task-dag-planner` (critical path, not partition)
- All tasks are already known to be fully independent — skip directly to `run-agents-in-parallel`

# find-parallel-split — optimal parallel partition via min-cut

## Purpose

Given a task dependency DAG (from `task-dag-planner`), find the partition into the maximum number
of independent parallel streams by identifying which dependency edges, when respected, naturally
divide the task set into groups with no cross-group dependencies.

**Core rule:** A stream is only valid if every task within it has all its prerequisites either
inside the same stream (and ordered correctly) or already completed in a prior wave. No task may
depend on a task in a different, concurrently running stream.

## When to use

- Any call to `run-agents-in-parallel` with 4+ tasks — run this first
- After `task-dag-planner` produces a wave table and you want the optimal agent assignment
- When the wave table shows multiple tasks per wave and you need to decide which tasks go to which agents

## Algorithm — min-cut reasoning

The dependency graph is a DAG. An independent parallel stream is a set of nodes with no directed
edges crossing between sets (once each set's internal ordering is respected).

The algorithm proceeds as follows:

1. Start from the wave table produced by `task-dag-planner` (or recompute from the DAG if not available).
2. Within each wave, identify connected components — clusters of tasks that share a common prerequisite within the wave or produce a common output consumed later.
3. Tasks in different connected components within the same wave are candidates for different parallel streams.
4. Merge streams across waves when a wave-k task feeds only wave-k+1 tasks in one connected component — these tasks belong in the same stream.
5. The optimal partition maximises the number of streams while keeping each stream internally ordered and externally independent.

**Key constraint:** Honour all dependency edges from the DAG. Do not remove or reorder them to create more parallelism. Only partition along edges that already have no cross-group dependency.

## Steps

### 1. Receive the DAG

Accept the output of `task-dag-planner`: the directed graph (nodes = tasks, edges = dependencies) and
the wave table. If only a flat task list is available, stop and invoke `task-dag-planner` first.

Confirm: cycle-free (topological sort succeeded), each task has an identifier and a `depends_on` list.

### 2. Identify cross-wave dependency clusters

For each pair of tasks in the same wave, check whether they share a common predecessor or a common
successor. Tasks that share either are in the same cluster; tasks that share neither are in different
clusters and are candidates for different parallel streams.

Build the cluster membership table:

```
Wave 0: [task-A, task-B] → cluster 0-α (no shared predecessor/successor)
         [task-C]         → cluster 0-β
Wave 1: [task-D, task-E] → cluster 1-α (task-D depends on task-A; task-E depends on task-B)
         [task-F]         → cluster 1-β (depends on task-C)
```

### 3. Merge clusters into streams

A stream is a chain of clusters across waves that are connected by dependency edges. Merge:
- Cluster 0-α → Cluster 1-α → … → Stream 1
- Cluster 0-β → Cluster 1-β → … → Stream 2

Streams that never interact are confirmed independent.

### 4. Check independence

For every pair of streams (Stream i, Stream j), verify there are no dependency edges from any task
in Stream i to any task in Stream j, or vice versa, that would require them to synchronise mid-run.

If a cross-stream edge is found: merge the two streams into one. A merged stream reduces parallelism
but preserves correctness. Prefer correctness.

### 5. Emit the partition

Output the numbered stream list:

```
## Parallel streams — <feature> — <YYYY-MM-DD>

Stream 1 (tasks: N):
  1. task-A  (wave 0, no prerequisites)
  2. task-D  (wave 1, depends on task-A ✓ internal)

Stream 2 (tasks: M):
  1. task-C  (wave 0, no prerequisites)
  2. task-F  (wave 1, depends on task-C ✓ internal)

Stream 3 (tasks: K):
  1. task-B  (wave 0, no prerequisites)
  2. task-E  (wave 1, depends on task-B ✓ internal)

Dependency edges honoured: task-A→task-D, task-C→task-F, task-B→task-E
Cross-stream dependencies: none

Partition: 3 independent parallel streams, 0 cross-stream edges.
```

### 6. Flag under-parallelism

If the result is a single stream (all tasks are mutually dependent), report:

```
WARNING: No valid parallel split found. All tasks form one dependency chain.
Action: Dispatch sequentially via execute-plan or spawn-subagent; do not use run-agents-in-parallel.
```

If the number of streams equals the number of tasks (fully independent), report:

```
NOTE: All tasks are fully independent — no DAG analysis needed.
Action: Dispatch directly via run-agents-in-parallel without this step next time.
```

### 7. Hand off to run-agents-in-parallel

For each stream, produce a brief agent task brief:
- Stream N: tasks [list], ordered as [sequence], may not touch files owned by other streams.

Pass the full partition to `run-agents-in-parallel` as the dispatch plan.

PROVEN BY: partition is validated by re-checking every dependency edge in the emitted streams; any cross-stream edge would appear in the "cross-stream dependencies" line above, making violations self-evident.

## Output format (summary)

```
Streams:          <N>
Tasks per stream: <min>–<max>
Cross-stream edges: 0
Edges honoured:   <E>
```

## Pitfalls

| Mistake | Fix |
|---|---|
| Running without a DAG | `task-dag-planner` first — this skill partitions an existing graph, it does not build one |
| Confusing this skill with `task-dag-planner` | `task-dag-planner` finds ordering and critical path; this skill finds the parallel partition |
| Merging streams to reduce agent count | Keep streams independent even if it means more agents — correctness first, then bound by the `run-agents-in-parallel` max of 5–6 |
| Ignoring the under-parallelism flag | A single-stream result means sequential execution is correct; dispatching in parallel would violate dependencies |
| Splitting more than 5–6 streams | `run-agents-in-parallel` caps at 5–6 concurrent agents. If the partition yields more, batch the streams into waves of ≤6. |

## Pairs with

- `task-dag-planner` — prerequisite; produces the DAG this skill partitions
- `run-agents-in-parallel` — consumer; this skill's output is the dispatch plan
- `conflict-graph-scheduler` — complementary; checks file-ownership conflicts within a stream after partition
- `wave-runner` — alternative orchestration if streams have internal ordering requirements
