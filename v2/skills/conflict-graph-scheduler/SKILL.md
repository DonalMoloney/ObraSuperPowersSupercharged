---
name: conflict-graph-scheduler
description: Use before dispatching 2+ candidate parallel tasks when file-scope overlap is unclear and you need to prove which can run concurrently — builds a conflict graph from each task's declared file scope (plus transitive, semantic, and build-artifact collisions) and partitions tasks into safe concurrent batches, flagging any that must be serialized or merged first.
author: Donal Moloney
tier: v2
supports: [dispatching-parallel-agents, subagent-driven-development]
type: process
pairs-with: parallel-plan-executor
---

## Not this skill if

- **You already have batches and want to run them** — that is v2 **parallel-plan-executor**: it dispatches each wave into isolated worktrees and merges between waves. This skill is the pre-dispatch analyzer that *produces* the partition `parallel-plan-executor` consumes. Run this first, hand it the batches, stop.
- **Only one candidate task** — there is nothing to schedule; dispatch directly.
- **Tasks form a strict chain (one consumes another's output)** — there is no parallelism to find; sequence with v1 **executing-plans**.
- **Scopes are already known disjoint** — batch freely; the graph buys nothing.

# Conflict-Graph Scheduler

## Purpose

v1 **dispatching-parallel-agents** assumes you have *already* judged tasks independent; v2 **parallel-plan-executor** runs the partition you *already* built. Nothing decides — provably — which tasks may share a batch. The default is an eyeball "do these overlap?" check, and its failure mode is two concurrent agents writing the same file, caught only at merge.

This skill replaces the eyeball check with a conflict graph: model task independence as graph coloring, where each color class is a batch in which no two tasks can collide. It is the independence test of v2 **parallel-plan-executor** made explicit and graph-shaped, run as a standalone analysis before any dispatch.

**Core principle:** A pair runs in the same batch only when *no* collision edge connects them. Any uncertain edge is drawn — sequence on doubt, never parallelize on hope.

## Inputs

- 2+ candidate tasks, each with a **declared file scope** (every file it may read or write). Scope discipline is the load-bearing input.
- Undeclared scope → treat that task as touching the whole repo (it gets an edge to every other task, so it lands alone). Never guess a narrower scope; guessing is how collisions happen.

If candidate tasks have no file scopes, **STOP** — derive them (from the plan via v1 **writing-plans**, or from the task definitions) before scheduling.

## Building the conflict graph

Nodes are tasks. Draw an edge between two tasks when *any* of these collision types holds:

1. **Direct file overlap** — their declared file sets intersect.
2. **Transitive conflict** — task A imports or depends on a file task B edits; A's behavior shifts under it even though A never writes that file. Include transitively imported/depended-on files in each scope.
3. **Semantic conflict** — both change the same behavior from opposite ends (one edits the caller, one the callee). Each passes in isolation; together they break.
4. **Build-artifact conflict** — both regenerate the same lockfile, snapshot, migration, or generated output. No shared *source* file, but they race on the produced artifact.

Two tasks with disjoint source files can still earn edges 2–4 — those are exactly the collisions the eyeball check misses.

## Partitioning into batches

Partition the graph by greedy coloring: assign each task the lowest color not used by any neighbor, so no edge connects two same-color tasks. Each color class is one safe concurrent batch.

In prose, the procedure is:

1. Order tasks by descending degree (most-conflicting first).
2. Walk the list; give each task the first batch whose members it shares no edge with, else open a new batch.
3. **Cap batch width** at 3 (matching v2 **parallel-plan-executor**'s default) — merge cost grows with width faster than the time saved. Split an over-wide color class into sequential sub-batches.
4. Tasks at full-repo scope, or in their own singleton color, run alone between batches.

A runnable graph-coloring helper (e.g. a small NetworkX `greedy_color` script) is an optional future addition; the analysis is doable by hand for the small task counts this skill targets.

## Worked example

| Task | Declared scope |
|------|----------------|
| T1 | `auth/login.py`, `auth/models.py` |
| T2 | `auth/models.py`, `db/schema.sql` |
| T3 | `api/routes.py` |
| T4 | `db/schema.sql` |

Edges: T1–T2 (share `auth/models.py`), T2–T4 (share `db/schema.sql`). T3 is isolated.
Partition → **Batch 1:** T1, T3, T4 · **Batch 2:** T2.

## Output and handoff

Emit the schedule: the batches, plus for every drawn edge *which collision type* forced it. Then:

- Hand the batches to v2 **parallel-plan-executor** as its proven wave partition, or dispatch a single batch directly with v1 **dispatching-parallel-agents** / **subagent-driven-development**.
- Flag any task that landed in a singleton because of an edge as "**serialize or merge first**" — that is a decision for the human or for v1 **writing-plans**, not for blind dispatch.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Trusting an undeclared or guessed scope | Require explicit scope; treat unknown as full-repo (lands alone) |
| Counting only direct file overlap | Also draw transitive, semantic, and build-artifact edges |
| Widening a batch to "go faster" | Cap at 3; merge cost outruns the speedup |
| Skipping the post-partition check | Before handoff, assert no same-batch pair shares an edge |
| Treating the output as an execution order | This proves what runs *together*, not in what *order* — ordering belongs to the plan / v2 **parallel-plan-executor** |

## Verification

Re-walk the partition: for every batch, confirm no two members are connected by any edge (direct, transitive, semantic, or build-artifact). The schedule is invalid until that holds.

PROVEN BY: the emitted batches plus the edge list (each edge tagged with its collision type), and an explicit "no same-batch pair shares an edge" assertion before the partition is handed to v2 parallel-plan-executor or v1 dispatching-parallel-agents.
