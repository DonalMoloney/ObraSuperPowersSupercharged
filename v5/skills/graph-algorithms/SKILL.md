---
name: graph-algorithms
description: Use for graph problems — shortest paths, flows, orderings, connected components, centrality. Also the shared engine that conflict-graph-scheduler, task-dag-planner, skill-dependency-graph, and blast-radius call internally.
author: Donal Moloney
track: D
type: support
chains-to: proof-gate
---

## Not this skill if
- The graph is trivial (<5 nodes) — reason about it directly
- You need a routing decision, not a graph computation — use `skill-router`

# graph-algorithms — build-once graph engine

## Purpose

A single, reusable graph engine. User-facing for quantitative tasks (shortest path, max-flow,
topological order, components, PageRank) and the internal dependency of every graph-based skill in
this set, so the math is implemented and tested once.

## Core rule

> **Rule:** Every answer carries its own check — re-verify the result (path validity, ordering
> legality, component membership) and attach `PROVEN BY:` before claiming it.

## Triggers

**Use when:**
- The question contains "shortest path", "longest path", "critical path", or "minimum spanning tree"
- You need a topological ordering of tasks, dependencies, or modules with known precedence edges
- You are asked which node is "most central", "most connected", or "highest influence" (PageRank / degree centrality)
- You need to know whether a cycle exists — and where it is
- You are computing max-flow or min-cut on a capacity graph
- `conflict-graph-scheduler`, `task-dag-planner`, `skill-dependency-graph`, or `blast-radius` delegates a computation to this skill
- The task involves partitioning a graph into connected or strongly-connected components

**Don't use when:**
- The graph has fewer than 5 nodes — enumerate or reason about it inline
- The question is a routing or skill-selection decision, not a graph computation — use `skill-router`
- You only need a single yes/no reachability answer on a tiny adjacency matrix — check it by inspection

## Algorithm

Wrap `networkx`. Map each problem class to its canonical function:

| Problem class | `networkx` call |
|---|---|
| Topological order (DAG) | `topological_sort` |
| Critical / longest path | `dag_longest_path` |
| Shortest path (unweighted) | `shortest_path` |
| Shortest path (weighted) | `shortest_path` with `weight=` |
| Connected components (undirected) | `connected_components` |
| Strongly connected components (directed) | `strongly_connected_components` |
| Cycle detection | `simple_cycles` |
| Centrality / influence ranking | `pagerank` |
| Graph coloring (conflict partition) | `greedy_color` |
| Max-flow / min-cut | `maximum_flow` |

Select exactly one function per sub-question. If a caller needs multiple computations in one pass,
run them sequentially on the same graph object rather than rebuilding the graph for each.

## Steps

### 1. Parse and build the graph

Identify whether the input is directed or undirected and whether edges carry weights or capacities.
Construct the appropriate `networkx` object: `DiGraph` for directed, `Graph` for undirected,
`MultiDiGraph` only when parallel edges are required.

Add every node explicitly before adding edges — do not rely on implicit node creation when the input
may include isolated nodes that carry no edges. Record the node count and edge count as part of the
build log so the verification step can confirm completeness.

If the input arrives as a schema (task list, dependency map, skill call-graph), normalise it to
`(source, target, optional_weight)` triples before loading.

### 2. Select the algorithm

Match the question to one entry in the algorithm table above. If the question is ambiguous — for
example, "how related are these two nodes?" — resolve it to a concrete computation (shortest-path
distance, common-neighbour count, Jaccard coefficient) before proceeding. Do not run multiple
algorithms speculatively; pick one, run it, then decide whether a second pass is needed.

For DAG-only algorithms (`topological_sort`, `dag_longest_path`), assert the graph is acyclic first
with `is_directed_acyclic_graph`. If cycles exist, surface them via `simple_cycles` and stop — a
topological sort on a cyclic graph is undefined.

### 3. Run the computation

Call the selected function. Capture the full result object, not just the scalar summary. For example,
store both the path list and its total weight, not just the weight. This detail is required for the
verification step.

If the call raises an exception (disconnected graph, negative weight cycle, capacity violation),
catch it, report the error class and affected nodes, and halt — do not return a partial result as
though it were complete.

### 4. Verify the result

Re-check the result against the raw graph before returning it. The specific check depends on the
algorithm used:

- **Topological order** — iterate every edge `(u, v)` in the graph and confirm `index(u) < index(v)` in the returned order. Any violation is a bug in the input or the call.
- **Shortest / longest path** — walk the returned node sequence and confirm each consecutive pair `(u, v)` is a real edge in the graph with the recorded weight.
- **Components** — confirm every node appears in exactly one component; confirm no edge crosses two distinct components (for connected components) or one non-trivially-SCC group (for SCCs).
- **PageRank** — confirm the scores sum to 1.0 within floating-point tolerance; confirm the highest-ranked node has a higher in-degree than any node ranked below it (sanity check, not proof).
- **Max-flow** — confirm flow conservation at every internal node (inflow = outflow); confirm no edge exceeds its stated capacity.
- **Cycle detection** — walk each returned cycle and confirm every consecutive edge exists and the last node re-enters the first.

Record the verification result (pass / fail + detail) as a separate artefact alongside the computation result.

### 5. Return result, verification, and PROVEN BY

Package three items: the computation result (full, not summarised), the verification record from step 4, and the `PROVEN BY:` block. Hand off to `proof-gate` for final attestation before the result leaves this skill.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Running `topological_sort` on a graph that contains a cycle | Assert `is_directed_acyclic_graph` first; if false, run `simple_cycles` and surface the offending cycle before stopping |
| Returning only the scalar result (e.g. path length) without the supporting structure (the path itself) | Capture the full result object; the verification step requires the path list, not just its weight |
| Building the graph with implicit node creation, silently dropping isolated nodes | Add all nodes explicitly before adding edges; confirm node count matches input before proceeding |
| Treating a disconnected graph as though it were fully connected | Check `is_connected` / `is_weakly_connected` before algorithms that assume connectivity; report disconnection explicitly |
| Mixing directed and undirected graph types when the caller delegates from another skill | Read the caller's edge schema; choose `DiGraph` vs `Graph` from the schema, not from a default |
| Reporting the result without a verification record | Always attach a per-algorithm correctness check; a bare answer with no check does not satisfy the Core rule |

## Proof

Hand off to `proof-gate` once the verification step in step 4 passes.

The `PROVEN BY:` block must contain:
- The algorithm selected and the `networkx` function called
- Node count and edge count of the graph as built
- The full result (not a summary) — path list, ordered sequence, component sets, or score table
- The verification method used (e.g. "walked all edges in returned path; all present and weights match")
- Verification outcome: pass or fail with detail
- If any nodes or edges were dropped or coerced during build, a count and reason

## Adapt from
- **`networkx`** — the engine for all of the above. <https://networkx.org>
