---
name: fusion-dance
description: Use when two competing approaches to the same problem both have real merits and neither cleanly wins — synthesizes one design from both, with an explicit equal-power-level precondition and a final check that the fusion beats both donors.
author: Donal Moloney
tier: v2
supports: [brainstorming, writing-plans]
type: technique
chains-to: writing-plans
pairs-with: red-team-spec
---

## Not this skill if

- One approach dominates on every axis that matters — just pick it; fusion is for genuine trade-offs.
- The approaches solve different problems — that's decomposition (v1 **brainstorming**), not fusion.

# Fusion Dance

## Purpose

The fusion dance requires two fighters at equal power level and perfect synchronization — mismatched or sloppy, you get Veku, weaker than either dancer. Design synthesis has the same physics: merging a mature approach with a half-baked one, or gluing parts together without checking the seams, yields a design worse than either original. This skill makes the preconditions and the post-check explicit.

Supports v1 **brainstorming** (when "propose 2–3 approaches" ends with two real contenders) and v1 **writing-plans** (the fused design is what the plan gets written from).

## Triggers

**Use when:**
- Two proposed approaches each win on different axes you actually care about
- Two implementations of the same thing exist (spike vs incumbent) and both have keepers
- A reviewer's counter-proposal has real merit against yours

**Don't use when:**
- One option dominates outright
- The "two approaches" aren't solving the same problem

## The dance

### 1. Equal power level check

Both approaches must be developed enough to compare honestly: each can answer how it handles the same hard cases. If one is vague, develop it first or discard it — never fuse with a sketch.

### 2. Axis table

List the decision axes that matter; mark which approach wins each:

| Axis | Approach A | Approach B |
|---|---|---|
| e.g. read performance | wins | — |
| e.g. simplicity of writes | — | wins |

Drop axes where both tie — fusion only concerns the axes with a split decision.

### 3. Compose along winning axes

Take each axis from its winner, whole — no splitting the difference. Then inspect every seam: where A's part meets B's part, what assumption crosses the boundary? Each seam gets a sentence in the design.

### 4. The Veku check

Compare the fusion against BOTH donors on the full axis table. The fusion must beat or tie each donor overall, and the seams must not have created new worst-cases. If it doesn't clearly win — fusion failed; pick the stronger donor and move on. A failed fusion is a fine outcome; shipping Veku is not.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Fusing a design with a hand-wave | Equal power level first — develop or discard the sketch |
| Compromise on every axis ("split the difference") | Take each axis from its winner, whole |
| Seams unexamined | Every A-meets-B boundary documented |
| Sunk-cost fusion ("we discussed both so we must use both") | Veku check — failed fusion means pick one donor |

## After

Run the fused design through v2 **red-team-spec** if the stakes warrant it, then hand it to v1 **writing-plans**. Record the axis table in the design doc — it's the rationale future readers will ask for.
