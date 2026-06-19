# dev-essentials

A standalone, general-purpose Claude Code plugin: **15 skills for the universal
development loop** — plan → build → debug → verify → review → ship — plus the
cross-cutting workspace and thinking discipline that holds the loop together.

Every skill here applies to almost any coding task in any codebase. There is no
domain lock-in (no frontend/database/cloud specifics) and no dependency on any
particular project layout. Drop it in and the skills are available immediately.

## What's inside

| Phase | Skill | Use it when… |
|-------|-------|--------------|
| **Plan** | `brainstorming` | A fuzzy idea needs to become an agreed design before any code is written. |
| **Plan** | `writing-plans` | A spec needs to become a reviewable, step-by-step implementation plan. |
| **Build** | `test-driven-development` | Implementing a feature or fix — red → green → refactor, test first. |
| **Build** | `commit-checkpoints` | Multi-step work where any earlier step should be one `git reset` away. |
| **Debug** | `systematic-debugging` | Any bug, test failure, or surprise — hypothesis-first, not guess-and-check. |
| **Verify** | `verification-before-completion` | About to claim something is done/fixed/passing — show evidence first. |
| **Verify** | `fast-verify-loop` | Tighten the edit→verify cycle down to the fastest reliable signal. |
| **Review** | `requesting-code-review` | Work is complete and needs rigorous, risk-scaled review before merge. |
| **Review** | `receiving-code-review` | Acting on review feedback — verify and reason, don't perform agreement. |
| **Ship** | `finishing-a-development-branch` | Implementation is done and tests pass — decide merge vs PR vs cleanup. |
| **Workspace** | `using-git-worktrees` | Feature/risky work needs isolation from the current workspace. |
| **Think** | `karpathy-think` | A quick pre-task ritual: surface interpretation, alternatives, and scope. |
| **Think** | `devils-advocate` | A non-mechanical claim (design, root cause, finding) needs stress-testing. |
| **Think** | `write-adr` | A significant architectural decision needs a permanent rationale record. |
| **Think** | `incident-postmortem` | A failure or outage needs a structured, blameless postmortem and prevention. |

Several skills ship companion scripts/docs next to their `SKILL.md` (e.g.
`finishing-a-development-branch/scripts/finish-branch.sh`,
`writing-plans/scripts/lint-plan.py`). These are self-contained — they reference
only files within this plugin.

## Install

This is a standard Claude Code plugin (a `.claude-plugin/plugin.json` manifest with
auto-discovered `skills/`). To use it:

- **As a local plugin:** copy or symlink this `dev-essentials/` folder into your
  Claude Code plugins directory (e.g. `~/.claude/plugins/dev-essentials`), then
  restart Claude Code. The 15 skills become available via the `Skill` tool.
- **Per-project:** drop the folder under your project's `.claude/plugins/` (or
  wherever your setup discovers plugins).

No build step. The manifest plus the `skills/<name>/SKILL.md` directories are all
that's required.

## Provenance & attribution

These skills are a curated, repackaged subset distilled from the
`ObraSuperPowersSupercharged` tier library:

- The core dev-loop skills derive from **obra/superpowers** (the v1 tier — supercharged
  versions of the upstream obra superpowers skills).
- `commit-checkpoints`, `fast-verify-loop`, and `karpathy-think` come from the v4 tier
  (tools built on Andrej Karpathy's and Boris Cherny's published ideas).
- `devils-advocate`, `write-adr`, and `incident-postmortem` come from the v2 tier.

Each skill was rewritten to be self-contained: tier-specific frontmatter and
provenance scaffolding were stripped, and all cross-references now resolve within
this plugin. Curated and maintained by Donal Moloney.
