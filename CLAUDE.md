# ObraSuperPowersSupercharged

A five-tier evolution of `obra/superpowers` skills: supercharged better versions of
the core obra skills (v1), supporting skills and plugins outside core obra (v2),
experimental AI ideas (v3), Claude Code tools inspired by Andrej Karpathy and
Boris Cherny (v4), and a general catch-all of skills imported from the Forge fork (v5).

**v1 source (true upstream):** obra/superpowers 5.1.0, cached at
`~/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0/skills/` (14 skills).

**Forge fork (v5 source, NOT a v1 source):** `/Users/donalmoloney/PycharmProjects/superpowers2`
— a rebranded fork ("Forge") of obra/superpowers with renamed slugs, rewritten content,
and ~80 added skills. Imported wholesale into `v5/skills/` (88 skills) and useful as
idea material for v2/v3/v4 — never copied into v1.

**SelfImprovingAgent (v3/v4 idea source):** `/Users/donalmoloney/PycharmProjects/SelfImprovingAgent/`
— useful source material for v3 experimental ideas and v4 Claude Code tools inspired by
self-improving agent patterns and autonomous workflows.

## Tier rules — which folder you are in determines how you work

| Folder | Purpose | Discipline |
|--------|---------|------------|
| `v1/` | BETTER versions of the core obra superpowers skills — supercharged in place | Start from the verbatim upstream skill (obra/superpowers 5.1.0 plugin cache, see source above), keep the upstream skill name, then improve it. Every v1 skill MUST have a `## Supercharged vs upstream` section listing what changed and why. Only the 14 core obra skills live here — no new skill identities. |
| `v2/` | Supporting skills and plugins that supercharge the system but are NOT core obra | New skill identities only — anything that exists in upstream obra belongs in v1, not here. Each v2 skill/plugin names which v1 skill(s) or workflow it supports (`supports:` frontmatter) and must not duplicate v1 content — reference it. |
| `v3/` | Crazy / experimental AI ideas | Creativity over polish. Mark every skill `status: experimental` in frontmatter. No v1/v2 quality bar applies. |
| `v4/` | Claude Code tools built on Karpathy + Boris Cherny ideas | Each tool MUST cite the specific idea it builds on (e.g. Karpathy: LLM-as-OS, autonomy sliders, context discipline; Cherny: verification loops, hooks discipline, do-the-simple-thing). |
| `v5/` | General catch-all — skills imported wholesale from the Forge fork (`superpowers2/skills/`) | Holding area, no tier discipline. Keep skills verbatim as imported. When a skill earns a real home, promote it into v1–v4 under that tier's rules and remove it from v5. |
| `frontend/` | Domain folder (subject matter, not provenance) — frontend design, verification, debugging, performance skills | Browser-tool-driven: skills name concrete Chrome DevTools MCP / Playwright MCP steps, not abstract process. Frontmatter: `name`, `description`, `cluster: design \| verify \| debug \| perf` (no `tier:`). Every skill MUST end with a `## Verification` section naming concrete browser-tool evidence. Reference v1 skills, never duplicate them. |

## Skill format (all tiers)

- One skill per directory (kebab-case names). v1 is flat: `v1/<skill-name>/SKILL.md`.
  v2–v5 split by component type: `vN/skills/<skill-name>/SKILL.md` and
  `vN/plugins/<plugin-name>/`.
- SKILL.md frontmatter requires `name` and `description`; description states WHEN to
  use the skill, not just what it does.
- v2–v4 skills additionally require a `tier:` field (`v2`, `v3`, or `v4`).
- v1 skills keep their upstream frontmatter shape and add a
  `## Supercharged vs upstream` body section.

## Chaining skills together

Skills compose into workflows, not just standalone invocations. The relationship
vocabulary (`supports:`, `chains-to:`, `pairs-with:` frontmatter), the canonical
14-skill workflow graph (CC2 in `v1/SUPERCHARGING-OPTIONS.md`), and the
research-grounded options for chaining skills *better* — mapped to Anthropic's five
agent-workflow patterns (prompt chaining, routing, parallelization,
orchestrator-workers, evaluator-optimizer) — are documented in **`CHAINING-OPTIONS.md`**
at the repo root. Consult it before adding a skill that hands off to, builds on, or
runs alongside another.

## Workflow

- All 14 v1 baselines are ported. Supercharging is driven by
  `v1/SUPERCHARGING-OPTIONS.md`: pick one option per skill, hand it to the
  `skill-supercharger` agent as a work order, and record results in that skill's
  `## Supercharged vs upstream` section (tracker table at the bottom of the doc).
- When adding a v2 skill, also add it to the "Current skills" table in
  `v2/README.md` with the v1 skill(s) it supports.
- Design v3 skills with the `moonshot-ideator` agent (idea backlog: `v3/IDEAS.md`);
  v4 tools with the `karpathy-boris-architect` agent (idea backlog: `v4/IDEAS.md`).
- v5 is import-only: copy verbatim from `superpowers2/skills/` via `skill-porter`.
  To promote a v5 skill, rewrite it under the target tier's rules, move it, and
  delete it from `v5/`.
- Run the `skill-auditor` agent on any new or changed skill before committing.
- This is a git repository with `origin` at
  https://github.com/DonalMoloney/ObraSuperPowersSupercharged (private), created
  2026-06-10 via the global GitHub push convention. Default branch: `main`.
  Commit (and push when asked) after a skill passes the `skill-auditor` gate.

## Gotchas

- `superpowers2/skills/` contains a `v1/` subdirectory — that is the Forge fork's own
  rewrite pass, not this project's v1 tier. Don't confuse the two when importing to v5.
- Do not modify anything inside `/Users/donalmoloney/PycharmProjects/superpowers2` — it
  is read-only source material for this project.
- Forge skills overlap the 14 obra core under different names (e.g. `debugging`,
  `testing`). A v5 skill that shadows a v1 skill is improvement material for v1, not a
  promotion candidate for v2.
