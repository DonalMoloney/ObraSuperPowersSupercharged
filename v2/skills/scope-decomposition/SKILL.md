---
name: scope-decomposition
description: Use when a project idea or spec might be too large for a single spec/plan cycle — applies four concrete over-scope heuristics, and if any fire, splits the work into dependency-ordered sub-projects that each get their own spec → plan cycle.
author: Donal Moloney
tier: v2
supports: [brainstorming, writing-plans]
type: technique
chains-to: writing-plans
---

## Not this skill if

- The scope is plainly single-feature sized — proceed with v1 **brainstorming** directly.
- The spec is right-sized but possibly wrong — attack it with v2 **red-team-spec**; decomposition fixes size, not correctness.

# Scope Decomposition

## Purpose

v1 **brainstorming** says "if the project is too large for a single spec, help the user decompose" and v1 **writing-plans** warns that multi-subsystem specs "should have been broken into sub-project specs" — but neither says how to detect "too large" or how to split. This skill supplies the detection heuristics and the splitting procedure.

## Over-scope heuristics

Run all four against the one-paragraph project description. Any single "yes" means decompose.

| # | Heuristic | Yes when |
|---|---|---|
| 1 | Independent user flows | ≥2 flows where a user could complete one without the other existing (e.g., "chat" and "billing") |
| 2 | Distinct data stores | The description implies ≥2 unrelated schemas/stores owned by different parts of the system |
| 3 | "And"-junctions | The one-sentence summary needs ≥2 "and"s joining capabilities (not joining steps of one capability) |
| 4 | Plan-size projection | An honest task list would exceed ~10 tasks or one implementation plan document |

## Procedure

1. Write the project as one sentence. Count capabilities, not adjectives.
2. Run heuristics 1–4; record yes/no each.
3. If all four are "no": stop — return to v1 **brainstorming** for a normal single spec.
4. If any "yes": list candidate sub-projects, one per independent capability/flow.
5. For each pair of sub-projects, record the dependency: A-blocks-B, B-blocks-A, or independent. Justify each non-independent edge in one line (shared schema, shared API, shared component).
6. Order sub-projects: dependencies first; among independents, highest user value first.
7. Confirm the split and the order with the user.
8. Take ONLY the first sub-project into v1 **brainstorming** → v1 **writing-plans**. The rest wait — their specs will be better informed by what shipping the first one teaches.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Splitting by technical layer (frontend/backend/db) | Split by capability — each sub-project ships working, testable software end-to-end |
| Speccing all sub-projects upfront | Spec only the first; later specs improve with shipped knowledge |
| Counting steps of one flow as separate flows | "Sign up and verify email" is one flow; "sign up and export reports" is two |
| Treating the order as fixed | Re-run the dependency check after each sub-project ships; edges change |

## After

Verify the decomposition held: the first sub-project's spec stands alone (no "see other sub-project" references needed to implement it), then chain to v1 **writing-plans**.

PROVEN BY: the pasted heuristic table (4 rows, yes/no) plus, when decomposing, the dependency-ordered sub-project list confirmed by the user. Speccing a multi-"yes" project as one unit is invalid under this skill.
