# v2 — Supporting skills and plugins (not core obra)

New skills and plugins that support and supercharge the v1 core, but are NOT
themselves obra superpowers skills. If a skill exists in upstream obra, improving it
happens in `v1/` — never here.

Rules:
- New skill identities only.
- Frontmatter must include `tier: v2` and `supports:` naming the v1 skill(s) or
  workflow it supports.
- Reference v1 content, never duplicate it.
- Plugins (commands, hooks, agents packaged together) are welcome here alongside
  plain skills.

Layout: skills live in `skills/<skill-name>/SKILL.md`, plugins in `plugins/<plugin-name>/`.

## Current skills

| Skill | Supports (v1) |
|---|---|
| `loop-until-green` | test-driven-development, verification-before-completion, systematic-debugging |
| `merge-parallel-results` | dispatching-parallel-agents, verification-before-completion |
| `parallel-plan-executor` | writing-plans, executing-plans, dispatching-parallel-agents, using-git-worktrees |
| `red-team-spec` | brainstorming, writing-plans, dispatching-parallel-agents |
| `review-clarification-gate` | receiving-code-review, requesting-code-review |
| `session-handoff` | executing-plans, writing-plans |
| `compress-md` | writing-skills, using-superpowers |
| `skill-lint` | writing-skills |
| `house-rules` | writing-skills |
| `spike-in-worktree` | using-git-worktrees, finishing-a-development-branch |
| `scouter` | using-superpowers, writing-plans, brainstorming |
| `shenron-wish` | subagent-driven-development, dispatching-parallel-agents |
| `zenkai-boost` | systematic-debugging, test-driven-development |
| `instant-transmission` | systematic-debugging |
| `senzu-bean` | executing-plans |
| `dragon-radar` | verification-before-completion, systematic-debugging |
| `kaioken` | dispatching-parallel-agents, systematic-debugging |
| `gravity-chamber` | test-driven-development, verification-before-completion |
| `fusion-dance` | brainstorming, writing-plans |
| `hyperbolic-time-chamber` | writing-skills |
| `hoi-poi-capsule` | using-git-worktrees, finishing-a-development-branch |
| `blast-radius` | requesting-code-review, verification-before-completion |
| `devils-advocate` | receiving-code-review, verification-before-completion |
| `incident-postmortem` | systematic-debugging |
| `migrate-codebase` | dispatching-parallel-agents, using-git-worktrees |
| `security-audit` | requesting-code-review, verification-before-completion |
| `track-assumption` | brainstorming, executing-plans, finishing-a-development-branch |
| `write-adr` | brainstorming, writing-plans |
| `compile-goal-to-contract` | subagent-driven-development, writing-plans |
| `decision-ledger` | brainstorming, writing-plans, executing-plans |
| `delta-debugger` | systematic-debugging, test-driven-development |
| `dispatch-triage` | subagent-driven-development |
| `done-gate` | verification-before-completion, requesting-code-review |
| `post-merge-retro` | finishing-a-development-branch |
| `reviewer-lenses` | requesting-code-review, dispatching-parallel-agents |
| `scope-decomposition` | brainstorming, writing-plans |
| `conflict-graph-scheduler` | dispatching-parallel-agents, subagent-driven-development |
| `hypothesis-ranker` | systematic-debugging |
| `evidence-trail` | verification-before-completion, finishing-a-development-branch |
| `test-impact-analysis` | test-driven-development, verification-before-completion |
| `spec-from-codebase` | brainstorming, writing-plans |
| `write-release-notes` | finishing-a-development-branch |
| `skill-test-harness` | writing-skills |
| `database-migration-planner` | writing-plans, systematic-debugging |
| `detect-agent-cheats` | subagent-driven-development, verification-before-completion |
| `ubiquitous-language` | brainstorming, writing-plans |
| `browser-evidence-debugging` (plugin: chrome-devtools-toolkit) | systematic-debugging |
| `performance-trace-audit` (plugin: chrome-devtools-toolkit) | verification-before-completion |
| `memory-leak-hunt` (plugin: chrome-devtools-toolkit) | systematic-debugging |
| `ui-verification-loop` (plugin: playwright-toolkit) | verification-before-completion |
| `bug-reproduction-script` (plugin: playwright-toolkit) | systematic-debugging |
| `e2e-test-generation` (plugin: playwright-toolkit) | test-driven-development |
| `skill-graph` | writing-skills, using-superpowers |
| `semantic-skill-router` | using-superpowers, dispatching-parallel-agents |
| `eval-driven-dev` | test-driven-development, verification-before-completion |
| `plan-drift-detector` | executing-plans, writing-plans |
| `flaky-test-quarantine` | test-driven-development, verification-before-completion |
| `bisect-the-regression` (plugin: regression-guard) | systematic-debugging |
| `resolve-merge-conflict` | using-git-worktrees, verification-before-completion |
| `safe-dependency-bump` | verification-before-completion, finishing-a-development-branch |
| `review-feedback-triage` | receiving-code-review |
| `pr-description-synthesizer` | requesting-code-review, finishing-a-development-branch |

## Current plugins

| Plugin | Supports (v1) | Components |
|---|---|---|
| `verification-gate` | verification-before-completion, test-driven-development | Stop + PostToolUse hooks, `/verify-status` command |
| `bug-hunter` | systematic-debugging, requesting-code-review | 6 hunter agents, 1 verifier agent, `/hunt-bugs` command |
| `chrome-devtools-toolkit` | systematic-debugging, verification-before-completion | 3 skills: browser-evidence-debugging, performance-trace-audit, memory-leak-hunt |
| `playwright-toolkit` | verification-before-completion, systematic-debugging, test-driven-development | 3 skills: ui-verification-loop, bug-reproduction-script, e2e-test-generation |
| `skill-quality-gate` | writing-skills, verification-before-completion | PostToolUse hook (scores SKILL.md writes, warn/block modes), `/skill-score` command, 2 skills: skill-evaluator, skill-quality-validator |
| `regression-guard` | test-driven-development, systematic-debugging | Stop hook (fail-soft verifier, warn/block modes), 1 skill: bisect-the-regression; chains to standalone flaky-test-quarantine + delta-debugger |
| `auto-format` | verification-before-completion, test-driven-development | PostToolUse hook (opt-in, formats edited file via project's prettier/ruff\|black/gofmt/rustfmt/shfmt), `/format-status` command |
