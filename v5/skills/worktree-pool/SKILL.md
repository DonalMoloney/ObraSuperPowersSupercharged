---
name: worktree-pool
description: Use when N agents must write files in parallel on a shared branch and writes could collide. Triggered by parallel implementation waves, "try N approaches at once" tasks, or any agent fan-out where concurrent disk writes are expected. Not for read-only research fan-out or single-agent tasks.
author: Donal Moloney
track: A
type: implementation
chains-to: finish-branch
pairs-with: using-git-worktrees
---

## Not this skill if
- Read-only fan-out (research, search) — no write collisions, skip worktrees; use run-agents-in-parallel directly
- A single agent or a single task — there is nothing to pool
- You only need the merge-back / conflict-surfacing orchestration after isolated work returns (not the pool mechanics) — use `isolate-parallel-writes`

# Worktree Pool

## Purpose

Give each parallel writing agent its own git worktree so concurrent writes never collide. Merge clean results, discard the rest.

## Triggers

**Use when**
- Two or more agents write to overlapping paths simultaneously on one branch.
- Running "try N approaches at once" implementation spikes.
- A sub-agent wave is spawned and each may touch shared files.

**Don't use when**
- Fan-out is read-only (research, grep, analysis).
- Agents write to fully disjoint new files with no shared parents.
- Cost budget is tight and isolation risk is low.
- Single sequential task — one worktree is overhead.

## The pattern

### Native harness path (preferred)

Pass `isolation: 'worktree'` on every parallel `agent()` call. The harness provisions a fresh worktree per agent and auto-removes it when the diff is empty.

```js
const results = await Promise.all([
  agent("implement-approach-A", { isolation: "worktree" }),
  agent("implement-approach-B", { isolation: "worktree" }),
  agent("implement-approach-C", { isolation: "worktree" }),
]);
```

### Manual path (non-Workflow)

Use the built-in harness tools `EnterWorktree` / `ExitWorktree`, or git directly:

```bash
git worktree add ../wt-approach-a -b spike/approach-a
# agent writes here
git worktree remove ../wt-approach-a --force   # discard
```

### Post-agent integration

1. Collect per-worktree diffs (`git diff main...HEAD`).
2. Check cross-worktree conflicts — any file touched by more than one worktree is a candidate.
3. Merge clean worktrees; open a PR per surviving approach or squash into one. For disciplined reconciliation of overlapping changes, hand off to `isolate-parallel-writes` — surface every overlap side-by-side and resolve each by an explicit recorded decision before applying. This skill owns the *pool* (provisioning, leasing, capping, reclaiming); `isolate-parallel-writes` owns *how results merge back*.
4. Remove discarded worktrees (`git worktree prune`).

## Cheat sheet

| Step | Command / call |
|------|---------------|
| Provision | `agent(..., { isolation: "worktree" })` or `git worktree add` |
| Inspect diff | `git diff main...HEAD` (inside each worktree) |
| Detect conflicts | compare changed-file lists across all worktrees |
| Merge winner | `git merge` or open PR via `finish-branch` |
| Discard loser | `git worktree remove --force` then `git worktree prune` |

## Pitfalls

| ❌ Mistake | ✅ Fix |
|-----------|--------|
| Using worktrees for read-only fan-out | Skip isolation; plain parallel agents are cheaper |
| Merging without checking cross-worktree conflicts | Always diff changed-file lists before merging any worktree |
| Leaving stale worktrees after the task | Run `git worktree prune` as the final step; confirm with `git worktree list` |
| Provisioning a worktree per micro-task | Pool is for parallel writes; batch small tasks into one agent instead |

## After

Hand each surviving branch to `finish-branch` for merge or PR. Run `verify-before-done` on the merged result before closing the pool.

```
PROVEN BY: git worktree list shows no stale entries; cross-worktree conflict check returned zero overlapping paths; merged branch passes CI.
```
