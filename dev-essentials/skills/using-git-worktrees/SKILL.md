---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

The mechanical steps — isolation detection, directory priority, ignore verification, worktree creation, project setup, baseline capture — are implemented in `scripts/setup-worktree.sh` (next to this file). The skill text covers the judgment calls: asking consent, preferring native tools, deciding what to do with a failing baseline.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, run the helper — don't re-derive the git state by hand:**

```bash
scripts/setup-worktree.sh detect
```

(Path is relative to this skill's directory.)

Output is a fixed key=value block:

```
STATE=already-isolated | submodule | normal-repo
BRANCH=<branch name or DETACHED>
WORKTREE_PATH=<path>
LOCATION=<directory the git fallback would use>   # normal-repo/submodule only
LOCATION_SOURCE=project-local-existing | global-legacy | default
NEXT=skip-creation-go-to-setup | ask-consent-then-prefer-native-tool
```

The submodule guard is built in: `STATE=submodule` means the GIT_DIR/GIT_COMMON split is for submodule reasons — treat it as a normal repo, never as existing isolation.

**If `STATE=already-isolated`:** You are already in a linked worktree. Skip to Step 3 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `STATE=normal-repo` (or `submodule`):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 3.

## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 3.

Native tools handle directory placement, branch creation, and cleanup automatically. Using the git fallback when you have a native tool creates phantom state your harness can't see or manage. The script never replaces this step — `create` is the fallback, not the default.

Only proceed to Step 1b if you have no native worktree tool available.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available.

```bash
scripts/setup-worktree.sh create <branch-name> [directory]
```

Pass `[directory]` only when the user has declared a worktree directory preference — explicit preference beats everything. Otherwise the script applies the priority order itself: existing `.worktrees/` > existing `worktrees/` > legacy global `~/.config/superpowers/worktrees/<project>` > default `.worktrees/`.

The script refuses to nest inside an existing linked worktree, verifies project-local directories are git-ignored before creating anything (adding the entry to `.gitignore` and committing if missing — prevents worktree contents being tracked), then runs `git worktree add` and prints `WORKTREE_PATH=`. `cd` to that path.

**Sandbox fallback:** If `create` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run `setup` and `baseline` in place.

## Step 3: Project Setup

```bash
scripts/setup-worktree.sh setup
```

Auto-detects `package.json` / `Cargo.toml` / `requirements.txt` / `pyproject.toml` / `go.mod` and runs the matching install; skips when no manifest is recognized.

## Step 4: Verify and Record Clean Baseline

Run the test suite THROUGH the helper so the result is recorded, not just reported:

```bash
scripts/setup-worktree.sh baseline -- <test command>
# e.g.  baseline -- npm test    baseline -- pytest    baseline -- go test ./...
```

The run is captured as a fixed evidence block (`BASELINE_CMD`, `BASELINE_EXIT`, `BASELINE_STATUS`, `BASELINE_COMMIT`, `BASELINE_DATE`, `BASELINE_DIGEST`, `BASELINE_SUMMARY`, `BASELINE_OUTPUT`) stored in this worktree's own git dir — it survives the session and is removed automatically when the worktree is cleaned up.

**If tests fail:** Report failures, ask whether to proceed or investigate. If the user proceeds, the failing baseline stays recorded — that is the point: at finish time it proves which failures were pre-existing.

**If tests pass:** Report ready.

### Baseline handshake (exit condition)

This skill's exit artifact is the recorded baseline. At finish time, finishing-a-development-branch's Step 1 (verify tests) should compare against it instead of merely re-running:

```bash
scripts/setup-worktree.sh baseline-compare
```

This re-runs the recorded command and prints `VERDICT=clean | regression | fixed | pre-existing-failure` — distinguishing "you broke it" from "it was already broken". Use `baseline-show` to inspect the block without re-running.

### Report

```
Worktree ready at <full-path>
Baseline recorded: <BASELINE_STATUS> (<BASELINE_SUMMARY>)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| `STATE=already-isolated` | Skip creation (Step 0) |
| `STATE=submodule` | Treat as normal repo (consent, then Step 1) |
| Native worktree tool available | Use it (Step 1a) — never run `create` |
| No native tool | `setup-worktree.sh create <branch>` (Step 1b) |
| User declared a directory | Pass it: `create <branch> <dir>` |
| No directory guidance | Script priority: `.worktrees/` > `worktrees/` > global legacy > default |
| Directory not ignored | Script adds to `.gitignore` + commits, before creation |
| Permission error on create | Sandbox fallback: work in place, still run `setup` + `baseline` |
| Tests fail during baseline | Report failures + ask; failing baseline stays recorded |
| No recognized manifest | `setup` skips dependency install |
| Finishing the branch | `baseline-compare` for the regression-vs-pre-existing verdict |

## Common Mistakes

### Fighting the harness

- **Problem:** Using the git fallback when the platform already provides isolation
- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools. `create` is last resort.

### Hand-rolling the mechanics with raw git

- **Problem:** Re-deriving detection/directory-choice/creation reintroduces the classic failures: nested worktrees, submodules mistaken for isolation, unignored worktree directories polluting `git status`, directory locations that violate project conventions
- **Fix:** Use `scripts/setup-worktree.sh` — `detect` includes the submodule guard, `create` refuses to nest, verifies ignore entries before creating, and applies the directory priority by construction

### Running baseline tests outside the helper

- **Problem:** The result is reported then forgotten; at finish time nobody can prove which failures are new
- **Fix:** Always run Step 4 through `baseline -- <cmd>` so the evidence block exists for `baseline-compare`

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed — and keep the failing baseline recorded so `baseline-compare` can render the verdict later

## Red Flags

**Never:**
- Create a worktree when `detect` reports `STATE=already-isolated`
- Use the git fallback when you have a native worktree tool (e.g., `EnterWorktree`). This is the #1 mistake — if you have it, use it.
- Skip Step 1a by jumping straight to `create`
- Hand-roll the detection, directory choice, ignore verification, or creation that `setup-worktree.sh` implements
- Run baseline tests outside `baseline` — an unrecorded baseline gives finishing-a-development-branch nothing to compare
- Proceed with failing tests without asking

**Always:**
- Run `detect` first
- Prefer native tools over the git fallback
- Pass an explicit user directory preference to `create`; otherwise let the script's priority order decide
- Run `setup`, then `baseline -- <test command>`, in the new worktree
- Hand off to finishing-a-development-branch with `baseline-compare` at finish time
