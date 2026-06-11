# v1 — Obra Superpowers, supercharged

BETTER versions of the 14 core skills from `obra/superpowers` 5.1.0, cached locally at
`~/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0/skills/`.

NOT from `/Users/donalmoloney/PycharmProjects/superpowers2/skills/` — that repo is a
rebranded fork ("Forge") with renamed slugs, rewritten content, and ~80 added skills.
It is inspiration material only.

Rules:
- Only the 14 core obra skills live here, under their upstream names. No new skill
  identities — those belong in `v2/`.
- Each skill starts as a verbatim port of upstream (verified with
  `diff -r <upstream-skill-dir> v1/<skill-name>`), then gets supercharged in place.
- Every v1 skill MUST have a `## Supercharged vs upstream` section listing what
  changed and why. A v1 skill without one is still an unmodified port.
