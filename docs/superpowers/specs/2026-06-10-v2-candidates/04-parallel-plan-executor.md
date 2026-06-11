# parallel-plan-executor — v2 candidate spec

| Field | Value |
|---|---|
| Type | **skill** |
| Theme | Parallelization |
| Tier | v2 |
| Supports (v1) | writing-plans, executing-plans, dispatching-parallel-agents, using-git-worktrees |
| Composes with (v2) | merge-parallel-results, context-sufficiency-check |
| Status | built 2026-06-10 — see `v2/skills/parallel-plan-executor/` |

## Problem

v1 has all the pieces — plans (`writing-plans`), execution (`executing-plans`),
parallel dispatch (`dispatching-parallel-agents`), isolation
(`using-git-worktrees`) — but no bridge: nothing says how to take a written plan
and decide *which tasks can safely run in parallel*, dispatch them isolated, and
reassemble. Today that judgment is ad hoc, and the failure mode (two agents
editing the same file) is expensive.

## What it does

Given a written plan, partitions tasks into parallel waves using an independence
test, dispatches each wave's tasks to worktree-isolated agents, and hands fan-in
to v2 `merge-parallel-results`.

## Parts

### `SKILL.md`

**Frontmatter**
- `name: parallel-plan-executor`
- `description`: "Use when a written plan has 3+ tasks and you suspect some are
  independent — partitions tasks into parallel waves, dispatches each into an
  isolated worktree agent, and merges results…"
- `tier: v2`, `supports:` as above.

**Section: Not this skill if**
- Plan has < 3 tasks or tasks form a strict chain — plain v1 `executing-plans`.
- Tasks are exploratory/research, not code — plain v1
  `dispatching-parallel-agents` (no worktrees needed).

**Section: The independence test (core content)**
Two tasks may share a wave only if ALL hold:
1. **No file overlap** — the sets of files each is expected to touch are
   disjoint (derive from the plan's per-task file lists; if the plan lacks
   them, STOP and go back to v1 `writing-plans` to add them).
2. **No ordering** — neither consumes the other's output (types, APIs,
   migrations).
3. **No shared mutable resource** — test DBs, ports, fixtures.
4. **Independently verifiable** — each task's tests can run green without the
   other's changes.

Anything uncertain → same wave is forbidden; sequence it.

**Section: Wave construction**
- Topologically sort tasks by dependency; group independent tasks per level into
  waves. Cap wave width (default 3 agents) — merge cost grows with width.

**Section: Dispatch protocol**
- One worktree-isolated agent per task (`isolation: worktree`).
- Each prompt passes the v2 `context-sufficiency-check` before dispatch.
- Prompt must include: the single task, its file list (as a boundary — "touch
  only these"), verification command, and required result format (for merge).

**Section: Fan-in**
- Wave completes → v2 `merge-parallel-results` for dedupe/contradiction/file
  collisions → run the full suite on the merged state → only then start the
  next wave.
- Any collision found at merge despite the independence test → record which
  test condition was wrong; re-sequence the remainder of the plan.

**Section: Failure handling**
- One agent fails, others succeed: merge the successes, run the failed task
  sequentially in the main session (it gets v1 `systematic-debugging` there).

## Workflow

plan → independence test → waves → per-wave: dispatch N worktree agents →
merge → verify merged state → next wave → done → v1
`finishing-a-development-branch`.

## Interfaces

- **v1 writing-plans**: imposes a requirement back on plans — per-task expected
  file lists. (Candidate `## Supercharged vs upstream` addition to v1.)
- **v2 merge-parallel-results**: the mandatory fan-in step.
- **v2 context-sufficiency-check**: the mandatory pre-dispatch gate.

## Success criteria

- A 6-task plan with 2 independent pairs executes in 2–3 waves with zero merge
  collisions.
- When the plan lacks file lists, the skill refuses to partition rather than
  guessing.

## Risks / open questions

- Plans rarely state file lists today — does the skill infer them (grep-based
  estimate) or hard-require them from `writing-plans`? Recommend hard-require;
  inference is how collisions happen.
- Wave width default (3?) needs real-world tuning.
- Worktree cleanup on abort — lean on `using-git-worktrees`' lifecycle rules.
