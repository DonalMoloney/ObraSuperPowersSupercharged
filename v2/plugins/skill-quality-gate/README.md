# skill-quality-gate (v2 plugin)

Mechanical pre-merge enforcement of skill authoring quality. A `PostToolUse` hook
scores every `SKILL.md` write/edit against this repo's structural + content rubric
and **warns** (default) or **blocks** when a skill is not ship-ready. The shape it
enforces is this repo's, not the upstream Python-package model: markdown reference
docs with tier-specific frontmatter and a verification loop.

tier: v2 · supports: writing-skills · amplifies: v2 skill-lint, v2 skill-test-harness

## What it supports

- **v1 writing-skills** — the authoring doctrine (RED-GREEN-REFACTOR, CSO,
  token-efficiency). This plugin mechanizes the checkable residue of those rules so
  the gate fires on every write instead of relying on the author to remember.
- **v2 skill-lint** — the seven-point commit-time structural checklist. This gate is
  the always-on, write-time form; skill-lint goes deeper at commit time.
- **v2 skill-test-harness** — the behavioral proof. This gate is the cheap static
  pass that runs *before* the heavier harness; a clean score is not behavioral proof.

## Components

| Part | Role |
|---|---|
| `hooks/score-skill.sh` | PostToolUse (Write/Edit): if the file is a `SKILL.md`, score it; warn or block on a low score |
| `scripts/score_skill.py` | the deterministic scorer — structural pass + content pass, single 0–100 |
| `standards/skill-standards.md` | the canonical rubric both embedded skills and the scorer reference |
| `skills/skill-quality-validator/` | embedded skill — the **structural** pass (frontmatter, name-matches-dir, tier fields) |
| `skills/skill-evaluator/` | embedded skill — the **content** pass (description, naming, size, example, verification loop) |
| `commands/skill-score.md` | `/skill-score`: run the scorer on demand and print the breakdown |

## How the two embedded skills divide the work

- **skill-quality-validator (structural, 65 pts)** — does the file have the right
  *skeleton* for its tier? Frontmatter block, `name` equals directory, tier-specific
  required fields (v1 `## Supercharged vs upstream`, v2 `tier`+`supports`, v3
  `status: experimental`, v4 `inspiration`/`cites`), at least one `##` section.
- **skill-evaluator (content, 35 pts)** — is the *prose* ship-ready? `Use when`
  trigger, when-not-what description, kebab name, ≤ 500-line body, a concrete example,
  a closing verification loop, no placeholders, no tier drift.

The shared scorer runs both and sums them to one 0–100; threshold 80.

## What the hook blocks on

The hook fires only on files literally named `SKILL.md`. When the combined score is
below threshold (default 80), in `block` mode it exits 2 — blocking the tool result
and asking for a fix — and lists the specific failing checks. In the default `warn`
mode it prints the same report without blocking.

## Configuration (environment variables)

| Var | Default | Meaning |
|---|---|---|
| `SQG_MODE` | `warn` | `warn` prints a report; `block` exits 2 (blocks the write); `off` disables |
| `SQG_THRESHOLD` | `80` | minimum combined score to pass |

Start in `warn` and tune on real skill edits before switching to `block` — false
blocks are what get enforcement hooks uninstalled (same lesson as the
verification-gate plugin).

## Usage outside the hook

```bash
python3 scripts/score_skill.py v2/skills/skill-lint/SKILL.md          # human report
python3 scripts/score_skill.py --json path/to/SKILL.md                # structured object
for s in v2/skills/*/SKILL.md; do python3 scripts/score_skill.py "$s"; done   # whole tier
```

Or run `/skill-score` to score the named (or most-recently-edited) skill in session.

## Verification

PROVEN BY: `score_skill.py` is deterministic. Run it against a known-good v2 skill —
all twelve checks PASS, score 100. Delete a v2 skill's `supports:` field — `tier_fields`
(structural) drops to FAIL. Rewrite its description to summarize the workflow —
`description_trigger` and `description_when_not_what` (content) drop to FAIL. Each
failing check emits its exact `fix` line, on every run.
