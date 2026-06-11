---
name: zenkai-boost
description: Use immediately after any bug fix is verified — converts the failure into permanent strength by capturing a regression test, recording a one-line lesson, and sweeping for sibling instances before the fix is considered closed.
author: Donal Moloney
tier: v2
supports: [systematic-debugging, test-driven-development]
type: process
chains-to: verification-before-completion
pairs-with: loop-until-green
---

## Not this skill if

- The failure was environmental or flaky with no code-level cause — fix the environment, note it, move on.
- The bug is still unfixed — finish v1 **systematic-debugging** first; zenkai happens after recovery, not during the fight.

# Zenkai Boost

## Purpose

Saiyans come back stronger from every near-death. A bug fix that leaves no regression test, no recorded lesson, and unswept siblings is a recovery without the boost — the same failure can hurt you again. This skill makes the boost mandatory before the fix is closed.

Supports v1 **systematic-debugging** (its root-cause output feeds all three steps) and v1 **test-driven-development** (the regression test follows the red–green discipline).

## Triggers

**Use when:**
- A bug fix has just been verified
- A production incident or review finding has been resolved
- You catch yourself about to move on right after "it works now"

**Don't use when:**
- The fix isn't verified yet
- The failure had no code-level cause

## The three-step boost

### 1. Regression test

Write the test that would have caught this bug.
- Run it against the pre-fix code (stash the fix, or check out the prior revision): must **FAIL**.
- Run it against the fixed code: must **PASS**.

A regression test that never failed proves nothing.

### 2. One-line lesson

Record the *class* of mistake — not the instance — in the project's gotchas (CLAUDE.md or equivalent):

`<date>: <bug class> — <how to avoid>`

Skip recording only if an equivalent lesson already exists.

### 3. Sibling sweep

The same root cause usually has siblings. Search for the pattern the root cause implies (same misused API, same off-by-one shape, same unchecked input) and list every hit. Fix or ticket each one — silently ignoring a found sibling voids the boost.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Regression test written but never run against broken code | Verify FAIL-then-PASS; red first |
| Lesson describes the instance ("fixed null in parser.py") | Record the class ("parser entry points must null-check input") |
| Sweep skipped because "this was a one-off" | Run the search anyway; the grep is cheap, the second incident isn't |
| Boost steps done but fix not re-verified | Chain to v1 **verification-before-completion** |

## After

Invoke v1 **verification-before-completion** with the boost evidence attached: regression test name + FAIL/PASS runs, lesson location, sibling-sweep search used and hits found.
