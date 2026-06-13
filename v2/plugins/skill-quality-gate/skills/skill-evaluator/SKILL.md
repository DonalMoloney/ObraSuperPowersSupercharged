---
name: skill-evaluator
description: Use when a SKILL.md needs its content quality scored before merge — description phrasing, name format, size budget, presence of a concrete example, a closing verification loop, and no placeholder text. The content half of the skill-quality-gate hook; pairs with skill-quality-validator, which checks structural shape.
author: Donal Moloney
tier: v2
supports: [writing-skills, skill-test-harness]
type: decision
pairs-with: skill-quality-validator
---

## Not this skill if

- You need the **structural shape** judged — frontmatter block, name-matches-directory, tier-specific required fields — that is the sibling skill **skill-quality-validator**.
- You need behavioral evidence the skill actually fires and produces the right behavior — that is v2 **skill-test-harness**. This skill scores the prose statically; it never runs the skill.
- You are still drafting and not yet shipping — the rubric is for ship-ready skills. Author with v1 **writing-skills** first.

# skill-evaluator — content-quality gate for SKILL.md

## Purpose

Score the **content quality** of a SKILL.md against the rubric in
`../../standards/skill-standards.md` (content pass, 35 pts). It answers: is the
prose ship-ready? It is the content half of the `skill-quality-gate` PostToolUse
hook; the structural half is **skill-quality-validator**.

Supports v1 **writing-skills** by mechanizing the checkable residue of its CSO and
token-efficiency rules, and amplifies v2 **skill-test-harness** by acting as the
cheap static gate that runs before the heavier behavioral test.

**Core rule:** Content checks are heuristics over prose, not proof of effectiveness.
A perfect content score still needs the behavioral proof of v2 **skill-test-harness**
before merge.

## When to use

- On every `Write`/`Edit` of a `SKILL.md` (the hook runs this automatically).
- Before merging a new or reworked skill, to confirm the description, naming, size,
  example, and verification loop meet the bar.
- After a wording change to a description — the `Use when` trigger and the
  when-not-what rule are the most commonly regressed checks.

## The eight content checks (35 pts)

Run in order; each is independently pass/fail.

1. **description_trigger (15)** — description begins with `Use when`.
2. **description_when_not_what (10)** — states WHEN (triggers/symptoms), third person, ≤ 500 chars — not a workflow summary (see v1 **writing-skills** CSO).
3. **name_format (10)** — kebab-case, < 64 chars, no reserved prefix (`anthropic-` / `claude-`).
4. **size_under_500_lines (15)** — body under 500 lines (token-efficiency budget).
5. **has_example (10)** — at least one fenced code block or a `## Example(s)` section.
6. **feedback_loop (15)** — ends in a `## Verification` / `## Review checklist` / `PROVEN BY:` block or a verify reference.
7. **no_placeholders (10)** — no `TODO` / `TBD` / `FILL:` / `PLACEHOLDER` / `coming soon`.
8. **consistent_terms (5)** — no tier/terminology drift (frontmatter tier agrees with the folder).

## Usage

```bash
python3 ../../scripts/score_skill.py --json path/to/SKILL.md   # full object; read the "content" array
python3 ../../scripts/score_skill.py --quiet path/to/SKILL.md  # exit non-zero if combined score < threshold
```

This skill is authoritative for the `content` array. Each failing check carries a
`fix` line naming the exact problem.

## Example

A description that summarizes the workflow instead of stating when to use it:

```text
[content]
  FAIL description_trigger            0/15
  FAIL description_when_not_what      0/10
  PASS name_format                   10/10
  PASS size_under_500_lines          15/15
  PASS has_example                   10/10
  PASS feedback_loop                 15/15
  PASS no_placeholders               10/10
  PASS consistent_terms               5/5
  fixes:
    - Description must begin with "Use when" and state the triggering condition (v1 writing-skills CSO).
```

## Review checklist

Before treating a content verdict as authoritative:

- [ ] The score is from the on-disk `SKILL.md`, not an in-memory draft.
- [ ] `consistent_terms` (heuristic) was spot-checked by a human — synonym/drift detection is approximate.
- [ ] `feedback_loop` matched a real verification section, not a stray "verify" in prose.
- [ ] Every `fix` line was applied, not patched around, before re-running.
- [ ] A clean content score was followed by a v2 **skill-test-harness** run — static-clean is not behaviorally-correct.

## Pairs with

- **skill-quality-validator** — the structural half of this gate; the two sum to one 0–100 score.
- v2 **skill-test-harness** — the behavioral proof that runs after this static gate is green.
- v1 **writing-skills** — defines the CSO and token-efficiency doctrine this skill mechanizes.

PROVEN BY: the eight checks are deterministic — `score_skill.py --json` against a description that begins "Checks whether…" yields `description_trigger` and `description_when_not_what` FAIL with the fix line above, and against a compliant description yields both PASS, on every run.
