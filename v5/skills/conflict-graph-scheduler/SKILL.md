---
name: conflict-graph-scheduler
description: Use when dispatching 2+ parallel tasks and file-scope overlap is unclear. Triggers on "run these in parallel", "are these tasks independent?", or before any multi-agent dispatch where concurrent file writes may collide.
author: Donal Moloney
track: A
type: implementation
chains-to: spawn-subagent
pairs-with: run-agents-in-parallel
---

## Not this skill if
- Only one task — there is nothing to schedule
- Tasks have a sequential dependency — use execute-plan to serialize, or wave-runner for waves
- You need execution *ordering* / critical path, not file-collision safety — use `task-dag-planner` (this skill only proves what can run together, never in what order)
- You just want a quick parallel-vs-sequence call — use `parallel-or-sequential` as the cheap front end; come here for a provable file-scope schedule

# Conflict-Graph Scheduler

## Purpose

Build an undirected conflict graph from each task's declared file scope, then compute provably non-overlapping parallel batches via greedy graph coloring. Replaces the manual "do these scopes overlap?" eyeball check.

## Triggers

**Use when**
- 2+ tasks are ready for parallel dispatch.
- Tasks declare file scopes (required by **run-agents-in-parallel**).
- You need a guarantee — not a guess — that no two concurrent agents touch the same file.

**Don't use when**
- Only one task — dispatch directly.
- Tasks are already known to be file-disjoint — batch freely without the graph.
- Fixed sequential dependency exists — use **execute-plan** to serialize instead.

## Pattern

**Steps**

1. **Collect scopes.** List every file each task may read or write. Unknown scope → treat as full-repo (edge to every node).
2. **Build the graph.** Nodes = tasks. Edge between any two tasks whose file sets intersect.
3. **Color the graph.** Greedy coloring: tasks sharing an edge get different colors. Each color class = one safe parallel batch.
4. **Cap batches.** Split any color class exceeding 5–6 agents into sequential sub-batches.
5. **Emit schedule.** List batches and which pairs share which files.

**Pseudocode**

```python
G = nx.Graph()
G.add_nodes_from(tasks)
for a, b in combinations(tasks, 2):
    if task_scopes[a] & task_scopes[b]:
        G.add_edge(a, b)
color_map = nx.coloring.greedy_color(G, strategy="largest_first")
batches = defaultdict(list)
for task, color in color_map.items():
    batches[color].append(task)
```

Why it earns its keep: a manual eyeball check passes T1={`auth/login.py`} and T3={`api/routes.py`} as "independent" — but if both import `util/helpers.py` and that shared scope is declared, the graph catches the edge the eyeball misses.

**Worked example**

| Task | Files |
|------|-------|
| T1 | `auth/login.py`, `auth/models.py` |
| T2 | `auth/models.py`, `db/schema.sql` |
| T3 | `api/routes.py` |
| T4 | `db/schema.sql` |

Edges: T1–T2, T2–T4. T3 isolated. → **Batch 1:** T1, T3, T4 · **Batch 2:** T2

## Pitfalls

| ❌ Mistake | ✅ Fix |
|-----------|--------|
| Trusting undeclared scopes | Require explicit scope; treat unknown as full-repo |
| Missing transitive overlap via shared helpers | Include all transitively imported files in scope |
| Batch exceeds 5–6 agents | Split oversized color class into sequential sub-batches |
| No post-partition re-check | Assert no same-batch pair shares a file before dispatch |

## Conflict types beyond direct file overlap

Two tasks can collide even when their declared write paths differ. Add edges for these too:

- **Transitive conflict:** task A imports or depends on a file that task B edits — A's behavior shifts under it even though A never writes that file.
- **Semantic conflict:** two tasks change the same behavior from opposite ends (one edits the caller, one the callee) — both pass in isolation, break together.
- **Build-artifact conflict:** two tasks regenerate the same lockfile, snapshot, or generated output — no shared *source* file, but they race on the produced artifact.

## After

Hand computed batches to **spawn-subagent** or **run-agents-in-parallel** for dispatch. If overlap slips through at merge time, a three-way merge MCP handles the residual case.

```
PROVEN BY: partition verified — no two tasks in the same batch share a declared file.
```
