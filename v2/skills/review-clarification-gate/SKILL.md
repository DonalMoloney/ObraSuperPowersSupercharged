---
name: review-clarification-gate
description: Use when received review feedback contains any item that is unclear, ambiguous, or technically questionable — freezes implementation of ALL items until every one is classified, and provides the clarification-request template plus an escalation path when the reviewer is unavailable.
author: Donal Moloney
tier: v2
supports: [receiving-code-review, requesting-code-review]
type: process
chains-to: receiving-code-review
---

## Not this skill if

- Every feedback item is unambiguous and technically sound — implement directly via v1 **receiving-code-review**.
- You understand the item fully but disagree with it — that is push-back, handled inside v1 **receiving-code-review**; this gate only manufactures missing clarity.
- The spec (not the code) is what's being challenged — use v2 **red-team-spec** before implementation, not a review gate after it.

# Review Clarification Gate

## Purpose

v1 **receiving-code-review** commands "STOP, do not implement anything yet" when feedback is unclear — but provides no procedure for getting unstuck. This gate is that procedure: classify every item, extract real answers for the unclear ones, and only then hand the batch back to v1 **receiving-code-review** for implementation. It equally operationalizes the "request clarification" move v1 **requesting-code-review** prescribes when a reviewer's finding looks wrong.

**Core rule:** one unclear item freezes the whole batch. Partial implementation against a half-understood review is how wrong fixes ship with green checkmarks.

## The gate

1. **List** every feedback item verbatim in a classification table (one row per item).
2. **Classify** each row: `UNDERSTOOD` (meaning and motivation are both clear), `NEEDS-CLARIFICATION` (could be read ≥2 ways, or the motivation is opaque), or `PUSH-BACK` (understood, but you have evidence it's wrong).
3. For each `NEEDS-CLARIFICATION` row, send the clarification request using the template below. Never guess-and-implement.
4. If the reviewer does not respond or is unavailable, escalate one rung at a time: reviewer → your human partner → defer the item explicitly (record it as deferred, do NOT silently drop it).
5. Re-classify on each answer. The gate opens only when zero rows remain `NEEDS-CLARIFICATION`.
6. Chain to v1 **receiving-code-review** to implement `UNDERSTOOD` items and argue `PUSH-BACK` items with evidence.

## Clarification request template

> Re: "<quoted feedback item, verbatim>"
>
> I can read this at least two ways:
> (a) <concrete interpretation A — what code would change>
> (b) <concrete interpretation B — what code would change>
>
> Which did you mean? If neither, a one-sentence restatement would unblock me.

Stating candidate interpretations forces you to demonstrate you engaged with the item, and lets the reviewer answer with one letter.

## Escalation ladder

| Rung | When | Action |
|---|---|---|
| Reviewer | Always first | Send the template; wait for the answer before touching related code |
| Human partner | Reviewer unavailable or answer still ambiguous after one round-trip | Present the item + both interpretations; ask them to adjudicate |
| Explicit deferral | Nobody can adjudicate now | Record item + open question where deferred work is tracked; exclude it from this batch visibly |

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Implementing the "obvious" items while one is unclear | The gate freezes the whole batch — answers to unclear items often change "obvious" ones |
| Asking "what do you mean?" with no interpretations | Use the template; make the reviewer's answer a one-letter choice |
| Treating silence as agreement with your favorite reading | Silence escalates the ladder; it never resolves a row |
| Reclassifying an item PUSH-BACK to avoid asking | PUSH-BACK requires evidence you understand it; if you can't state the reviewer's motivation, it's NEEDS-CLARIFICATION |

## After

Verify before implementing: re-read the classification table and confirm zero `NEEDS-CLARIFICATION` rows remain, then proceed via v1 **receiving-code-review**.

PROVEN BY: the pasted classification table with every row resolved to `UNDERSTOOD` or `PUSH-BACK` (with answers quoted) before any implementation begins. Implementing with an open `NEEDS-CLARIFICATION` row is invalid under this skill.
