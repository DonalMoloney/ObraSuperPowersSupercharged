---
name: commit-checkpoints
description: Use mid-task during multi-step work — commit at each verified increment so any earlier step is one `git checkout`/`git reset` away, then squash the throwaway checkpoints before the real PR
---

# Commit Checkpoints

**Not this skill if:** you are at the end of the work and need to integrate (merge, open the PR, delete the branch) → the `finishing-a-development-branch` skill owns end-of-work; this skill is strictly mid-work. If you need to decide how *big* each increment should be before you verify it, keep chunks small ad hoc. This skill assumes the increment is already verified; it governs only the commit that captures it.

A checkpoint is a commit you make the instant an increment goes green, so a wrong turn costs one increment, not the whole session. Cheap to make, cheap to throw away, squashed before anyone reviews. The one hard rule: you only checkpoint a verified-good state — a red or broken state is never committed as if it were a step forward.

## What counts as a checkpoint-worthy increment

Commit at the first moment one of these is true — and not before:

| Increment | Done means | Verify before committing |
|-----------|-----------|--------------------------|
| One passing test + the code it covers | The test is new/changed and now passes; the code it exercises exists | Run that test (or the file's suite) and see it green |
| One completed sub-task | A discrete item from the plan / todo list is fully done | The sub-task's own acceptance check passes |
| One green verifier run | Lint / typecheck / build / full suite passes after a batch of edits | Run the verifier and read the exit-0 output yourself |

If none of these is true, keep working — do not commit. A half-finished refactor, a test you have not run, or "I think this is right" is not a checkpoint.

## Commit cadence ladder

Match the checkpoint frequency to how reversible the work is. Finer cadence = smaller blast radius per wrong turn.

| Cadence | Checkpoint after… | Use when |
|---------|-------------------|----------|
| **Tight** | every single passing test | unfamiliar subsystem, risky refactor, or a recent wrong turn — you want the shortest possible rewind |
| **Normal** | every completed sub-task | routine feature work with decent coverage |
| **Loose** | every green verifier run over a batch | mechanical, low-risk edits (renames, formatting) where per-test commits would be noise |

When in doubt, tighten. The cost of an extra checkpoint is one squashed commit; the cost of a missing one is redoing lost work.

## The never-checkpoint-red rule

Before every checkpoint commit, confirm the working state is green with your own eyes — do not trust memory or assumption:

- The relevant test/verifier was actually run *in this state* and passed (exit 0).
- No known-broken edit is staged "to fix later".
- If the increment is genuinely incomplete and you must stash progress, that is a `git stash` or a clearly-labelled WIP — never a checkpoint that a later `git reset` would treat as a safe landing point.

A checkpoint that resets to a broken state defeats the entire purpose: rollback points must be safe to land on.

## Throwaway commit-message convention

Checkpoints are scaffolding, so mark them as disposable. Prefix every checkpoint with `checkpoint:` and name the increment, so they are trivial to spot and squash:

```
checkpoint: parser handles empty input (test green)
checkpoint: sub-task 3/5 — wire config loader
checkpoint: full suite green after rename batch
```

The prefix is the signal to future-you (and to the squash step) that this message is not meant to survive into history.

## Squashing before the real PR

Checkpoints are private scratch history; the branch that reaches review must read as intentional commits. Before handing off to the `finishing-a-development-branch` skill:

1. Confirm the final state is green one last time (the same never-checkpoint-red discipline applies to the final commit).
2. Interactive-rebase or soft-reset the run of `checkpoint:` commits into one or a few meaningful commits with real messages.
3. Verify no `checkpoint:` prefix remains in the branch's log before opening the PR.

Squash, then integrate. This skill ends where `finishing-a-development-branch` begins.

## Provenance

- **Idea:** Cherny's agentic-coding guidance is to commit frequently — treat commits as cheap checkpoints you can roll back to so that when the agent takes a wrong turn you `git reset`/`git checkout` to the last good state instead of unwinding edits by hand, and to keep changes small and reviewable rather than letting one giant diff accumulate.
- **Where stated:** "Claude Code: Best practices for agentic coding", Anthropic engineering blog, April 2025 (verified via web search, June 2026).
- **How this tool operationalizes it:** It turns "commit frequently" into a mid-work discipline with a concrete trigger (what counts as a checkpoint-worthy verified increment), a reversibility-matched cadence ladder, a `checkpoint:` message convention that marks the commits as disposable, a hard never-checkpoint-red rule so every rollback point is safe to land on, and an explicit squash-before-PR handoff to the `finishing-a-development-branch` skill.
