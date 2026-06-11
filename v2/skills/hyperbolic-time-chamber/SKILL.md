---
name: hyperbolic-time-chamber
description: Use before releasing a new or rewritten skill — a year of training in a day; stress-tests the draft against should-trigger scenarios and near-misses in isolation, tightening the description and triggers until they fire correctly.
author: Donal Moloney
tier: v2
supports: [writing-skills]
type: technique
chains-to: skill-lint
pairs-with: skill-lint
---

## Not this skill if

- Only formatting or structure changed, not behavior — run v2 **skill-lint** and move on.
- You can't name concrete scenarios where the skill should fire — that's a design gap; return to v1 **writing-skills** first.

# Hyperbolic Time Chamber

## Purpose

A year of training in a day, before the real fight. A skill that has never been exercised meets its first real scenario in production — and fails on its description (doesn't trigger), its boundaries (triggers when it shouldn't), or its body (doesn't actually help). The chamber runs those encounters cheaply, in isolation, before release.

Supports v1 **writing-skills** as the cheap pre-pass before its subagent pressure-testing protocol (`testing-skills-with-subagents.md`): drill the description and body on paper first, then spend subagent runs only on a draft that survived the chamber. Pairs with v2 **skill-lint**: lint checks structure statically; the chamber checks behavior.

## Triggers

**Use when:**
- A new skill draft is about to be released
- An existing skill's description, triggers, or core flow was rewritten
- A skill exists but keeps misfiring — triggering on the wrong tasks or missing the right ones

**Don't use when:**
- The change is cosmetic (typos, formatting)
- The skill's purpose itself is still undecided

## The training regimen

### 1. Build the scenario set

Before reading the draft again, write down:

| Set | Count | Contents |
|---|---|---|
| **Should-trigger** | 3+ | Realistic user phrasings and situations where this skill MUST be invoked — vary the wording, don't reuse the skill's own vocabulary |
| **Near-miss** | 2+ | Adjacent situations that look similar but belong to a different skill or no skill — the boundary cases |

If you can't produce three honest should-trigger scenarios, the skill's reason to exist is unclear — leave the chamber and go back to design.

### 2. Run the trigger drills

For each scenario, read ONLY the frontmatter `description` and ask: would a model scanning available skills invoke this one here?

- Should-trigger scenario fails to fire → the description is missing the situation's vocabulary; add WHEN language, not WHAT language.
- Near-miss fires → the description over-claims; sharpen the boundary and add it to the body's "Not this skill if".

### 3. Run the body drills

For each should-trigger scenario, walk the body as if executing it in that situation. Every step must be actionable in-scenario; any step that needs information the scenario doesn't have means a missing precondition or instruction.

### 4. The cold read

One final pass reading the whole skill with no scenario in mind: does it make sense to someone with zero context from this conversation? Names, examples, and references must stand alone.

**Exit criteria:** all should-trigger scenarios fire, all near-misses don't, the body walks cleanly in every scenario, and the cold read raises nothing. Until then, you stay in the chamber.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Scenarios written in the skill's own vocabulary | Use phrasings a real user would type, then check the description catches them |
| Only happy-path scenarios | Near-misses are mandatory — boundaries are where skills fail |
| Editing the body while drilling triggers | Trigger drills test the description alone; fix one layer at a time |
| Leaving the chamber on a feeling | Exit criteria are explicit; a failed drill means another round |

## After

Run v2 **skill-lint** for the static checks, then release. Record the scenario set in the skill's directory or PR description — the next rewrite reuses it as a regression suite.
