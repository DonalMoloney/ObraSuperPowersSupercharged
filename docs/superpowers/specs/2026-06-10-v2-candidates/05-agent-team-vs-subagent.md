# agent-team-vs-subagent — v2 candidate spec

| Field | Value |
|---|---|
| Type | **skill** (decision) |
| Theme | Parallelization |
| Tier | v2 |
| Supports (v1) | dispatching-parallel-agents, subagent-driven-development |
| Composes with (v2) | context-sufficiency-check, merge-parallel-results |
| Status | proposed |

## Problem

v1 `dispatching-parallel-agents` was written when subagents were fire-and-forget:
one prompt in, one result out, no follow-up. Modern Claude Code adds long-lived,
*addressable* teammates (named agents you can message repeatedly, with their
context intact). Using the wrong model wastes either context (re-explaining to a
fresh subagent what a teammate already knew) or money (keeping a teammate alive
for what one dispatch could do). No v1 skill covers the choice.

## What it does

Decision skill: choose fire-and-forget subagent vs. persistent named teammate
per task, plus lifecycle rules for teammates (naming, continuing, retiring).

## Parts

### `SKILL.md`

**Frontmatter**
- `name: agent-team-vs-subagent`
- `description`: "Use when about to dispatch agent work and the task may need
  follow-up, iteration, or back-and-forth — decides between a one-shot subagent
  and a persistent named teammate, and gives teammate lifecycle rules."
- `tier: v2`, `type: decision`, `supports:` as above.

**Section: Not this skill if**
- Work is a single self-contained query/task with no conceivable follow-up —
  plain subagent via v1 `dispatching-parallel-agents`, no decision needed.

**Section: The decision table (core content)**
| Signal | One-shot subagent | Named teammate |
|---|---|---|
| Result needs follow-up questions | — | ✓ |
| Same agent will get multiple sequential tasks in one domain | — | ✓ |
| Task is parallel fan-out of identical shape (N searches) | ✓ | — |
| Agent must hold evolving state (a doc it owns, a branch it tends) | — | ✓ |
| You only need the conclusion, not a relationship | ✓ | — |

Default on uncertainty: one-shot. A teammate is a commitment; a subagent is a
function call.

**Section: Teammate lifecycle rules**
- **Name at spawn** — role-based (`reviewer`, `db-migrator`), not generic.
- **Continue, don't respawn** — a follow-up to an existing teammate keeps its
  context; spawning fresh re-pays the entire briefing cost. Before any spawn,
  check whether a live teammate already covers the role.
- **One owner per artifact** — two teammates editing the same file is the same
  collision as two subagents; the independence test from
  `parallel-plan-executor` (#4) applies.
- **Retire explicitly** — when the role's work is done, stop messaging it;
  don't park open-ended "in case" teammates.

**Section: Prompt differences**
- Subagent prompts: complete and final (v2 `context-sufficiency-check` applies
  in full).
- Teammate first-message: role + standing context + first task; later messages
  may be incremental.

## Workflow

About to dispatch → run decision table → one-shot: v1
`dispatching-parallel-agents` as written → teammate: spawn named, manage per
lifecycle rules → results merge via v2 `merge-parallel-results` either way.

## Interfaces

- **v1 dispatching-parallel-agents**: unchanged for the one-shot path; this
  skill is a router in front of it.
- **v1 subagent-driven-development**: teammates suit its "implementer +
  spec-reviewer + code-quality-reviewer" loop — same reviewer across tasks
  beats a fresh one each time.

## Success criteria

- Given five scenario vignettes, the table yields an unambiguous answer for all
  five.
- Sessions stop re-briefing fresh agents for roles a live teammate already held.

## Risks / open questions

- Teams/teammate APIs are newer and may shift; keep mechanics thin and
  principles thick so the skill survives API churn.
- Does teammate cost (kept context) need a stated budget heuristic? Probably a
  one-liner: "more than ~3 idle turns → retire."
