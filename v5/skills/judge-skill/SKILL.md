---
name: judge-skill
description: Use when you want to score a SKILL.md before committing it, after editing an existing skill, or when a skill is flagged for quality review — emits a 0–100 score, per-dimension breakdown, and a prioritised fix list.
author: Donal Moloney
track: D
type: decision
chains-to: writing-skills
---

## Not this skill if
- You are still drafting the skill body — finish a complete draft first
- You want to find which skill to use — use `skill-router` or `semantic-router` instead
- You want to test skill *behaviour* against a contract — use `skill-test-harness`

# judge-skill — quality scorer for SKILL.md files

## Purpose

Skill quality is invisible until a skill fails in production. This skill makes quality measurable before commit: five dimensions, 0–100 total, with a prioritised fix list so the author knows exactly what to improve.

**Scoring rubric lives in:** [`rubric.md`](rubric.md) — consult it for exact 0/3/5 breakpoints.

## Dimensions

| # | Dimension | Max pts | Key question |
|---|-----------|---------|--------------|
| 1 | **Trigger clarity** | 20 | Does `description:` start with "Use when"? Is the trigger concrete and searchable? |
| 2 | **Process completeness** | 20 | Are all steps numbered, explicit, and runnable by a stranger? |
| 3 | **Proof-gate presence** | 20 | Is there a `PROVEN BY:` tag, a verification step, or an explicit pair with `proof-gate`? |
| 4 | **Voice consistency** | 20 | Imperative voice throughout? No marketing language, no hedges, no falsifiable percentages? |
| 5 | **Section completeness** | 20 | All required sections present: Purpose, Triggers/When-to-use, Process or Core Pattern, Pitfalls or Failure modes? |

Total: **100 points**. Target: **≥ 80 to ship**. Scores below 80 block the pre-commit gate.

## Process

1. **Read the target `SKILL.md`** in full — do not score from memory or a summary.

2. **Score each dimension independently** using the 0/3/5 table in `rubric.md`. Record raw score (0, 3, or 5) before applying the multiplier (×4 per dimension = 20 pts max).

3. **Emit the scorecard:**

```
SKILL JUDGE REPORT — <skill-name>
──────────────────────────────────
Trigger clarity      [score]/20
Process completeness [score]/20
Proof-gate presence  [score]/20
Voice consistency    [score]/20
Section completeness [score]/20
──────────────────────────────────
TOTAL                [score]/100   [PASS ≥ 80 | FAIL < 80]
```

4. **Emit the fix list** — ordered by impact (lowest-scoring dimension first):

```
FIX LIST (highest priority first)
1. [dimension] — [one-sentence description of the gap and how to close it]
2. ...
```

5. **If total ≥ 80:** state `PASS — safe to commit`. Chain to `writing-skills` for final deployment checklist if this is a new skill.

6. **If total < 80:** state `FAIL — do not commit`. The author must address fixes and re-run `judge-skill` before the pre-commit gate will clear.

## Scoring rules

- Score **each dimension independently**. Do not let a strong dimension compensate for a weak one in your reasoning — the numbers handle that.
- Score what is **present**, not what was intended. If a section exists but is incomplete, score it as incomplete.
- A dimension cannot score above 3 if the content is ambiguous. Ambiguity is a defect, not a grey area.
- Proof-gate presence scores 0 if there is no verification step and no explicit `chains-to: proof-gate` or `Pairs with: proof-gate` reference.

## Failure modes

| Symptom | Fix |
|---------|-----|
| Scorecard emitted without reading full file | Read the entire SKILL.md before scoring — no skimming |
| Score inflated by overall quality impression | Score each dimension in isolation; total last |
| Fix list is vague ("improve the description") | Each fix entry must name the exact line or section and the specific change |
| Proof-gate dimension scored high when no evidence exists | No `PROVEN BY:` and no verification step = score 0, no exceptions |

## Pairs with

- `writing-skills` — the authoring workflow this skill validates against
- `proof-gate` — the enforcement layer that blocks claims without evidence
- `skill-test-harness` — behavioural testing; judge-skill covers structural quality only
- `ci-fan-out-gate` — can run judge-skill as a CI check and auto-emit `PROVEN BY:`

## Evidence format

When used in CI or as a pre-commit gate, emit:

```
PROVEN BY (judge-skill): judge-skill <skill-name> → score [N]/100 [PASS|FAIL]
```
