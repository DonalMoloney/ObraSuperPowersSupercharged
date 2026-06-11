---
name: map-reduce-sweep
description: Use when asked to migrate all X, audit every skill, annotate every file, or run any large mechanical sweep across N files in isolation then combine the results into one report.
author: Donal Moloney
track: A
type: implementation
chains-to: verify-before-done
pairs-with: run-agents-in-parallel
---

## Not this skill if
- You only need to touch 1–3 files — do it inline; overhead not worth it.
- The task is exploratory/open-ended rather than a mechanical per-file operation — use `see-big-picture` instead.
- The units are heterogeneous subtasks, not a uniform per-file operation — use `fan-out-fan-in`.
- You only need the consolidation step for results that already returned — use `merge-parallel-results`.

# Map-Reduce Sweep

## Purpose

Apply one well-defined transform or audit to every file independently (map), then merge all per-file results into a single report (reduce). Items run in parallel; no file waits on another.

## Triggers

**Use when:**
- "Migrate all X to Y"
- "Audit every skill / every file"
- "Annotate every Y with Z"
- Any sweep where the same operation repeats N times with independent inputs

**Don't use when:**
- Files share mutable state and ordering matters — sequence the writes instead
- N < 4; run them sequentially

## The pattern

```js
pipeline(
  files,                            // array of file paths
  async (file) => transform(file),  // map — parallel, isolated
  async (results) => reduce(results) // reduce — single pass after all maps
);
```

1. **Collect** — enumerate all target files; record total count before filtering.
2. **Cap transparently** — if limiting to top-N, log dropped files and reason before the pipeline starts. **No silent caps.**
3. **Map** — pass the array to `pipeline(files, transformStage, verifyStage)`. Each file streams independently.
   - Add `isolation: 'worktree'` per item **only** if items write to shared files. Read-only sweeps skip it — worktrees cost ~200–500 ms per item.
   - Concurrency cap: **~16** via the `Workflow` tool; **5–6** for raw parallel Agent calls via `run-agents-in-parallel`.
4. **Reduce** — collect per-file results; produce a summary table. For non-trivial consolidation — deduping overlapping findings, detecting contradictions between agents, flagging file collisions, attaching provenance — use `merge-parallel-results` as the dedicated reduce step.
5. **Proof** — run `verify-before-done` on the reduced output before closing.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Silent top-N cap — sweep quietly skips files | Log dropped items with count and reason before pipeline starts |

> Example cap-log: `Dropped 21 of 37 files — only top-16 processed (concurrency cap); rerun to cover the rest.`
| Worktree per item on a read-only audit | Skip `isolation: 'worktree'`; plain parallel map saves 200–500 ms per file |
| Reduce starts before all map stages finish | `pipeline()` enforces this; do not hand-roll a reduce that reads partial results |
| One failure aborts the whole report | Catch per-item errors; include `status: error` row so reduce still runs |
| Unbounded concurrency with raw Agent dispatch | Cap at 5–6 agents; use `Workflow` tool for higher concurrency with back-pressure |

## Proof

Hand off to `verify-before-done` once the reduce stage completes.

The output must contain:
- Per-file result table (file path | status | finding)
- Combined reduced summary
- Count of items processed vs. items dropped
- `PROVEN BY:` the per-file evidence log (pipeline run IDs or explicit per-file confirm lines)
