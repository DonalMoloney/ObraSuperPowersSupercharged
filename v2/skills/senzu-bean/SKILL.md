---
name: senzu-bean
description: Use when resuming work mid-task after context compaction, a crash, or a long interruption — rebuilds true working state from durable artifacts (plan doc, git state, test runs) instead of trusting recollection.
author: Donal Moloney
tier: v2
supports: [executing-plans]
type: process
chains-to: executing-plans
pairs-with: session-handoff
---

## Not this skill if

- A current v2 **session-handoff** document exists — read it first; senzu-bean fills gaps, it doesn't replace a handoff.
- You're starting fresh work, not resuming — there is no state to recover.

# Senzu Bean

## Purpose

A senzu bean restores full strength mid-fight. After context compaction, a crash, or days away, your memory of the task is the least reliable source available — the artifacts are the truth. This skill rehydrates working state from artifacts and pinpoints exactly where to resume.

Supports v1 **executing-plans** (resumes plan execution at the verified-correct step). Pairs with v2 **session-handoff** — a handoff doc is the best artifact; this skill is the recovery path when one is missing or stale.

## Triggers

**Use when:**
- Resuming after context compaction or a session crash
- Returning to a task after an interruption long enough to doubt the details
- A plan's checkboxes don't obviously match the workspace

**Don't use when:**
- Fresh task, nothing to recover
- A current handoff doc already answers "where was I?"

## The rehydration checklist

Run all four steps; artifacts over recollection at every one.

1. **Plan doc** — read it fully. Note which steps are checked off. Checked ≠ done; it's a claim to verify.
2. **Workspace state** — `git status`, `git diff`, `git log --oneline -10` (or non-git equivalents). What was *actually* changed?
3. **Ground truth** — run the test suite (or the plan's verification commands). What *actually* passes?
4. **Diff claimed vs actual** — compare the plan's checkmarks against steps 2–3. The first discrepancy is the resume point.

| Discrepancy | Meaning | Action |
|---|---|---|
| Checked, but workspace/tests disagree | Step claimed but not done (or regressed) | Uncheck; resume here |
| Unchecked, but workspace shows it done | Step done but unrecorded | Verify, then check it off |
| All consistent | State is clean | Resume at the first unchecked step |

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| "I remember where I was" | Memory is the degraded component — run the checklist |
| Trusting checkmarks without verifying | Re-run the verification command for the last checked steps |
| Resuming at the last checked step by default | Resume at the first *discrepancy*, which may be earlier |
| Recovering state but not recording it | Update the plan's checkboxes to match verified reality before resuming |

## After

With the resume point verified, continue under v1 **executing-plans**. If you expect to stop again soon, write a v2 **session-handoff** doc now — eating a senzu bean is the fallback, not the plan.
