# native-task-queue — v2 candidate spec

| Field | Value |
|---|---|
| Type | **skill** |
| Theme | Advanced Claude Code |
| Tier | v2 |
| Supports (v1) | executing-plans, subagent-driven-development |
| Composes with (v2) | session-handoff, parallel-plan-executor (#4) |
| Status | proposed |

## Problem

v1 `executing-plans` tracks progress as markdown checkboxes inside the plan
document. That ledger has three weaknesses modern Claude Code already solves
natively: it doesn't survive context compaction reliably (the model must re-read
and re-parse the plan), it isn't visible to parallel agents working the same
plan, and it can't express dependencies. Claude Code's native task tools
(create/update/list, with statuses and dependencies) are a real queue — but no
skill says when or how to use them as the plan's execution ledger.

## What it does

Defines the convention for mirroring a written plan into the native task queue
and keeping the two in sync: tasks as the *live* state, the plan document as the
*specification*.

## Parts

### `SKILL.md`

**Frontmatter**
- `name: native-task-queue`
- `description`: "Use when starting execution of a written plan with 3+ tasks,
  or when multiple agents will work the same plan — mirrors the plan into native
  Claude Code tasks as the live ledger, with sync and dependency rules."
- `tier: v2`, `supports: [executing-plans, subagent-driven-development]`.

**Section: Not this skill if**
- 1–2 step task — ledger overhead exceeds the work; just do it.
- No native task tools in the environment — fall back to v1 `executing-plans`'
  checkbox protocol unchanged.

**Section: The mirror convention (core content)**
- **One task per plan task**, title = plan task heading verbatim (greppable both
  ways); description carries plan file + section anchor, not a copy of the
  content — the plan stays the single source of truth for *what*; the queue is
  the single source of truth for *status*.
- **Dependencies declared at creation** from the plan's ordering, which is what
  lets #4 `parallel-plan-executor` read ready-to-run tasks mechanically.
- **Status protocol**: `in_progress` before the first edit of a task, never
  after; `completed` only after that task's verification ran green (v1
  `verification-before-completion` evidence rule applies to status flips).
- **One in_progress task per agent** at any time.

**Section: Drift rule**
The plan document is amended only for *specification* changes (scope, approach);
checkbox edits stop entirely. If queue and plan disagree on status, the queue
wins; if they disagree on content, the plan wins.

**Section: Multi-agent use**
Parallel agents claim tasks by flipping `in_progress` (visible queue = cheap
mutual exclusion); the dispatching session watches the queue, not transcripts,
for progress.

**Section: Compaction & handoff**
After compaction, the queue is the recovery point: list tasks, find
`in_progress`, resume. The v2 `session-handoff` block shrinks to a pointer at
the queue plus the non-status context only.

## Workflow

plan approved → mirror into queue with dependencies → execute per status
protocol → queue empty + all verified → v1 `finishing-a-development-branch`.

## Interfaces

- **v1 executing-plans**: replaces its tracking layer only; review checkpoints
  and execution discipline unchanged. (Candidate `## Supercharged vs upstream`
  note in v1.)
- **#4 parallel-plan-executor**: consumes the dependency graph this convention
  creates; the two specs should land together or #4 ships with its own interim
  tracking.
- **v2 session-handoff**: handoff blocks get smaller; reference this skill.

## Success criteria

- Mid-plan compaction test: execution resumes on the correct task from queue
  state alone, without re-reading the full plan.
- Two agents working one plan never both mark the same task `in_progress`.

## Risks / open questions

- Tool availability varies by environment — the fallback line to plain
  `executing-plans` is mandatory, not optional.
- Granularity mismatch: plan tasks too coarse to be claimable units suggest the
  plan needs splitting — push back to `writing-plans` rather than inventing
  sub-tasks ad hoc in the queue.
