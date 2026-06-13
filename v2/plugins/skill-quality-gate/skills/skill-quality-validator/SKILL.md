---
name: skill-quality-validator
description: Use when a SKILL.md needs its structural shape checked before merge — whether the frontmatter block, name-matches-directory rule, and tier-specific required fields are present for its v1–v5 tier. The structural half of the skill-quality-gate hook; pairs with skill-evaluator, which scores content quality.
author: Donal Moloney
tier: v2
supports: [writing-skills, skill-lint]
type: decision
pairs-with: skill-evaluator
---

## Not this skill if

- You need the **content** judged — description phrasing, naming, size, examples, verification loop — that is the sibling skill **skill-evaluator**. This skill only checks structural shape.
- You need the seven-point commit-time checklist with cross-tier reference resolution — that is v2 **skill-lint**, which goes deeper on body structure. This validator is the lightweight shape gate the hook runs on every write.
- You need behavioral proof the skill fires correctly — that is v2 **skill-test-harness**.
- The skill has not been written yet — author it with v1 **writing-skills** first.

# skill-quality-validator — structural gate for SKILL.md

## Purpose

Score the **structural shape** of a SKILL.md against the rubric in
`../../standards/skill-standards.md` (structural pass, 65 pts). It answers one
question: does this file have the right skeleton for the tier it lives in? It is
the structural half of the `skill-quality-gate` PostToolUse hook; the content
half is **skill-evaluator**.

Supports v1 **writing-skills** (which defines the authoring doctrine) and amplifies
v2 **skill-lint** by giving the hook a fast, deterministic shape check on every
SKILL.md write.

**Core rule:** A structural FAIL means the skeleton is wrong for the tier — fix the
shape before any content review. Shape is binary, not a matter of taste.

## When to use

- On every `Write`/`Edit` of a `SKILL.md` (the hook runs this automatically).
- Before merging a new or moved skill, to confirm it sits in the right tier with
  the right frontmatter.
- When promoting a v5 skill into v1–v4 — the destination tier's required fields
  change, and this catches a skill that kept its old shape.

## The four structural checks (65 pts)

Run in order; each is independently pass/fail.

1. **frontmatter_block (20)** — a `---` block with non-empty `name` and `description`.
2. **name_matches_dir (15)** — frontmatter `name` equals the skill's directory name (kebab-case).
3. **tier_fields (20)** — the tier-specific required fields are present:
   - **v1** — a `## Supercharged vs upstream` body section (upstream frontmatter shape kept).
   - **v2** — `tier: v2` **and** a `supports:` field naming ≥ 1 v1 skill.
   - **v3** — `tier: v3` **and** `status: experimental`.
   - **v4** — `tier: v4` **and** an `inspiration:` / `cites:` field (originator + idea).
   - **v5** — none (import-only holding area).
4. **has_section_headings (10)** — at least one `##` heading (rejects a stub).

The tier is inferred from the path (`v1/<name>/`, `v2/skills|plugins/<name>/`, …).

## Usage

```bash
python3 ../../scripts/score_skill.py --json path/to/SKILL.md   # full object; read the "structural" array
```

The shared scorer emits both passes; this skill is authoritative for the
`structural` array. A structural check with `"passed": false` carries a `fix`
line naming the exact missing field or section.

## Example

A v2 skill that forgot its `supports:` field:

```text
[structural]
  PASS frontmatter_block         20/20
  PASS name_matches_dir          15/15
  FAIL tier_fields                0/20
  PASS has_section_headings      10/10
  fixes:
    - v2 skills require `tier: v2` and a `supports:` field naming the v1 skill(s) supported.
```

## Review checklist

Before treating a structural verdict as authoritative:

- [ ] The target is a real `SKILL.md` (the scorer rejects any other filename).
- [ ] The path encodes the intended tier — a misfiled skill fails `tier_fields` for the *wrong* reason; move it first.
- [ ] `name_matches_dir` was checked against the on-disk directory, not the draft you intended to create.
- [ ] Any `fix` line was applied, not worked around, before re-running.

## Pairs with

- **skill-evaluator** — the content half of this gate; run both, they sum to one 0–100 score.
- v2 **skill-lint** — deeper seven-point structural checklist for commit time.
- v1 **writing-skills** — authoring doctrine; this validator never restates it.

PROVEN BY: the four checks are deterministic — running `score_skill.py --json` against a known-good v2 skill yields all four structural checks PASS, and against a v2 skill with its `supports:` field deleted yields `tier_fields` FAIL with the exact fix line above, on every run.
