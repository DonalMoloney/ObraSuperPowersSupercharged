---
name: counterfactual-replay
description: Use after a task scores on the eval suite, when you suspect parts of the harness are dead weight — re-runs the completed task with exactly one harness variable flipped (a skill removed, autonomy lowered, a CLAUDE.md rule disabled) and reads each component's causal contribution off the score delta.
tier: v3
status: experimental
---

# counterfactual-replay

A harness accretes components forever and removes none, because nobody can prove
which ones earn their tokens. This skill answers "what does this piece actually
*do* to the score?" by ablation — the oldest causal trick there is: change one
thing, hold everything else fixed, measure the difference.

**Ablate:** take a task that has *already completed and scored* against the eval
suite. Re-run that same task with exactly **one** harness variable knocked out —
a skill made unavailable, the autonomy slider lowered a notch, a single
`CLAUDE.md` rule commented out, one subagent removed from routing. Everything
else is frozen, same as before. One flip per replay is non-negotiable; it is the
only thing that makes the delta attributable to that component.

**Measure:** the component's causal contribution is `score_baseline -
score_ablated`. A large positive delta means the component is load-bearing — its
removal hurt. A delta near zero means dead weight: the harness scored just as
well without it, so it is paying rent in tokens and attention for nothing. A
*negative* delta is the loud finding — the component was actively making the
agent worse, and removing it helped.

**Sweep:** ablate components one at a time across a representative slice of
scored tasks, and assemble a contribution table (component · mean score delta ·
how many tasks moved). This is a leave-one-out importance map of the harness:
which parts carry weight, which are inert, which are net-negative.

**Boundary:** v3 `eval-gated-evolution-loop` tests *proposed* edits — it asks
"would adding/changing this help?" and gates a forward mutation. This skill runs
the inverse experiment on what *already exists*: it ablates current components to
find dead weight, producing the contribution table that v3 `skill-cannibal`
consumes to decide what to eat (a measured causal delta is a far better prune
signal than `skill-cannibal`'s invocation-frequency proxy, which it explicitly
warns is weak). It is also not v3 `ghost-run`: ghost-run *predicts* an execution
without running it as a divergence tripwire; this is a real, controlled A/B
re-run scored against the eval suite. State these distinctions; don't duplicate
their machinery.

**Fitness signal:** the measured per-component score delta on the eval suite
(`score_baseline - score_ablated`), aggregated as a leave-one-out contribution
table. That signed delta — not anyone's opinion of whether a skill "feels"
useful — is the only verdict on whether a component earns its place.

## Why this might be crazy enough to work

Ablation is how every other field establishes causation, and a markdown/config
harness is uniquely cheap to ablate: knocking out a component is one comment-out
on one git branch, and the experiment is a re-run against a deterministic suite —
no retraining, no instrumentation, just a score before and after. It inverts the
usual self-improvement bias: instead of the model arguing that its additions
help (a closed loop of self-congratulation), the suite reports what *breaks when
something is taken away*, and "nothing broke" is the most damning evidence a
component can produce. It turns harness pruning from an aesthetic argument into a
measured subtraction.

## Known risks / absurdities

- **Interaction effects.** Leave-one-out misses synergy: two skills might each
  score zero alone yet matter together, or a skill might look inert only because
  a second skill silently covers for it. One-at-a-time ablation cannot see this;
  pairwise or grouped ablation explodes combinatorially.
- **Coverage blindness.** A component can contribute zero on the *measured* slice
  while being the one thing that saves a rare task the suite doesn't contain —
  the fire-extinguisher problem `skill-cannibal` already flags. A near-zero delta
  is "no measured contribution," never "safe to delete."
- **Noisy / flaky scores.** If the suite jitters ±1, small deltas are
  indistinguishable from noise; deltas need averaging over k replays before any
  prune decision rests on them, and that multiplies an already expensive
  re-run-per-component cost.
- **Replay non-determinism.** "Same task, one flip" assumes the rest of the run
  is reproducible; tool order, timestamps, and model sampling can drift, so the
  delta may reflect run-to-run variance rather than the ablated component unless
  the harness is pinned hard.

## Likely graduation criteria (v3 -> v2)

Promote to `v2/` once: (1) it has produced a real contribution table on a live
project's mined suite that correctly flagged at least one component later
confirmed as dead weight; (2) the delta is averaged over k replays with a stated
significance threshold so noise can't masquerade as contribution; (3) the
replay-determinism story is pinned (what is frozen, what isn't) precisely enough
to reproduce; (4) the handoff format into `skill-cannibal` is specified, not
described. Then rewrite to v2 standards (Not-this-skill-if, Triggers, Pitfalls,
PROVEN BY) with `supports: [verification-before-completion]` and
`chains-to: [skill-cannibal]`.
