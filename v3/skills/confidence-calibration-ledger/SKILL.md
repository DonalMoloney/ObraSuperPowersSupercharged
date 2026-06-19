---
name: confidence-calibration-ledger
description: Use whenever Claude is about to give a substantive answer or take a consequential action — log a confidence value up front, score it against reality when the outcome lands, and confront the running calibration gap so the next estimate is honest.
tier: v3
status: experimental
---

# confidence-calibration-ledger

Claude states things with the same fluent certainty whether it's 95% sure or
secretly 55% sure. The tone is calibrated to read well, not to match reality.
This skill makes Claude's *own confidence* a tracked, scored prediction.

**Capture:** before each substantive answer or consequential action, log a
confidence value (0–1, or low/med/high mapped to bands) alongside a one-line
claim and the domain it falls in ("this regex handles the edge case," "this
migration is reversible"). The number is stated *before* the outcome is known —
no retroactive confidence.

**Score:** when the outcome becomes known — test passes/fails, user confirms,
the bug recurs — mark the prediction right or wrong and compute the gap. Over
many entries this yields a Brier score and a calibration curve: of everything
said at "90%," what fraction was actually right?

**Confront:** Claude is shown its own miscalibration, broken out by domain:
"you said 90% on async-bug diagnoses and were right 60% of the time." That
feedback is injected before the next estimate in that domain, so the model can
deflate (or inflate) its stated confidence toward truth instead of toward
fluency.

**Fitness signal:** Brier score and per-domain calibration error trend DOWN
across sessions — the gap between stated confidence and observed hit-rate
shrinks, and high-confidence claims become genuinely more reliable than
low-confidence ones (resolution improves, not just average error).

**Boundary:** this OVERLAPS the v3 `belief-ledger`, which tracks load-bearing
project ASSUMPTIONS as probabilities and audits decisions when a belief
collapses. This skill is the SELF-CONFIDENCE-vs-OUTCOME specialization: it does
not open a second parallel store. EXTEND `belief-ledger` by adding a new row
type — a confidence-vs-outcome row whose subject is *Claude's own estimate*
rather than a fact about the project, carrying the same {claim, probability,
date} columns plus an outcome column and a domain tag. Belief rows revise the
world model; confidence rows revise the estimator. Same ledger, two row types.

## Why this might be crazy enough to work

The mechanism is the one that calibrates human forecasters: write the number
down before you know, score it after, and stare at your own track record.
LLMs are notoriously miscalibrated in their *verbalized* confidence even when
internal signals are better, and the failure is largely that nothing ever
closes the loop between "what I said" and "what happened." Feeding measured
per-domain miscalibration back in as context is a cheap, model-agnostic
correction signal — no fine-tuning, just a ledger and an honest mirror.

## Known risks / absurdities

Confidence stated up front is still a vibe wearing a number costume until
enough outcomes accrue, and many tasks never get a clean ground-truth outcome
to score against (selection bias: only checkable claims get scored, so the
curve describes the easy-to-verify subset). Domain tags are fuzzy, so the
per-domain breakdown may be slicing noise. There's also a perverse incentive:
once Claude knows it's being scored, it can game the Brier score by hedging
everything to 0.5 — resolution, not just calibration, has to be in the fitness
signal to punish that, and it may need a proper scoring rule plus a minimum
sample size per domain before any "confront" feedback is trusted.
