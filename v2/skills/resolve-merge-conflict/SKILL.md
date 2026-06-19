---
name: resolve-merge-conflict
description: Use when a git merge, rebase, cherry-pick, or stash pop stops with conflicts — resolves each conflicted hunk by reconstructing both sides' intent, then sweeps for the silent semantic conflicts that have no markers, and gates resolution on a green build + tests before continuing.
author: Donal Moloney
tier: v2
supports: [using-git-worktrees, verification-before-completion]
type: technique
chains-to: verification-before-completion
pairs-with: hoi-poi-capsule
---

## Not this skill if

- The conflict is in a **lockfile or generated artifact** (`package-lock.json`, `poetry.lock`, `*.pb.go`, snapshots) — don't hand-merge; take one side then regenerate (`npm install`, `poetry lock`, the codegen command) and commit the regenerated file.
- You started the operation **by mistake** — `git merge --abort` / `git rebase --abort` / `git cherry-pick --abort` and rethink, rather than resolving.
- The conflict is in a **binary asset** — pick a version deliberately (`git checkout --theirs/--ours <file>`); there is nothing to merge line-by-line.
- A merge would be cleaner as a **rebase or vice versa** — decide the integration strategy first (that's v1 **finishing-a-development-branch** / **using-git-worktrees**), then resolve.

# Resolve Merge Conflict

## Purpose

Git stops only at **textual** overlap — two sides touching the same lines. The conflicts that ship bugs are **semantic**: one side renames a function, the other adds a call to the old name on a line that never conflicted; one side changes a return type, the other consumes it elsewhere. No markers, clean `git` state, broken code. This skill resolves the marked hunks *with intent* and then sweeps for the unmarked breakage — and treats "git is happy" as necessary but never sufficient. Resolution isn't done until the build and tests are green.

Supports v1 **using-git-worktrees** (resolve integration conflicts in isolation) and v1 **verification-before-completion** (the green-suite gate below is its evidence rule applied to merges).

## The ours/theirs trap

`ours`/`theirs` **flip meaning** between merge and rebase. Confirm which operation you're in (`git status` names it) before using either:

| Operation | `--ours` is… | `--theirs` is… |
|---|---|---|
| `merge` | your current branch (HEAD) | the branch being merged in |
| `rebase` | the branch you're rebasing **onto** (upstream) | **your** commit being replayed |
| `cherry-pick` | HEAD | the commit being picked |

Picking the wrong side is the most common way to silently drop your own work during a rebase.

## Procedure

1. **Orient.** `git status` — list the full conflict set and the operation in progress. Resolve files in dependency order (shared/core files before their callers) so semantic checks downstream are meaningful.
2. **Reconstruct both intents — per file, before editing.** Read the whole hunk with surrounding context, not just the marked lines. Use `git log --merge -p -- <file>` (and `git diff <base>...<side>` for each parent) to see *why* each side changed. You cannot merge intents you haven't read.
3. **Resolve to satisfy both, not to pick a winner.** Combine the two changes unless one side is genuinely obsolete. Delete every `<<<<<<<`, `=======`, `>>>>>>>` marker. "Accept current/incoming" wholesale is a decision to discard one side's work — only do it when that is actually what you mean.
4. **Semantic sweep — the step that catches silent breakage.** After markers are gone, take every symbol either side renamed, removed, or changed the signature of, and grep the whole tree for stale references the conflict markers never touched. Reconcile them.
5. **Verify before staging.** Build, then run the **full** test suite (not just the touched files' tests — a merge can break distant code). A clean merge with a red suite is an unresolved merge.
6. **Stage explicitly and continue.** `git add <each resolved path>` (named paths, never `-A` blind), then `git merge --continue` / `git rebase --continue` / `git cherry-pick --continue`. For a multi-commit rebase, the next commit may conflict too — repeat from step 1.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Resolving marker-by-marker without reading either side's intent | `git log --merge -p` each file first; merge intents, not text |
| Assuming `--ours`/`--theirs` mean the same in rebase as in merge | Check the op; in rebase `--theirs` is *your* work |
| Stopping once the markers are gone | Run the semantic sweep — the dangerous conflict has no markers |
| `git add -A` to clear conflicts | Stage named paths; a stray resolved-wrong file slips through `-A` |
| `--continue` on a green `git status` but a red build | Build + full suite is the gate, not marker absence |
| Hand-merging a lockfile | Take one side, regenerate, commit the regenerated file |

## After

Hand the resolved, green state to v1 **verification-before-completion** (or v2 **done-gate**) before claiming the integration is complete.

PROVEN BY: post-resolution build + full test-suite output (totals, 0 failures) captured *after* the last conflict marker was removed and *before* `--continue`/commit, plus the result of the semantic sweep (symbols checked → references reconciled). Marker-free `git status` alone does not satisfy this skill.
