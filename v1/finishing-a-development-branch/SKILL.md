---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.

The mechanical steps — environment detection, CWD-safe merge, provenance-checked
cleanup — are implemented in `scripts/finish-branch.sh` (next to this file). The
skill text covers the judgment calls: verifying tests, presenting the choice,
writing the PR, confirming destruction.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

**Baseline handshake (worktree branches):** if the worktree has a recorded
baseline (see using-git-worktrees), run
`bash ../path-to/v1/using-git-worktrees/scripts/setup-worktree.sh baseline-compare`
instead of judging raw test output: `VERDICT=clean` or `VERDICT=fixed` proceeds;
`VERDICT=regression` stops; `VERDICT=pre-existing-failure` means the failure
predates this branch — surface it to the user rather than blocking on it.

### Step 2: Detect Environment

**Run the helper — don't re-derive the git state by hand:**

```bash
scripts/finish-branch.sh detect
```

(Path is relative to this skill's directory.)

Output is a fixed key=value block:

```
STATE=normal-repo | worktree-branch | worktree-detached
BRANCH=<branch name or DETACHED>
BASE_BRANCH=main | master | UNKNOWN
WORKTREE_PATH=<path>
MAIN_ROOT=<path>
PROVENANCE=none | superpowers | external
MENU=standard-4 | detached-3
CLEANUP=no-worktree | script-owned | harness-owned-do-not-remove
```

- `MENU` selects which menu to present in Step 3.
- `CLEANUP` says who owns workspace cleanup: `script-owned` worktrees are removed
  by the `cleanup` subcommand; `harness-owned-do-not-remove` worktrees are never
  removed (the script refuses by design — if your platform provides a
  workspace-exit tool, use it; otherwise leave the workspace in place).
- If `BASE_BRANCH=UNKNOWN`, ask: "This branch split from main - is that correct?"
  and pass the answer explicitly to `merge` in Step 4.

### Step 3: Present Options

**Use a structured multiple-choice question (AskUserQuestion-style) with a
recommended default — not a prose menu.**

**Recommended default:** "Push and create a Pull Request" when an `origin` remote
exists (`git remote get-url origin`), otherwise "Merge back locally".

**`MENU=standard-4` — present exactly these 4 options:**

| # | Label | Description |
|---|-------|-------------|
| 1 | Merge back to <base-branch> locally | Land it now: merge, retest, clean up branch and worktree |
| 2 | Push and create a Pull Request | Send for review; branch and worktree stay for iteration |
| 3 | Keep the branch as-is | I'll handle it later; nothing changes |
| 4 | Discard this work | Destructive: deletes branch, commits, and worktree (typed confirmation required) |

**`MENU=detached-3` — present exactly these 3 options (no local merge on a
detached HEAD):**

| # | Label | Description |
|---|-------|-------------|
| 1 | Push as new branch and create a Pull Request | Send for review |
| 2 | Keep as-is | I'll handle it later; nothing changes |
| 3 | Discard this work | Destructive: deletes commits (typed confirmation required) |

**Don't add explanation beyond the descriptions** - keep options concise.

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
scripts/finish-branch.sh merge <feature-branch> [base-branch]
```

The script cds to the main repo root (CWD safety), checks out the base branch,
fast-forwards from upstream when one exists, merges, and prints `MERGE_SHA=<sha>`.
On conflict it stops and leaves branch and worktree intact.

Then verify tests on the merged result:

```bash
<test command>
```

**Only after tests pass on the merged result:**

```bash
scripts/finish-branch.sh cleanup <feature-branch>
```

`cleanup` removes the worktree first (provenance-checked, executed from the main
root), then deletes the branch — in that order, by construction.

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

**Do NOT run `cleanup`** — user needs the branch and worktree alive to iterate on
PR feedback.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't run `cleanup`.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation. The structured choice in Step 3 does NOT replace
this — discard always requires the typed word.

If confirmed:

```bash
scripts/finish-branch.sh cleanup <feature-branch> --force
```

`--force` uses `git branch -D`. The provenance check still applies: the script
refuses to remove harness-owned worktrees even when discarding.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch | Script command |
|--------|-------|------|---------------|----------------|----------------|
| 1. Merge locally | yes | - | - | yes | `merge`, test, then `cleanup` |
| 2. Create PR | - | yes | yes | - | none |
| 3. Keep as-is | - | - | yes | - | none |
| 4. Discard | - | - | - | yes (force) | `cleanup <branch> --force` |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" is ambiguous
- **Fix:** Present the structured choice with a recommended default (4 options, or 3 for detached HEAD)

**Cleaning up worktree for Option 2**
- **Problem:** Remove worktree user needs for PR iteration
- **Fix:** Only run `cleanup` for Options 1 and 4

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

**Hand-rolling the mechanics with raw git**
- **Problem:** Re-deriving detection/merge/cleanup reintroduces the classic failures: `git worktree remove` run from inside the worktree being removed, branch deleted before its worktree (so `git branch -d` fails), harness-owned worktrees removed (phantom state)
- **Fix:** Use `scripts/finish-branch.sh` — it prevents all three by construction (cds to main root first, removes worktree before branch delete, refuses worktrees outside `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`)

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without typed confirmation
- Force-push without explicit request
- Run `cleanup` before confirming the merge succeeded and tests pass on the result (Option 1)
- Hand-roll the detect/merge/cleanup mechanics that `finish-branch.sh` implements

**Always:**
- Verify tests before offering options
- Run `finish-branch.sh detect` before presenting the menu
- Present the structured choice with a recommended default (4 options, or 3 for detached HEAD)
- Get typed confirmation for Option 4
- Run `cleanup` for Options 1 & 4 only

## Supercharged vs upstream

Baseline: obra/superpowers 5.1.0 `finishing-a-development-branch`, otherwise verbatim. Change applied: **Option A — Scriptify (+B menu), recommended option adopted 2026-06-11** (v1/SUPERCHARGING-OPTIONS.md).

What changed and why:

- **Shipped `scripts/finish-branch.sh` with `detect|merge|cleanup` subcommands** (Option A, CC3): environment detection, base-branch inference, CWD-safe merge, and provenance-checked worktree-then-branch cleanup are now executed, not re-derived from prose each time. Why: this skill was ~80% mechanical, and three of upstream's seven Common Mistakes (worktree removal from inside the worktree, branch-before-worktree deletion order, harness-owned cleanup) were prose rules the agent could violate — the script makes them impossible by construction (it cds to `MAIN_ROOT` first, removes the worktree before deleting the branch, and refuses worktrees outside the superpowers-owned paths).
- **Steps 2–6 collapsed into Steps 2–4 around script calls**: upstream's hand-written `GIT_DIR`/`GIT_COMMON` detection, base-branch probing, merge recipe, and cleanup procedure are replaced by `detect` (fixed key=value output the agent reads), `merge` (stops on conflict, prints `MERGE_SHA`), and `cleanup` (`--force` for discard). Why: SKILL.md now carries only the judgment calls — verify tests, choose an exit, write the PR body, confirm destruction — per Option A's "skill text shrinks to judgment calls".
- **Structured exit menu with recommended default** (Option B folded in, CC1): the prose 4-option/3-option menus become AskUserQuestion-style structured choices with per-option descriptions and a recommended default (PR when an `origin` remote exists, local merge otherwise). Why: prose menus get misread; structured choices don't. Discard keeps its typed-"discard" confirmation on top of the structured choice.
- **Common Mistakes and Red Flags rewritten to match**: the three script-prevented mistakes collapse into one "hand-rolling the mechanics" entry; the remaining entries (test verification, structured choice, Option-2 preservation, typed discard) stay as judgment rules. Why: prose warnings should only cover what the script can't enforce.
- **Step 1 consumes using-git-worktrees' baseline handshake** (audit follow-up, 2026-06-11): when a recorded baseline exists, `baseline-compare`'s VERDICT replaces raw test-output judgment, so pre-existing failures are surfaced instead of blocking the merge. Why: closes the one-directional cross-reference the skill-auditor flagged.
