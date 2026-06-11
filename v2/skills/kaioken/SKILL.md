---
name: kaioken
description: Use when normal effort has stalled after real attempts — applies a declared, budgeted burst of escalation (more parallel agents, deeper search, wider review) with a mandatory cooldown verification, because an unbounded power-up burns the session.
author: Donal Moloney
tier: v2
supports: [dispatching-parallel-agents, systematic-debugging]
type: process
chains-to: verification-before-completion
pairs-with: loop-until-green
---

## Not this skill if

- Normal effort hasn't actually been tried yet — escalation before a baseline attempt is just waste.
- The blocker is missing information only the user has — ask; no multiplier fixes an unknown requirement.

# Kaioken

## Purpose

Kaioken multiplies power at a cost to the body — used briefly and deliberately it wins fights; sustained, it breaks you. Effort escalation works the same way: more agents, broader sweeps, and deeper reviews are powerful and expensive (tokens, time, context). This skill makes escalation explicit — declared multiplier, fixed budget, forced cooldown — instead of an unbounded flail.

Supports v1 **dispatching-parallel-agents** (the multiplier is often "fan out the search") and v1 **systematic-debugging** (escalation path when the loop stalls).

## Triggers

**Use when:**
- Two solid normal-effort attempts at the same obstacle have failed
- A deadline-critical investigation needs breadth now, at known cost
- v2 **loop-until-green** is not converging and needs a stronger round

**Don't use when:**
- No baseline attempt exists
- The blocker is a decision or fact only the user can supply

## The burst protocol

Declare all four fields before powering up:

| Field | Example |
|---|---|
| **Trigger** | "Two attempts at localizing the flake failed" |
| **Multiplier** | x3 — three parallel agents on disjoint hypotheses |
| **Budget** | One round; results reviewed before any second burst |
| **Exit** | Converged (cause found) or budget spent — whichever first |

Escalation menu — pick the cheapest rung that can plausibly work:

1. Widen the search fan-out
2. Add parallel agents on *disjoint* slices
3. Deepen per-slice scrutiny
4. Bring a stronger reviewer to the judgment step

## Cooldown — mandatory

After the burst, before anything else:

1. Verify what the burst produced — run the checks; bursts produce claims, not facts.
2. Record what the multiplier actually bought. If nothing, the next burst needs a different *kind* of escalation, not a bigger number.
3. Return to normal effort. Back-to-back bursts without cooldown are the flail this skill exists to prevent.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Escalating on the first failure | Two genuine baseline attempts first |
| "x20!" — max everything at once | Cheapest plausible rung of the menu |
| Burst with no declared exit | Budget and exit condition written before powering up |
| Skipping cooldown verification | Burst output is unverified claims until checked |

## After

Cooldown's verification step hands its evidence to v1 **verification-before-completion**. If bursts keep failing on the same obstacle, stop multiplying — the task is mis-framed; return to v1 **systematic-debugging**'s root-cause discipline or escalate to the user.
