---
name: cross-model-harness-transfer
description: Use when an evolution loop's per-iteration model cost is the thing blocking overnight runs — experimental cost strategy that evolves the harness on a cheap, fast model (Haiku) under test, freezes the winning harness, and deploys it driving a stronger model (Opus) for real work, gated by re-running a held-out eval slice on the deploy model before trusting the transfer.
tier: v3
status: experimental
---

# cross-model-harness-transfer

Evolution loops are expensive for one boring reason: every proposed harness edit
costs a full eval-suite re-run, and a suite re-run is N rollouts of a real model
doing real tasks. Run that overnight on your most capable model and the bill, not
the idea, is what kills the project. So most people never run the loop long enough
to climb a curve.

This skill is a wager that you don't have to. The loop's job is to optimize the
*harness* — `CLAUDE.md` rules, skills, hooks, sub-agent configs, routing — not the
model's weights. If a harness edit is genuinely good ("always write the failing
test first," "route schema questions to the db sub-agent"), it is plausibly good
*independent of which model reads it*. So: do all the expensive iteration on the
cheapest model that still discriminates good edits from bad ones, freeze the
winner, then point that frozen harness at the strong model for production.

**Evolve cheap. Deploy expensive. Re-verify before you trust the swap.**

## The mechanism

This is a strategy layered on top of v3 `eval-gated-evolution-loop` (the
mine→diagnose→propose→gate engine) and v3 `eval-suite-from-git` (the suite it
scores against). It changes only *which model* runs in each phase.

1. **Evolve under Haiku.** Run the entire evolution loop with the cheap, fast
   model selected as the model under test. Every iteration — score the suite,
   diagnose a failure, propose one harness edit, re-run, keep-or-revert — happens
   at Haiku rollout cost. This is where the overnight `while`-loop lives, because
   this is where the iteration count is high and the per-rollout price has to be
   low. The output is a *frozen harness*: a specific commit of the 8 git-tracked
   components (system prompt, skills, hooks, sub-agents, routing, memory, etc.)
   that scored best on the suite under Haiku.

2. **Freeze the winner.** Tag/commit the winning harness exactly as the loop left
   it. Nothing about the harness changes in the next phase — only the model
   driving it does. (Real CC primitives: model selection is real, sub-agents are
   real. This skill invents no flags; it just runs the same files against a
   different chosen model.)

3. **Hold out a slice.** *Before* evolution begins, partition the mined suite into
   a training slice (what the Haiku loop is allowed to score and optimize against)
   and a **held-out slice the loop never sees**. The loop must not gate on the
   held-out tasks, or you've leaked them and the guard below is worthless.

4. **Re-verify on the deploy model.** Run the held-out slice — and only now — with
   the strong model (Opus) driving the frozen harness. This is the gate. Compare
   the held-out score under Opus against a baseline: the *bare* deploy model with
   no evolved harness, on the same held-out slice. If the evolved harness lifts the
   held-out Opus score over bare Opus, transfer is confirmed and the frozen harness
   ships. If it doesn't, transfer **failed for this harness** — do not deploy it;
   fall back to bare Opus or to the last harness that did transfer.

5. **Deploy expensive.** Only a harness that passed step 4 drives Opus for real
   work. The cheap loop keeps running overnight to propose the *next* candidate;
   each candidate must clear the held-out re-verification before it is promoted to
   production.

## What's verifiable here (the fitness signal, named explicitly)

There are two distinct signals, and conflating them is the trap:

- **Optimization signal (Haiku, training slice):** the eval score the loop climbs.
  This selects edits but proves nothing about the deploy model.
- **Transfer signal (Opus, held-out slice):** the *actual* fitness of this skill.
  A frozen harness is only trusted if re-running the held-out eval slice on the
  deploy model confirms it beats bare deploy-model baseline on tasks it was never
  tuned against. That held-out re-run on the production model is the completion
  evidence in the sense of v1 `verification-before-completion`: the cheap loop's
  rising number is a *claim* of improvement; the held-out Opus score is the
  *verification*, and you may not deploy on the claim alone.

## Boundary — what this is NOT

- **Not the evolution loop itself.** v3 `eval-gated-evolution-loop` is the engine;
  this is a cost/transfer policy bolted onto it (which model runs each phase). All
  the diagnose/propose/gate machinery is borrowed, unchanged.
