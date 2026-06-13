---
name: eval-suite-from-git
description: Use when a self-improvement or evolution loop needs an eval suite but nobody has written one yet (the cold-start that stalls every such project) — experimental skill that MINES regression tasks from your own git history instead of hand-authoring them, reconstructing each pre-fix state as a task whose check is the fix's own test.
tier: v3
status: experimental
---

# eval-suite-from-git

The governing rule of this whole tier: self-improvement only works where outcomes
are **verifiable**. An evolution loop is just expensive vibes until it can ask
"did that edit make the agent better?" and get a number back. The eval suite *is*
that number — and writing one by hand is the step that quietly kills these
projects. Twenty good tasks is a week of unfun work nobody schedules.

So don't write them. **Mine them.** Your repo already contains hundreds of
verified failures with verified fixes — they're called bug-fix commits. Each one
is a task with a fitness signal pre-attached: a test that was red before the fix
and green after.

## The mechanism

Walk `.git` with ordinary `git log` / `git show` (real tools — no special API):

1. **Find the corpus.** Filter for bug-fix and revert commits — `git log` grepping
   `^fix`, `revert`, `regression`, closed-issue references, or any commit that
   *adds or modifies a test file alongside a source change*. That last heuristic is
   the strongest: a commit that touches both `test_*` and the code it tests is
   almost always "bug found, test written, bug fixed."
2. **Split each fix commit into before/after.** The fix's diff has two halves: the
   source change (the answer) and the test change (the grader). Reconstruct the
   **pre-fix tree** (`git checkout <fix>~1`) but cherry-pick *only the test half* of
   the fix on top of it. Now you have a working tree where the new test exists and
   **fails** — a real, reproduced bug.
3. **Emit a task.** Write `evals/task-NNN/prompt.md` (the reconstructed symptom:
   the issue text, the failing test name, the error) and `evals/task-NNN/check.sh`
   (run exactly that test; exit 0 iff it passes). The expected fix is the source
   half you held back — keep it as a reference solution, not shown to the agent.
4. **Score.** `run-evals.sh` resets each task to its reproduced-bug state, hands the
   agent `prompt.md`, runs `check.sh`, and prints `14/20 (70%)`. That ratio is the
   fitness function the rest of the loop optimizes.

## Self-maintaining

This is the part that makes it more than a one-time script. Every time the agent
fixes a *new* bug in real work, that fix is itself a bug-fix commit with a test —
so the same miner auto-promotes it into the suite next run (adapt the
suite-promotion idea from neosigmaai/auto-harness, but sourced from *your* real
failures, not a benchmark). The corpus grows on its own. The agent's regression
suite becomes a living memory of every mistake it has already learned not to make.

## What's verifiable here (the fitness signal, named explicitly)

Every mined task ships a binary, machine-checked signal: the fix's own test,
red→green, taken straight from history. There is no judge model, no rubric, no
taste. A task only enters the suite if `check.sh` provably fails on the pre-fix
tree and passes on the post-fix tree — that round-trip is the admission gate. This
is the one eval-authoring method where the grader is not written by anyone; it's
*recovered*.

## Boundary — what this is NOT

- **Not v2 `skill-test-harness`.** That spawns personas to behaviorally test ONE
  skill against its contract. This mines a regression EVAL SUITE for the whole
  agent/harness from real git history — different unit (the agent, not a skill),
  different source (history, not authored personas).
- **Not v2 `loop-until-green`.** That is the convergence *loop* for one task's test
  suite. This is the *corpus* the loop runs against. They compose: a downstream
  evolution loop scores `run-evals.sh`, proposes one harness edit, and could use
  `loop-until-green` per task to drive each fix.
- It builds on, not replaces, v1 `test-driven-development` (every mined task is a
  pre-written failing test — TDD's red phase, recovered from history) and v1
  `verification-before-completion` (the suite score is the completion evidence for
  any harness change).

## Why this might be crazy enough to work

The hardest, most-skipped input to any self-improvement loop — a labeled eval set
with a trustworthy grader — turns out to already exist, fully labeled, inside
`.git`. A bug-fix commit is *definitionally* a (broken-state, test, fix) triple
that someone already verified by merging it. We're not generating evals; we're
reading them off the historical record. That sidesteps the two things that make
synthetic evals worthless — fabricated difficulty and an untrustworthy grader —
because both the difficulty and the grader were validated by the original human
who shipped the fix.

## Known risks / absurdities

- **Mining precision.** The "touches a test + its source" heuristic will catch
  refactors, feature commits with tests, and flaky-test quarantines, not just bug
  fixes. The before/after round-trip admission gate filters a lot (no red→green, no
  task), but expect a manual triage pass on the first harvest, and squashed/rebased
  histories will hide many of the cleanest examples.
- **Reconstruction can't always isolate the test.** Some fixes interleave source
  and test in one inseparable hunk, or the test won't even import on the pre-fix
  tree (the fix added the module the test imports). Those tasks are unsalvageable
  and should be dropped, not forced.
- **Stale environments.** A 2-year-old bug's test may fail today for dependency
  reasons unrelated to the bug — a false signal. Pin/skip tasks whose pre-fix tree
  won't build at all.
- **Teaching to the test / overfitting history.** A suite made only of past bugs
  optimizes the agent for *yesterday's* mistakes; it says nothing about novel
  failure modes. It is a regression net, not a measure of true capability — do not
  confuse a rising mined-suite score with a smarter agent.
- **Reference-solution leakage.** The held-back source half must never reach the
  agent at score time; if it leaks into context, the eval is contaminated.

## Likely graduation criteria (path to v2)

Promote to v2 when: (1) the miner runs end-to-end on at least two real repos and
emits a suite where every task's `check.sh` provably fails pre-fix and passes
post-fix (the admission gate is enforced, not assumed); (2) mining precision after
the round-trip gate is high enough that triage is light, with the false-positive
categories above documented as known filters; (3) `run-evals.sh` is deterministic
and idempotent (same repo state → same `N/M` score); and (4) auto-promotion of
newly-fixed bugs is demonstrated across two consecutive harvests without dupes.
At that point it stops being speculative and becomes infrastructure — rewrite to
v2 standards (concrete commands, pitfalls table, `PROVEN BY:` evidence) and move it.
