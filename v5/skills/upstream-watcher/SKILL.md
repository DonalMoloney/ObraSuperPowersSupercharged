---
name: upstream-watcher
description: Use when scheduling automated upstream drift checks, keeping upstream-diff.md current, or running release-prep checks against tracked sources such as obra/superpowers.
author: Donal Moloney
track: D
type: process
chains-to: find-original-reason
pairs-with: scheduled-maintenance
---

## Not this skill if

- You have a one-off "has upstream X changed?" question — fetch and diff now; no cron needed.
- The skill is original to this repo with no upstream source — nothing to watch.

# Upstream Watcher

## Purpose

Register a recurring job that fetches each tracked upstream, measures edit-distance against the local copy, and surfaces only real drift. Keeps `upstream-diff.md` honest without manual checking.

## Triggers

**Use when:**
- Scheduling automated upstream monitoring (weekly, pre-release)
- `upstream-diff.md` may be stale after upstream repos have been active
- "Watch upstream for changes" / release-prep drift check

**Don't use when:**
- Skill has no upstream (original authorship)
- You need an instant one-off comparison

## The pattern

1. **Register the job** — use `CronCreate` (manage with `CronList` / `CronDelete`) or `/schedule` with weekly cadence and this skill as payload.
2. **Fetch upstream** — retrieve the current raw source file from each tracked repo (GitHub raw URL or local plugin cache).
3. **Compute edit-distance** — diff fetched upstream against `skills/<slug>/SKILL.md`. Record line-delta and a normalised distance score.
4. **Compare to baseline** — load last-run snapshot stored alongside `upstream-diff.md`. Store each upstream snapshot at `.upstream-watcher/snapshots/<skill-slug>.txt` (alongside `upstream-diff.md`); the run diffs the freshly fetched upstream against this file, then overwrites it. If delta exceeds threshold (>5% of file size or >10 net lines), mark drifted.
5. **Diff-only discipline** — if nothing moved, exit silently.
6. **On drift detected** — open a note or draft PR listing drifted skills with the raw diff attached. Do not auto-merge. Chain to `find-original-reason`; confirm divergence is not deliberate before patching. Update `upstream-diff.md` in the same PR.

### Tracked upstreams

| Upstream repo | Our skills |
|---|---|
| obra/superpowers 5.1.0 | skill-router, outline-plan, execute-plan, spawn-subagent, run-agents-in-parallel, write-tests-first, find-root-cause, verify-before-done, request-review, apply-review-feedback, finish-branch, scope-feature |
| mattpocock/skills | diagnose-bug, see-big-picture, spike-it, challenge-spec |
| pcvelz/superpowers | proof-gate |
| affaan-m/everything-claude-code | check-token-usage |
| muratcankoylan/agent-skills-for-context-engineering | detect-context-rot, shrink-context |
| ComposioHQ/awesome-claude-skills | write-pr-notes |
| alexgreensh/token-optimizer | optimize-tokens |

All rows: weekly cadence.

## Pitfalls

| | Wrong | Right |
|---|---|---|
| ❌ Blind re-sync | Pull upstream changes directly into local file | Chain to `find-original-reason` first; divergence may be deliberate |
| ❌ Noisy runs | Fire a note/PR even when nothing changed | Diff-only: silent unless drift exceeds threshold |
| ❌ Author field on re-sync | Add `author:` when refreshing a verbatim copy | Verbatim copies omit `author:`; adapted skills keep it |
| ❌ Stale record | Update skill file without touching `upstream-diff.md` | Both changes in the same commit; `upstream-diff.md` is source of truth |

**PROVEN BY:** fetched-upstream diff attached to the note/PR showing exact lines moved and edit-distance score against the local copy.
