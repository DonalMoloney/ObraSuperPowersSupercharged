# v7 — Tool ports as runnable Claude Code plugins

Ports of notable published AI tools/artifacts into installable Claude Code plugins
(starting with Karpathy's). Where **v4** distills Karpathy/Cherny *ideas* into skills,
**v7** ports a *specific named artifact* into a runnable plugin.

## Contract

Each port = `v7/plugins/<name>/`: an installable plugin
(`.claude-plugin/plugin.json` + `commands/` + `skills/` + `scripts/`, optional `hooks/`).
Every v7 plugin MUST:

1. Name the source artifact + release date in a `## Provenance` section and the skill's
   `inspiration:` frontmatter.
2. Preserve the source's core invariant (autoresearch: the harness — not the LLM — owns
   accept/reject).
3. Be runnable out of the box via a deterministic example.
4. Carry `tier: v7` on its skill(s).

`skill-auditor` applies to the skill(s); shell harnesses must be `shellcheck`-clean.

## Plugins

| Plugin | Source artifact | What it does |
|--------|-----------------|--------------|
| `autoresearch` | Karpathy AutoResearch (2026-03-07) | Keep-or-revert optimization loop over any measurable objective |
