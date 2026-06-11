---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**This skill is the degraded-mode twin of superpowers:subagent-driven-development.** It executes the same plans with the same two-stage review (spec pass first, then quality pass) and the same task status vocabulary (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED) — but every role is played by you in a single context instead of by fresh subagents. A plan should execute identically on either skill; only who reviews changes.

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## Entry and Exit Conditions

- **Entry condition:** an approved written plan (produced by superpowers:writing-plans) and an isolated workspace (verified or created by superpowers:using-git-worktrees).
- **Exit skill:** superpowers:finishing-a-development-branch — the only exit on success.
- **If the plan needs rework mid-execution:** return to superpowers:writing-plans for an amendment; do not improvise a new plan inside this skill.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. **Self-run spec review:** re-read the task's literal text from the plan file (not from memory), then review the actual `git diff` against it. Nothing missing, nothing extra. Fix gaps and re-verify before continuing.
5. **Self-run quality review:** review the same diff for code quality — naming, duplication, magic numbers, test coverage. Fix issues and re-verify. Never start the quality pass before the spec pass is clean (same ordering rule as subagent-driven-development).
6. Assign the task a status from the vocabulary below. Only DONE tasks get marked completed.

**Honest limitation:** a self-run review is weaker than the fresh-context reviewers subagent-driven-development dispatches — you are predisposed to approve your own work. Reviewing the real diff against the plan's literal task text (rather than your memory of either) narrows that gap; it does not close it. That residual weakness is the cost of running without subagents, and is why the note above tells you to prefer subagent-driven-development when available.

### Task Status Vocabulary

Use the same statuses as subagent-driven-development's implementers, so progress reports read identically regardless of which skill executed the plan:

- **DONE** — implemented, verified, both review passes clean. Mark completed and continue.
- **DONE_WITH_CONCERNS** — work complete but you have doubts. Record the concern alongside the task. Correctness or scope concerns must be resolved before moving on; pure observations (e.g., "this file is getting large") may carry forward.
- **NEEDS_CONTEXT** — the plan doesn't provide information you need. Stop and ask your human partner; don't guess.
- **BLOCKED** — the task cannot be completed as written (missing dependency, failing verification, wrong assumption in the plan). Stop and report the blocker with evidence. If the plan itself is wrong, your partner amends it via superpowers:writing-plans and you return to Step 1.

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

Report every stop using the status vocabulary above (NEEDS_CONTEXT or BLOCKED) so your partner sees the same statuses subagent-driven-development would have produced.

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Run both review passes per task — spec first, then quality — and assign a status
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks

**Full-strength twin:**
- **superpowers:subagent-driven-development** - Same plan, same two-stage review, same status vocabulary, but with fresh-context subagent reviewers. Prefer it whenever subagents are available.

## Supercharged vs upstream

Option C — Degraded-mode twin, recommended option adopted 2026-06-11.

Changes from the upstream obra/superpowers 5.1.0 skill:

- **Twin framing added to Overview.** The skill now explicitly declares itself the no-subagent fallback of superpowers:subagent-driven-development, so the choice between the two skills is about platform capability, not process differences.
- **Entry and Exit Conditions section added (CC2).** Entry (approved plan + isolated worktree) and exit (finishing-a-development-branch) are stated explicitly, and mid-execution plan rework is routed back to writing-plans — completing the workflow-graph wiring that upstream left partial.
- **Two-stage self-review added to Step 2.** Each task now ends with a self-run spec compliance pass (diff vs. literal plan text) followed by a self-run quality pass, mirroring subagent-driven-development's spec-then-quality ordering rule so plans execute identically regardless of platform.
- **Shared status vocabulary added.** Tasks report DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED — the same statuses subagent-driven-development's implementers use — and stop conditions now report in that vocabulary. Upstream had no per-task status at all.
- **Honest limitation stated.** Per the option's trade-off, the skill says plainly that self-review is weaker than fresh-context review, names the mitigation (review the real diff against the literal plan text), and admits the mitigation does not close the gap.
- **Integration section gained a "Full-strength twin" entry** pointing to subagent-driven-development, making the twin relationship discoverable from both directions.

Why: upstream executing-plans was the thinnest skill in the tier — "follow each step exactly" with no defined review or status mechanics — so the same plan produced different rigor depending on whether subagents were available. The twin reframing imports subagent-driven-development's quality gates in self-run form, keeping plan execution consistent across platforms while being honest about the residual weakness.
