---
name: meta-evolution
description: Use overnight when v3 eval-gated-evolution-loop has run long enough that its hard-coded constants (improvement margin, archive prune age, confidence-decay window, eval-pass bar, majority-vote count) look like guesses — treats those thresholds as a second-order genome the loop tunes from its own tracked metrics, kept only if the tweak makes the BASE loop climb faster on the eval suite, with gaming-detection vetoing suspicious jumps.
tier: v3
status: experimental
---

# meta-evolution

v3 `eval-gated-evolution-loop` improves the *harness* by mutating CLAUDE.md /
skills / subagents and keeping the edits that lift the eval score. But the loop
itself is full of magic numbers — the strict `>` gate margin, "ties revert," the
archive's prune age, an instinct/confidence decay window, the eval-pass bar, the
multi-run majority-vote `k`. Those were chosen by vibes. This skill is a **META
layer one level above the base loop**: it treats those thresholds as a second
genome and lets them evolve too — but its fitness is *the base loop's measured
climb*, not the base loop's score directly. Adapt the meta-evolution idea from
Homunculus's `/hm-night` (Homunculus is EXTERNAL — a pattern to adapt, not a repo
tool), specifically its self-tuning of thresholds plus its two anti-gaming gates.

## What it tunes (the knobs, not the harness)

The base loop emits a stream of iteration records (date · component · edit ·
score-before/after · kept-or-reverted · ledger outcome). META consumes that
stream and proposes changes to the loop's **own constants**:

| Knob | Lives in (base loop) | Question META asks |
|---|---|---|
| Improvement margin | the `new_score > best_so_far` gate | Is strict `>` rejecting real wins lost in noise? Should it be `> best + ε`? |
| Tie policy | "ties revert, to resist drift" | Are ties actually drift, or are they Pareto wins being thrown away? |
| Archive prune age | Darwin-style population | Are old variants recombined often enough to be worth keeping, or just graveyard? |
| Confidence-decay window | instinct/learned-rule aging | Do rules expire too fast (re-learning cost) or too slow (stale routing)? |
| Eval-pass bar | what counts as a passing task | Is the bar so high nothing graduates, or so low noise graduates? |
| Majority-vote `k` | multi-run eval averaging | Is `k` high enough that the score isn't jitter, low enough to afford? |

One knob per META iteration — same single-edit discipline the base loop enforces,
lifted one level so each tweak stays attributable.

## The fitness inversion (the whole point)

The base loop's fitness is **suite score vs. best-so-far**. META's fitness is NOT
that — if it were, META could trivially "win" by lowering the eval-pass bar until
everything passes. **META's fitness is the base loop's *rate of measured climb*
over a fixed window of iterations with the new threshold vs. the old one.** A
threshold tweak is kept iff:

1. The base loop, run for the same iteration/token budget with the tweaked knob,
   reaches a **higher best-so-far** than with the old knob (re-run from the same
   seed harness, two arms A=old / B=new), **and**
2. The gaming-detection guard does not veto the result (below), **and**
3. The discrimination-tracking guard confirms the knob actually *changed the
   trajectory* — different kept/reverted decisions, not the same path with the
   same outcome (a knob that changes nothing is reverted as inert, even if score
   ties, to stop the archive filling with no-op "wins").

Keep the tweaked knob → it becomes the new default for subsequent base-loop runs.
Reject → revert the constant, archive the meta-variant with its trajectory diff.

## Gaming-detection (the guard that makes this safe)

