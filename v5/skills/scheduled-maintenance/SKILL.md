---
name: scheduled-maintenance
description: Use when recurring, unattended hygiene of the skills framework is needed — weekly skill audits, upstream drift detection, stale-alias sweeps, or any time-triggered framework health job that should run without a human in the loop.
author: Donal Moloney
track: D
type: process
chains-to: write-pr-notes
pairs-with: skill-router
---

## Not this skill if

- The need is a one-off audit right now — run the relevant audit skill directly instead.
- The task is code CI, not skills hygiene — use a CI pipeline or a GitHub Action.

# Scheduled Maintenance

## Purpose

Register recurring remote agents that audit the skills framework on a cadence and act only on real drift. Runs that find nothing stay completely silent.

## Triggers

**Use when**
- "Audit the skills weekly"
- "Watch upstream for drift"
- "Set up recurring maintenance"
- Release-cadence hygiene — keep `upstream-diff.md`, `CLAUDE.md`, and `AGENTS.md` honest without manual checks

**Don't use when**
- A single, immediate audit is enough
- The scope is application code, not framework files

## The pattern

### Register a job

| Option | When to use |
|---|---|
| `/schedule` skill | Natural-language setup; handles cron expression automatically |
| `CronCreate` tool | Precise control over schedule, payload, and timeout |

Use `CronList` to inspect registered jobs. Use `CronDelete` to retire a job when the corresponding skill is removed.

### Recommended recurring jobs

| Job | Skill to invoke | Cadence | Acts on |
|---|---|---|---|
| Orphan / cycle check | skill-dependency-graph | Weekly | Skills with no inbound refs or circular calls |
| Dead skill sweep | audit-dead-skills | Weekly | Skills with no recorded invocations |
| Upstream drift | upstream-watcher | Weekly | Divergence vs `obra/superpowers` and tracked upstreams |
| Alias sweep | alias-sweep | Monthly | Aliases in `CLAUDE.md` / `AGENTS.md` pointing to renamed or deleted skills |

### Diff-only discipline

Every scheduled run must evaluate findings before acting:

1. Run the audit skill.
2. Clean output → exit silently. No note, no PR, no message.
3. Drift found → capture audit output as evidence, then continue to **After**.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct behaviour |
|---|---|
| Run posts a note/PR even when nothing drifted | Silent exit when clean; act only on real findings |
| Job with side effects runs without a dry-run pass | Add a dry-run flag or confirmation gate before any destructive action |
| Retired skill still has a registered cron job | Call `CronDelete` in the same change that removes the skill |
| Cadence far shorter than the audit runtime | Match interval to audit duration; weekly is the safe default |

## After

Pipe audit output into write-pr-notes to auto-fill the note body. PR title: job name + date. Body: diff only, no boilerplate.

```
PROVEN BY: audit output from <job-name> run on <date> — attached as the PR body via write-pr-notes
```
