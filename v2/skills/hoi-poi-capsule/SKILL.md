---
name: hoi-poi-capsule
description: Use when more than one workspace, worktree, or development branch exists at once, or when returning to a machine with old ones — inventories every capsule, classifies it (active, finished, stale, unknown), and routes each to the finishing flow or an explicit discard so no work rots in a forgotten capsule.
author: Donal Moloney
tier: v2
supports: [using-git-worktrees, finishing-a-development-branch]
type: process
chains-to: finishing-a-development-branch
pairs-with: spike-in-worktree
---

## Not this skill if

- There's a single workspace and nothing parallel — nothing to inventory.
- You're about to CREATE an isolated workspace — that's v1 **using-git-worktrees** (or v2 **spike-in-worktree** for throwaway experiments).

# Hoi-Poi Capsule

## Purpose

Capsule Corp's rule: every capsule has an owner and a label, and you always know what's deployed. Parallel development breaks the other way — worktrees and branches accumulate, each holding work someone meant to come back to, until nobody remembers what's in them and finished work quietly rots unmerged. This skill manages the *fleet*: what capsules exist, what's in each, and what happens to it.

Supports v1 **using-git-worktrees** (the inventory is the other half of creation) and v1 **finishing-a-development-branch** (finished capsules route into its merge/PR/discard decision).

## Triggers

**Use when:**
- More than one worktree or feature branch exists right now
- Returning to a repo or machine after time away — what did past-you leave deployed?
- Before creating yet another workspace — check the fleet first
- Disk, confusion, or "which branch had that fix?" moments

**Don't use when:**
- Single workspace, no parallel work
- Creating a new workspace (that's v1 **using-git-worktrees**)

## The fleet check

### 1. Inventory

List every capsule with its vitals:

```
git worktree list
git branch -vv --sort=-committerdate
```

Every row gets an entry: location, branch, last commit date, ahead/behind its base.

### 2. Classify

| Class | Signal | 
|---|---|
| **Active** | You can say what task it serves today |
| **Finished** | Work complete, not yet merged/PR'd |
| **Stale** | No commits in a long time, purpose foggy |
| **Unknown** | Can't say what it is without looking |

"Unknown" is a temporary class — inspect (`git log`, `git diff <base>...`) until it becomes one of the other three.

### 3. Route

- **Active** → leave it; note its task in one line.
- **Finished** → v1 **finishing-a-development-branch** — merge, PR, or discard via its structured options.
- **Stale** → check for unique work (`git log <base>..<branch>`). Unique commits: recover (rebase, cherry-pick, or finish) or discard with a written one-line reason. No unique work: remove.
- **Unknown** → never delete while unknown; inspect first.

### 4. The repack rule

A capsule is closed only two ways: through the v1 finishing flow, or by an explicit discard with a recorded reason. Silent deletion is how work disappears.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Creating workspace #5 without checking the fleet | Inventory before every new capsule |
| Deleting a stale worktree to "clean up" | Check for unique commits first; discard is a decision, not housekeeping |
| Finished branch parked "until later" | Finished routes to v1 **finishing-a-development-branch** now — parked is how it rots |
| Inventory done, classifications kept in your head | Write the ledger down; the next fleet check starts from it |

## After

Route every **Finished** capsule through v1 **finishing-a-development-branch**. If the fleet check found work worth isolating going forward, create new capsules via v1 **using-git-worktrees** — labeled, with an owner and a task.
