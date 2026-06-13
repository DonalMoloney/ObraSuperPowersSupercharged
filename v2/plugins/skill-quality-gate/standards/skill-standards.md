# Skill quality standards (this repo)

Canonical rubric for `score_skill.py` and for the two embedded skills. Adapted to
ObraSuperPowersSupercharged conventions: skills here are **markdown reference docs**
with tier-specific frontmatter, not Python packages — so there are no README.md /
GUIDE.md / `*.py` / type-hint checks. The authority for the underlying authoring
doctrine is v1 **writing-skills**; this file only restates the mechanically
checkable subset.

Total: 100 points across two independent passes. Ship threshold: **80**
(override with `SQG_THRESHOLD`).

## Structural pass (skill-quality-validator) — 65 pts

Does the file have the right shape for its tier?

| # | Check | Points |
|---|---|---|
| S1 | `---` frontmatter block with non-empty `name` and `description` | 20 |
| S2 | Frontmatter `name` equals the skill's directory name (kebab-case) | 15 |
| S3 | Tier-specific required fields present (see table below) | 20 |
| S4 | Body has at least one `##` section heading (not a stub) | 10 |

### S3 — tier-specific required fields (CLAUDE.md tier rules)

| Tier | Required |
|---|---|
| v1 | a `## Supercharged vs upstream` body section (keeps upstream frontmatter shape) |
| v2 | `tier: v2` **and** a `supports:` field naming at least one v1 skill |
| v3 | `tier: v3` **and** `status: experimental` |
| v4 | `tier: v4` **and** an `inspiration:` / `cites:` field naming originator + idea |
| v5 | none — import-only holding area, no tier discipline |

## Content pass (skill-evaluator) — 35 pts

Is the prose ship-ready?

| # | Check | Points |
|---|---|---|
| C1 | Description begins with `Use when` (the CSO trigger phrase) | 15 |
| C2 | Description states WHEN (triggers/symptoms), third person, ≤ 500 chars — not a workflow summary | 10 |
| C3 | `name` is kebab-case, < 64 chars, no reserved prefix (`anthropic-` / `claude-`) | 10 |
| C4 | `SKILL.md` body under 500 lines (token-efficiency budget) | 15 |
| C5 | At least one concrete example — a fenced code block or a `## Example(s)` section | 10 |
| C6 | Ends in a feedback loop — `## Verification` / `## Review checklist` / `PROVEN BY:` / a verify reference | 15 |
| C7 | No placeholder text (`TODO`, `TBD`, `FILL:`, `PLACEHOLDER`, `coming soon`, …) | 10 |
| C8 | No tier/terminology drift — frontmatter tier agrees with the folder | 5 |

> Note: the point columns are calibrated independently per pass; `score_skill.py`
> sums every awarded point across both passes and reports a single 0–100 percentage.

## What this rubric does NOT prove

- **Effectiveness.** A skill can score 100 and still teach the wrong behavior.
  Behavioral proof is v2 **skill-test-harness** (spawns subagents, invokes the
  skill, grades transcripts).
- **Structural lint depth.** For the seven-point commit-time structural checklist
  (cross-tier reference resolution, explicit step lists), use v2 **skill-lint**.
- **Authoring doctrine.** The RED-GREEN-REFACTOR Iron Law and CSO rules live in
  v1 **writing-skills** — this file never restates them, only checks the
  mechanical residue.
