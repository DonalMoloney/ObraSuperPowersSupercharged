# v2 candidate specs — 2026-06-10

Candidate skills and plugins for the `v2/` tier, themed around **harness,
parallelization, loops, and advanced Claude Code**. Each file is a proposal-level
spec: problem, parts, workflow, interfaces with v1/v2, success criteria, and open
questions. None are approved or built yet — promotion into `v2/` follows the
normal brainstorm → spec → plan flow.

## Index

| # | Candidate | Type | Theme | Supports (v1) |
|---|-----------|------|-------|----------------|
| 1 | [verification-gate](01-verification-gate.md) | plugin (hooks + command) | Harness | verification-before-completion, test-driven-development |
| 2 | [background-verify](02-background-verify.md) | skill | Harness | executing-plans, verification-before-completion |
| 3 | [tdd-enforcer](03-tdd-enforcer.md) | plugin (hooks) | Harness | test-driven-development |
| 4 | [parallel-plan-executor](04-parallel-plan-executor.md) | skill | Parallelization | writing-plans, executing-plans, dispatching-parallel-agents, using-git-worktrees |
| 5 | [agent-team-vs-subagent](05-agent-team-vs-subagent.md) | skill (decision) | Parallelization | dispatching-parallel-agents, subagent-driven-development |
| 6 | [fan-out-code-review](06-fan-out-code-review.md) | skill | Parallelization | requesting-code-review, receiving-code-review, dispatching-parallel-agents |
| 7 | [unattended-loop](07-unattended-loop.md) | skill | Loops | executing-plans, verification-before-completion |
| 8 | [watch-and-resume](08-watch-and-resume.md) | skill | Loops | executing-plans, systematic-debugging |
| 9 | [native-task-queue](09-native-task-queue.md) | skill | Advanced Claude Code | executing-plans, subagent-driven-development |
| 10 | [headless-claude](10-headless-claude.md) | plugin (command + skill) | Advanced Claude Code | verification-before-completion, requesting-code-review |

## Recommended first picks

- **#4 parallel-plan-executor** — fills the real gap between three v1 skills and
  composes with existing v2 `merge-parallel-results` and `context-sufficiency-check`.
- **#1 verification-gate** — first true plugin in `v2/plugins/`, establishes the
  hooks-enforcement pattern the whole Harness theme depends on.
