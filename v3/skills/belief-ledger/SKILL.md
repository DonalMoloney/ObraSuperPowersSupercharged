---
name: belief-ledger
description: Use whenever an assumption is stated during debugging or planning, and at session end — tracks the project's load-bearing beliefs as explicit probabilities and audits decisions when a belief collapses.
tier: v3
status: experimental
---

# belief-ledger

Decisions get recorded; the *evidence under them* silently rots. This skill
makes belief revision a first-class event.

**Capture:** whenever Claude states a load-bearing assumption during debugging
or planning — "the flaky test is timing-related," "users never hit the legacy
path" — record it in a ledger (described, not built) as a probabilistic
statement: the claim, a probability, the date, and what currently rests on it.

**Update:** every session ends with one question: did anything observed today
move any belief? Adjust probabilities with a one-line justification. "Huh,
weird" moments are exactly the trigger — weirdness is evidence.

**Collapse audit:** when a belief crosses below 50%, a mandatory audit fires:
list every decision that was built on this assumption — what is now standing
on sand? The audit output is a punch list, not automatic rework.

**Boundary:** v2 `decision-ledger` records decisions made and why. This skill
records the *evidence and assumptions underneath* decisions, with explicit
uncertainty. A decision cites beliefs; a belief collapse re-opens decisions.

## Why this might be crazy enough to work

Making belief revision a first-class event converts "huh, weird" moments into
structural updates — which is the actual mechanism of expertise, normally
locked inside a senior engineer's head.

## Known risks / absurdities

The probabilities are vibes wearing a number costume, and the collapse audit
could trigger paralyzing re-litigation over a belief that drifted to 49%.
Hysteresis (audit at 40%, not 50%) and a cap on audit frequency are probably
needed before this is usable.
