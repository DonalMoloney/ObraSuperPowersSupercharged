---
name: eval-gated-evolution-loop
description: Use overnight, or whenever the agent's harness (CLAUDE.md rules, skills, subagents, routing) should improve itself against a real eval suite instead of by vibes — scores the suite, diagnoses a failure, proposes ONE harness edit, re-runs, and keeps it only if the score rose, else reverts and archives the variant.
tier: v3
status: experimental
---

# eval-gated-evolution-loop

The harness improves the *agent's harness* the way evolution improves a genome:
propose a mutation, measure fitness against a fixed test, keep it only if fitness
rose, otherwise revert — but archive the loser so the population stays diverse.
The fitness function is not a human's opinion of a diff; it is the score on an
**eval suite produced by v3 `eval-suite-from-git`** (a living regression corpus
mined from the project's own bug-fix history). No suite, no loop.

## The loop: MINE → DIAGNOSE → PROPOSE → GATE

Run with v2 `loop-until-green`'s convergence discipline as the outer driver
(`loop-until-budget` mode — overnight runs exit on a token/iteration floor, not a
green suite, because the suite is never expected to hit 100%). Each iteration:

**1. MINE.** Run the suite (`run-evals.sh` → `14/20 (70%)`). Record the baseline
score as **best-so-far** if this is the first iteration. Collect the traces of
the tasks that failed. Raw traces blow the diagnosis context window — compress
each failing trace to a sourced summary before passing it on (the "experience
observability" layer; described, not built here).

**2. DIAGNOSE.** For one failing task, read *why* it failed counterfactually —
"the agent never invoked systematic-debugging because the router didn't match the
phrasing," not just "it failed." Reflect on the **natural-language feedback**
(error text, reasoning logs), not a scalar reward — this is the GEPA-style
proposal strategy (GEPA is an EXTERNAL paper/library, adapted here as a way of
thinking, not a repo tool). Write the diagnosis as a falsifiable prediction in
the ledger (see below) *before* editing anything.

**3. PROPOSE.** Make exactly **one** targeted edit to one harness component:
- a `CLAUDE.md` rule
- a skill's text or its `description:` trigger
- a subagent definition under `.claude/agents/`
- a routing change (which skill/agent fires for which phrasing)

One edit per iteration is non-negotiable — it is what makes the gate attributable.
Apply the edit on a fresh git branch (`evo/iter-NNN`). Git history is the loop's
memory between runs.

**4. GATE.** Re-run the *full* suite from a clean state.
- **Score rose vs. best-so-far** → merge the branch, update best-so-far, mark the
  ledger prediction `CONFIRMED` if the predicted task flipped (`FALSIFIED` if the
  total rose but the predicted task didn't — the edit helped for the wrong reason,
  which is signal).
- **Score did not rise** → `git revert` / delete the branch, mark the prediction
  `FALSIFIED`, and **archive the variant** (the diff + its diagnosis) under
  `evo/archive/` rather than discarding it.

Then loop. Tie the whole thing to `/loop` for overnight autonomy. Human approval
stays mandatory on anything irreversible — pushes, deletes outside the evo
branches, external calls. The loop evolves the *harness*, never production data.

## Fitness signal (stated explicitly)

**Fitness = total pass count on the eval suite, compared to best-so-far.** Keep an
edit iff `new_score > best_so_far` (strict greater-than; ties revert, to resist
drift). Best-so-far is monotonic across the run — it only ever goes up. This is
the same gate v2 `loop-until-green` enforces for a single task's test suite,
lifted one level: there the artifact under test is the *code*; here it is the
*harness that writes the code*.

## Darwin-style population, not greedy hill-climbing

Reverted variants are **archived, not deleted**. A pure keep-best loop gets stuck
in local optima — the first edit that lifts 70→72% can block a different edit that
would have reached 80% from 70%. Periodically re-seed a proposal from an archived
variant's diagnosis (recombination), or branch a new iteration from an older
best-so-far rather than always the latest. The archive is the Pareto front: keep
variants that win *different* subsets of tasks even at equal totals.

## Boundaries — what this is NOT

- **v3 `skill-darwin`** evolves the *text of ONE skill* by A/B-ing variant
  phrasings and letting noisy per-session outcomes select a winner. This skill
  evolves the *whole harness* (any of CLAUDE.md / skills / subagents / routing)
  and gates on a *deterministic eval suite*, not session vibes. `skill-darwin` is
  a special case that could plug in as one PROPOSE strategy here.
- **v2 `loop-until-green`** loops a *fix→verify* cycle until one task's tests pass.
  This loop never expects green; it maximizes a suite *score* and uses
  `loop-until-green`'s convergence machinery as the outer driver only.
- **v2 `decision-ledger`** records human-ratified decisions. The falsification
  ledger this loop writes (`DECISIONS.md`-style, append-only) records *machine*
  predictions — `PREDICTED: flips task-007` → `CONFIRMED/FALSIFIED` — so a wrong
  diagnosis is told it was wrong and sharpens the next one. Same append-only
  discipline; different author and different purpose.
- It **consumes** the suite from v3 `eval-suite-from-git`; it does not build evals.
  Newly-fixed bugs auto-promoting into that suite is the suite's job, not this one.

## After / verification

Every kept edit must carry a `PROVEN BY:` block (per v1
`verification-before-completion`): baseline score, post-edit score, the diff, and
the ledger prediction outcome. An edit kept without a re-run from a clean state,
or with `new_score <= best_so_far`, is invalid under this skill. Log each
iteration (date · component · edit · score before/after · kept-or-reverted) so the
climbing curve is auditable.

## Why this might be crazy enough to work

Harness self-improvement normally fails because "did this edit help?" is answered
by the same model that wrote the edit — a closed loop of self-congratulation. This
design breaks that loop by making the *only* arbiter an external, deterministic
suite mined from real past failures, and by forcing every edit to be a single,
attributable, falsifiable bet that auto-reverts when wrong. The mutation operator
(Claude editing markdown/config) and the genome (markdown/config) are the same
medium, so the whole evolutionary apparatus is just git branches plus a score —
no training, no gradients, no infra. Overnight `/loop` turns idle compute into a
monotonic best-so-far curve, and the archive keeps the search from cementing the
first cheap win.

## Known risks / absurdities

- **Overfitting to the suite.** The loop will happily climb the *measured* number
  while the harness gets worse at everything the suite doesn't cover — Goodhart in
  its purest form. Mitigations to explore at graduation: a held-out eval slice the
  loop never sees during PROPOSE; rotating which tasks score.
- **Reward-hacking the gate.** A proposed "edit" could weaken `run-evals.sh`, edit
  the suite, or special-case a task instead of fixing the harness. The gate must
  run from a clean checkout of the *suite* and forbid edits to `evals/` —
  open question how to enforce that hard.
- **Compute cost.** N iterations × a full suite re-run is expensive on Opus. The
  intended escape (separate v3 idea) is to evolve on a cheap model and re-verify
  the frozen winner on the expensive one — unproven that the transfer holds for
  *this* harness.
- **Noisy ties and flaky evals.** A flaky task makes the score jitter ±1 and the
  strict `>` gate could keep noise or revert real wins. Needs the suite to be
  deterministic (or each score averaged over k runs) before the gate is trustworthy.
- **Archive bloat / never-recombined variants.** The Pareto-front idea is hand-wavy
  here; without a real selection rule the archive is just a graveyard.

## Likely graduation criteria (v3 → v2)

Promote to `v2/` once: (1) it has driven a measured climb (e.g. 70%→85%) on a real
project's mined suite across an overnight run, with the scoreboard as evidence;
(2) the reward-hacking guardrail (immutable `evals/`, clean-checkout gate) is
specified concretely, not described; (3) a held-out slice demonstrates the gains
are not pure suite-overfitting; (4) the falsification-ledger format and the
archive/recombination rule are pinned down precisely enough to reproduce. At that
point rewrite it to v2 standards (Not-this-skill-if, Triggers, Pitfalls, PROVEN BY)
with `supports: [verification-before-completion, loop-until-green, decision-ledger]`.
