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
| `blast-radius` | requesting-code-review, verification-before-completion |
| `devils-advocate` | receiving-code-review, verification-before-completion |
| `incident-postmortem` | systematic-debugging |
| `migrate-codebase` | dispatching-parallel-agents, using-git-worktrees |
| `security-audit` | requesting-code-review, verification-before-completion |
| `track-assumption` | brainstorming, executing-plans, finishing-a-development-branch |
| `write-adr` | brainstorming, writing-plans |
| `browser-evidence-debugging` (plugin: chrome-devtools-toolkit) | systematic-debugging |
| `performance-trace-audit` (plugin: chrome-devtools-toolkit) | verification-before-completion |
| `memory-leak-hunt` (plugin: chrome-devtools-toolkit) | systematic-debugging |
| `ui-verification-loop` (plugin: playwright-toolkit) | verification-before-completion |
| `bug-reproduction-script` (plugin: playwright-toolkit) | systematic-debugging |
| `e2e-test-generation` (plugin: playwright-toolkit) | test-driven-development |

## Current plugins

| Plugin | Supports (v1) | Components |
|---|---|---|
| `verification-gate` | verification-before-completion, test-driven-development | Stop + PostToolUse hooks, `/verify-status` command |
| `chrome-devtools-toolkit` | systematic-debugging, verification-before-completion | 3 skills: browser-evidence-debugging, performance-trace-audit, memory-leak-hunt |
| `playwright-toolkit` | verification-before-completion, systematic-debugging, test-driven-development | 3 skills: ui-verification-loop, bug-reproduction-script, e2e-test-generation |