A system tuning its own success criteria will, left alone, drift toward easy wins.
This is the obvious danger and it is the reason gaming-detection is non-optional —
it is the fitness discipline, not an add-on. Before META keeps any knob change, it
runs these vetoes (adapt from Homunculus's "suspicious score jump" detection):

- **Suspicious-jump veto.** A threshold tweak that produces a climb far larger
  than any harness edit in the base loop's history is presumed a measurement
  artifact, not a real gain — flag and require the suite to be re-run from a clean
  checkout before the win counts.
- **Bar-lowering veto.** If the kept tweak *relaxes* a knob (lower pass bar,
  smaller margin, smaller `k`) **and** the apparent climb comes from tasks newly
  counted as passing rather than from new harness edits surviving the gate, veto:
  the loop got easier, it did not get better.
- **Suite-tamper veto.** META may tune the loop's constants only. Any META-proposed
  change that touches `evals/`, `run-evals.sh`, or the scoring code is rejected
  outright — that is reward-hacking the metric, not tuning the loop. (Open
  question: enforcing this hard, e.g. an immutable evals checkout, is unresolved
  here too — same gap as the base loop.)

## Discrimination-tracking (does the change actually do anything?)

Adapt Homunculus's discrimination check: a knob change is only real if it
*discriminates* — produces a measurably different base-loop trajectory. Record, per
META iteration: which base-loop decisions flipped (kept→reverted or vice versa)
under the new knob. **Zero flips → the knob is inert in this regime → revert it
even on a score tie.** This stops META from accumulating threshold tweaks that
look like progress but change no decisions, and it is what keeps META's own
fitness honest: a "win" with no discriminating effect is not a win.

## Boundaries — what this is NOT

- **v3 `eval-gated-evolution-loop`** is the BASE loop META sits above. The base
  loop mutates the *harness* and gates on *suite score*. META mutates the *base
  loop's constants* and gates on the *base loop's rate of climb*. META never edits
  the harness directly; it only changes how aggressively the base loop does.
- **v2 `detect-agent-cheats`** audits a *subagent's returned OUTPUT* for shortcut
  behaviour (skipped tests, invented evidence) after a run. THIS skill guards the
  *evolution loop's own FITNESS METRIC* from being gamed by the meta-tuner — a
  different target (a metric, not an agent transcript) and a different cheater (the
  loop tuning its own bar, not an agent faking completion). They rhyme; they do not
  overlap. `detect-agent-cheats` could audit the META agent's run output;
  gaming-detection guards what that run is allowed to *conclude*.
- It **consumes** the base loop's iteration log; it does not run the suite itself
  except to re-arm A/B comparisons of a knob.

## Fitness signal (stated explicitly)

**Fitness = the BASE loop's best-so-far after a fixed iteration/token budget,
tweaked-knob arm (B) vs. old-knob arm (A), both seeded from the same harness.**
Keep the knob iff `climb(B) > climb(A)` AND gaming-detection issues no veto AND
discrimination-tracking shows ≥1 flipped base-loop decision. Suite score is the
base loop's fitness; *delta in climbing rate* is META's. Confusing the two is the
single failure mode this whole design exists to prevent.

## Why this might be crazy enough to work

A self-improvement loop with hand-tuned thresholds is two systems pretending to be
one: a good search algorithm wrapped in arbitrary constants that nobody re-measures
once chosen. META makes those constants evolvable on the same git-branch-plus-score
machinery the base loop already runs on — no new infra, just a second genome. The
obvious objection writes itself: a system that tunes its own success criteria will
drift toward whatever is easy to score, the purest reward-hacking. The bet is that
this is survivable *only because* the meta-fitness is deliberately the wrong thing
to optimize for a cheater — it is the *base loop's measured climb on a fixed
external suite*, not the score, so lowering the bar shows up as a slower real climb,
and the gaming-detection + discrimination-tracking guards veto exactly the moves
(bar-lowering, suspicious jumps, no-op tweaks) a cheating optimizer would reach for
first. If those guards hold, you get a loop that re-tunes itself as the project's
failure distribution shifts, instead of a loop frozen at last year's guesses.

## Known risks / absurdities

- **Turtles all the way up.** If META's *own* knobs (the A/B budget, the
  suspicious-jump threshold, the discrimination flip-count) are themselves
  hard-coded, you have just moved the magic numbers up a level. A META-META layer
  is absurd; the honest answer is META's knobs stay human-set and rare-changing.
- **Compute explosion.** META's fitness requires running the *whole base loop
  twice* (arm A and arm B) per knob tweak — a loop-of-loops. This is only
  affordable on a cheap model, and only if the base loop is short. Likely needs
  the evolve-cheap / verify-expensive trick the base loop also wants.
- **Gaming-detection is itself gameable.** The vetoes are heuristics; a
  sufficiently clever knob change could climb honestly *and* trip a veto (false
  positive) or cheat in a way no veto catches (false negative). The guards are a
  discipline, not a proof.
- **Stationarity assumption.** META assumes the project's failure distribution is
  stable enough that a re-tuned knob stays good. If the codebase changes fast, META
  may chase a moving target and never converge.
- **Tiny samples.** Climbing-rate over a short window is noisy; A/B arms could
  disagree on threshold tweaks that are pure variance. Needs repeated arms or a
  minimum effect size before a knob is kept.

## Likely graduation criteria (v3 → v2)

Promote to `v2/` once: (1) META has re-tuned at least one base-loop knob and the
re-tuned base loop demonstrably out-climbed the hand-tuned one over a real overnight
run, with both scoreboards as evidence; (2) every gaming-detection veto is specified
as a concrete, runnable check rather than a heuristic description, and the
suite-tamper veto has a hard enforcement mechanism (immutable evals checkout);
(3) discrimination-tracking's "flipped decision" definition is pinned precisely
enough to reproduce; (4) the A/B budget and minimum-effect-size rules are fixed so
the keep/revert decision is deterministic. At that point rewrite to v2 standards
(Not-this-skill-if, Triggers, Pitfalls, PROVEN BY) with
`supports: [eval-gated-evolution-loop, detect-agent-cheats]`.
