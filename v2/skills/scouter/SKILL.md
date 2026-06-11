---
name: scouter
description: Use before engaging any non-trivial task — takes a power-level reading (scope, risk, unknowns), maps it to a response band, and names which v1 skills to invoke; signals decomposition when the reading is over 9000.
author: Donal Moloney
tier: v2
supports: [using-superpowers, writing-plans, brainstorming]
type: process
chains-to: brainstorming
pairs-with: writing-plans
---

## Not this skill if

- The task is a single trivially-reversible edit — just do it and verify.
- The user already supplied an explicit plan — go to v1 **executing-plans**.

# Scouter

## Purpose

Gauge a task before engaging it. Wrong-sized responses waste work in both directions: planning ceremony for a one-line fix, or diving head-first into a five-subsystem feature. The scouter reading picks the response band *before* any work starts.

Supports v1 **using-superpowers** (the reading names which skills to invoke), v1 **writing-plans** (medium band routes there), and v1 **brainstorming** (over-9000 band routes to its decomposition guidance).

## Triggers

**Use when:**
- Starting any task that is not obviously trivial
- "Just add X" requests where X's true size is unclear
- Deciding whether to plan, brainstorm, or act directly

**Don't use when:**
- Mid-task — the engagement decision is already made
- An explicit plan exists

## The reading

Score three dials, each 1–3:

| Dial | 1 | 2 | 3 |
|---|---|---|---|
| **Scope** | one file | one module | cross-cutting |
| **Risk** | trivially reversible | revert needs care | hard to undo (data, public API, release) |
| **Unknowns** | none | one open question | several questions you can't answer |

Sum the dials: power level 3–9.

## Response bands

| Reading | Band | Action |
|---|---|---|
| 3–4 | **Low** | Act directly. Finish with v1 **verification-before-completion**. |
| 5–7 | **Medium** | Plan first: v1 **writing-plans**, then v1 **executing-plans**. |
| 8–9, or multiple independent subsystems in the request | **Over 9000** | Stop. The task is several projects in a trench coat — decompose via v1 **brainstorming**'s decomposition guidance; each sub-project gets its own reading. |

Any single dial at 3 forces at least **Medium** regardless of sum.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Eyeballing "looks easy" without a reading | Score all three dials explicitly |
| Letting scope creep without re-reading | Re-run the scouter when the task mutates |
| Over-9000 task pushed through one plan | Decompose first; one spec → plan → implement cycle per sub-project |
| Treating the reading as final | Scouters break — if mid-task evidence contradicts the band, re-read and escalate |

## After

State the reading in one line before starting work, e.g.:

`SCOUTER: scope 2 / risk 1 / unknowns 2 = 5 → Medium → writing-plans`

Then invoke the band's skill.