- **Not the suite.** v3 `eval-suite-from-git` mines the tasks; this skill only
  decides how to *partition* them (train vs. held-out) and which model scores each.
- **Not a quality downgrade.** Haiku is used only as a discriminating *probe* for
  edit quality during search, never as the thing that does production work. The
  strong model still does all real work — it just inherits a harness paid for at
  cheap-model prices.
- **Not v1 `verification-before-completion` restated.** It *invokes* that rule
  (held-out re-run = evidence before the deploy claim) but adds the cross-model
  twist: the verification must run on a *different model* than the one that
  produced the claim.

## Why this might be crazy enough to work

The expensive part of an evolution loop is the search, and search quality depends
on having a *discriminator* that ranks edits correctly — not on that discriminator
being the smartest model alive. A cheap model that can still tell "test-first beats
test-after" is a perfectly good ranking oracle for harness text, and harness text
is largely model-portable because it encodes process and routing, not capability
that lives in weights. If both of those hold, you get the strong model's harness
improvements at the cheap model's iteration price — a 10–30x cost cut on the one
phase that otherwise makes overnight evolution unaffordable. The honest catch is
that "both hold" is an **empirical** claim, not a guarantee: transfer can and will
fail when an edit exploits a Haiku-specific quirk (papering over a weakness Opus
doesn't have), when Haiku is too weak to discriminate the edits that matter to
Opus at all, or when the optimum harness is genuinely model-shaped. That is
exactly why the held-out re-verification on the deploy model is non-negotiable —
it is the one cheap experiment that converts "transfer is plausible" into "transfer
happened, for this harness, measured." The strategy is not "trust transfer"; it's
"bet on transfer cheaply, then check before you spend."

## Known risks / absurdities

- **Transfer is not guaranteed and is the whole point of failure.** The held-out
  gate catches *whole-harness* transfer failure, but a harness can be a net win on
  Opus while still containing individual edits that hurt Opus and are masked by
  other edits that help. Per-edit transfer attribution is unsolved here.
- **Cheap-model overfitting.** The loop will happily evolve edits that exploit
  Haiku's specific failure modes (verbose hand-holding it needs and Opus doesn't),
  inflating the training score with edits that are dead weight or harmful on Opus.
- **Discrimination floor.** If Haiku is too weak, it scores good and bad edits the
  same way (everything fails, or everything passes), and the loop optimizes noise.
  There's likely a minimum capability the probe model needs *relative to suite
  difficulty* — too-hard a suite makes Haiku a coin flip. Open question: how to
  detect a non-discriminating probe before wasting a night on it.
- **Held-out slice exhaustion.** A small mined suite can't spare many tasks for a
  never-trained-on hold-out, and re-using held-out tasks across many candidate
  promotions slowly leaks them. The guard decays the more you lean on it.
- **Baseline ambiguity.** "Beats bare Opus" needs a fixed, fair bare-Opus baseline
  on the held-out slice; if that baseline is itself noisy (non-deterministic
  rollouts), small transfer lifts are unprovable.
- **Two-model bookkeeping.** Every score now carries a model tag; mixing a
  Haiku-scored number with an Opus-scored number in the scoreboard silently
  corrupts the whole audit trail.

## Likely graduation criteria (path to v2)

Promote to v2 when: (1) the held-out re-verification protocol is concrete and
enforced — a documented train/held-out split with leak protection, a fixed
bare-deploy-model baseline, and a deploy gate that refuses promotion on transfer
failure; (2) cross-model transfer is *demonstrated*, not assumed — at least two
frozen harnesses show a positive, repeatable held-out lift on the deploy model
across independent runs, and at least one documented transfer *failure* shows the
gate correctly blocked a deploy; (3) the realized cost ratio (cheap-loop spend vs.
estimated all-Opus spend for the same iteration count) is measured and reported, so
the savings claim is evidence, not hope; and (4) a probe-discrimination check
exists that flags a too-weak cheap model before a wasted run. At that point it
stops being a wager and becomes a documented cost policy — rewrite to v2 standards
(concrete commands, model-tag discipline, `PROVEN BY:` transfer evidence) and move
it, naming the v3 loop and v1 verification skills it depends on.
