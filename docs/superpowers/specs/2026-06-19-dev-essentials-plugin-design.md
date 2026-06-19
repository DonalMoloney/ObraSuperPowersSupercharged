# Design — `dev-essentials`: a standalone general-purpose Claude Code plugin

**Date:** 2026-06-19
**Status:** Approved (design); pending spec review
**Author:** Donal Moloney (with Claude Code)

## Goal

Curate the highest-leverage, **universally-applicable** skills scattered across this
repo's tiers (v1–v6) and sibling sources into a single, clean, **standalone Claude Code
plugin** — `dev-essentials/` at the repo root — that can be dropped straight into
`~/.claude/plugins` or installed as a plugin, with **none** of the v1–v6 tier discipline
baked in.

This is a *distillation/repackaging* deliverable, not a new-skill-authoring one. The
content already exists and is proven; the work is selecting the universal subset and
rewriting each skill to be self-contained and portable.

## Non-goals (YAGNI)

- No bundled hooks, agents, commands, or MCP config — **skills only** for this flagship.
- No domain- or tool-specific skills (frontend, database, security-audit, Figma, Vercel, etc.).
- No experimental (v3) or meta/skill-system-authoring skills (`writing-skills`,
  `using-superpowers`, `dispatching-parallel-agents`, `subagent-driven-development`).
- No changes to the existing v1–v6 tiers, their READMEs, or `CLAUDE.md` tier rules.
  `dev-essentials/` is additive and self-contained.

## Deliverable structure

A new top-level folder, free of tier discipline:

```
dev-essentials/
  .claude-plugin/
    plugin.json            # name, version, description, author
  skills/
    <skill>/SKILL.md       # one dir per skill, clean self-contained content
  README.md                # what's inside, install steps, provenance/attribution
```

`plugin.json` follows this repo's existing convention (see `v2/plugins/*/.claude-plugin/plugin.json`):

```json
{
  "name": "dev-essentials",
  "version": "0.1.0",
  "description": "Fifteen general-purpose skills for the universal dev loop — plan, build, debug, verify, review, ship — plus worktree and pre-task thinking discipline. Self-contained; works in any codebase.",
  "author": { "name": "Donal Moloney" }
}
```

## Flagship skill set (15)

Grouped by the universal dev loop: **plan → build → debug → verify → review → ship**,
plus cross-cutting workspace/thinking discipline. Every skill applies to almost any
coding task.

| # | Skill (dest name) | Source path | Purpose |
|---|---|---|---|
| 1 | `brainstorming` | `v1/brainstorming/SKILL.md` | Fuzzy idea → agreed design before coding |
| 2 | `writing-plans` | `v1/writing-plans/SKILL.md` | Spec → reviewable step-by-step plan |
| 3 | `test-driven-development` | `v1/test-driven-development/SKILL.md` | Red/green/refactor discipline |
| 4 | `commit-checkpoints` | `v4/skills/commit-checkpoints/SKILL.md` | Frequent restore-point commits for cheap rollback |
| 5 | `systematic-debugging` | `v1/systematic-debugging/SKILL.md` | Hypothesis-first debugging, not guess-and-check |
| 6 | `verification-before-completion` | `v1/verification-before-completion/SKILL.md` | Run checks + show evidence before "done" |
| 7 | `fast-verify-loop` | `v4/skills/fast-verify-loop/SKILL.md` | Tighten edit→verify to the fastest reliable signal |
| 8 | `requesting-code-review` | `v1/requesting-code-review/SKILL.md` | Get rigorous review of completed work |
| 9 | `receiving-code-review` | `v1/receiving-code-review/SKILL.md` | Respond to review with rigor, not agreement theater |
| 10 | `finishing-a-development-branch` | `v1/finishing-a-development-branch/SKILL.md` | Structured merge / PR / cleanup decision |
| 11 | `using-git-worktrees` | `v1/using-git-worktrees/SKILL.md` | Isolated workspaces for parallel/risky work |
| 12 | `karpathy-think` | `v4/skills/karpathy-think/SKILL.md` | Quick per-task pre-coding ritual (interpretation, scope) |
| 13 | `devils-advocate` | `v2/skills/devils-advocate/SKILL.md` | Stress-test a plan/spec before committing |
| 14 | `write-adr` | `v2/skills/write-adr/SKILL.md` | Capture an architecture decision + rationale |
| 15 | `incident-postmortem` | `v2/skills/incident-postmortem/SKILL.md` | Turn a failure into a durable lesson |

## Rewrite contract (applied to every skill)

Each source `SKILL.md` is copied into `dev-essentials/skills/<name>/SKILL.md` and then
made **self-contained and portable**:

1. **Frontmatter** — keep only `name` and `description`. The `description` must state
   *when* to use the skill (trigger), not just what it does. Remove tier-specific keys:
   `tier:`, `supports:`, `chains-to:`, `pairs-with:`, `status:`, `cluster:`.
2. **Strip provenance scaffolding** — remove any `## Supercharged vs upstream` section
   and any tier-bookkeeping prose.
3. **Resolve cross-references** — replace `[[wiki-links]]` and "see v1/… / v2/…"
   references with either (a) inline content if essential, (b) a plain reference to the
   sibling skill *by name within this plugin* if it's one of the 15, or (c) deletion if
   it points outside the plugin and isn't essential. No dangling references to tiers or
   to skills not shipped in `dev-essentials`.
4. **Preserve proven content** — keep the body's actual guidance, checklists, flowcharts,
   and red-flag tables intact. This is a repackaging, not a rewrite of the technique.
5. **Self-contained assets** — if a skill references `references/*.md` or other companion
   files, either copy them into the skill dir or inline the needed parts. No links to
   files outside `dev-essentials/`.

## README contents

- One-paragraph statement of what the plugin is (the universal dev loop, 15 skills).
- A table of the 15 skills grouped by loop phase (plan/build/debug/verify/review/ship +
  cross-cutting), each with a one-line description.
- Install instructions (drop into `~/.claude/plugins/`, or local plugin install).
- **Provenance/attribution**: derived from `obra/superpowers` (the v1 core) and this
  repo's v2/v4 tiers; authored/curated by Donal Moloney. Note it's a private repo.

## Acceptance criteria

1. `dev-essentials/.claude-plugin/plugin.json` exists, is valid JSON, has the four
   required keys, and `name` is `dev-essentials`.
2. Exactly 15 skill directories under `dev-essentials/skills/`, each with a `SKILL.md`.
3. Every `SKILL.md` has valid frontmatter with **only** `name` + `description`; no
   `tier:`/`supports:`/`status:`/`## Supercharged vs upstream` remnants.
4. `grep` finds **zero** dangling references to `v1/`…`v6/`, `[[…]]` wiki-links, or
   "Supercharged vs upstream" across `dev-essentials/`.
5. Every internal cross-reference points to one of the 15 bundled skills by name.
6. `README.md` lists all 15 skills and includes install + attribution.
7. The existing v1–v6 tiers are untouched (no diffs outside `dev-essentials/` and
   `docs/superpowers/specs/`).

## Build sequence (high level; detailed plan to follow)

1. Scaffold `dev-essentials/` (manifest + skills/ + README stub).
2. For each of the 15 skills: copy source → apply rewrite contract → save.
3. Write README with the grouped table + install + attribution.
4. Run the acceptance-criteria checks (greps + JSON validity + count).
5. Commit (staging explicit `dev-essentials/` and the spec path only — concurrent
   sessions edit this repo, so never `git add -A`).
