---
name: spike-in-worktree
description: Use when spiking a risky change, throwaway prototype, or library evaluation and the experiment must not contaminate the current branch
author: Donal Moloney
tier: v2
supports: [using-git-worktrees, finishing-a-development-branch]
type: technique
chains-to: finishing-a-development-branch
---

## Not this skill if
- The change is meant to ship — work on a normal branch via v1 **using-git-worktrees** instead
- You need parallel write isolation across many agents — use v5 `worktree-pool`

# Spike in Worktree

## Purpose

Run a throwaway experiment in an isolated git worktree so a failed spike leaves the main workspace pristine. Every spike ends with an explicit keep/discard decision and a verified clean main tree.

Supports v1 **using-git-worktrees** (adds the throwaway-experiment shape that skill doesn't cover) and v1 **finishing-a-development-branch** (the graduation path when a spike is kept).

## Triggers

**Use when:**
- "spike this", "throwaway prototype", "try something risky"
- Evaluating a new library, approach, or architecture before committing to it
- Any experiment you might want to simply delete

**Don't use when:**
- The prototype is already planned to ship — use v1 **using-git-worktrees** + a real branch
- You're already inside a linked worktree from a prior skill invocation

## The Pattern

### Steps

1. **Create the spike worktree**
2. **Run the experiment** — code freely; treat the worktree as disposable
3. **Decide: keep or discard**
4. **Confirm the main tree is clean**

### Cheat sheet

```bash
# Option A — native tool (preferred when available)
EnterWorktree spike/<experiment-name>
# … run the spike …
ExitWorktree   # auto-cleans if no commits were made

# Option B — raw git fallback
git worktree add .worktrees/spike-<name> -b spike/<name>
cd .worktrees/spike-<name>
# … run the spike …

# Discard path
git worktree remove --force .worktrees/spike-<name>
git branch -D spike/<name>

# Keep path — graduate via finishing-a-development-branch
# (cherry-pick or re-implement cleanly on the target branch)
```

Use `EnterWorktree` / `ExitWorktree` when available. Drop to raw git only when no native tool exists.

## Pitfalls

| ❌ Anti-pattern | ✅ Fix |
|---|---|
| Spiking directly on the main branch | Always open a worktree first; the whole point is isolation |
| Forgetting to discard the worktree after a failed spike | Explicit discard step — run `git worktree remove --force` + `git branch -D` |
| Smuggling spike code into the real change without redoing it cleanly | Graduate by re-implementing on the target branch, not by merging spike commits |
| Leaving the worktree directory unignored and tracked | Verify `.worktrees/` is in `.gitignore` before creating a project-local worktree |

## After

On **keep:** invoke v1 **finishing-a-development-branch** to graduate the experiment — re-implement or cherry-pick cleanly onto the target branch, then open a PR.

On **discard:** remove the worktree and branch (see cheat sheet). Verify the main tree with:

```bash
git status   # must show: nothing to commit, working tree clean
```

**PROVEN BY:** `git status` output showing a clean main tree (`nothing to commit, working tree clean`) is the required close of this skill. No clean-tree confirmation = spike not done.
