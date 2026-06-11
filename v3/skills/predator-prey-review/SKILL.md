---
name: predator-prey-review
description: Use on request as an adversarial alternative to standard code review — co-evolving predator agents hunt for bugs the prey agent did not already know about.
tier: v3
status: experimental
---

# predator-prey-review

Two co-evolving agent lineages per project:

- **Prey** agents write the code — and simultaneously write a *private*
  "weaknesses I'm hiding" note listing every shortcut, doubt, and known soft
  spot. The note is sealed from the predator.
- **Predator** agents hunt the code for bugs, and score points **only** for
  finding issues NOT on the prey's note. Re-reporting what the author already
  knew earns nothing — the predator must hunt past the obvious.

After each round, both lineages update from the kill log: the predator's
hunting playbook gains the patterns that scored, the prey's defensive
checklist gains the weaknesses that got caught. Both playbooks persist across
sessions, so the arms race compounds.

**Boundary:** v2 `red-team-spec` attacks specs pre-implementation, one-shot.
This skill is post-implementation, on code, and co-evolutionary — the
adversaries learn each other across rounds.

## Why this might be crazy enough to work

The "score only for unlisted bugs" rule breaks the lazy equilibrium where
adversarial reviewers re-report obvious issues, and the two persistent
playbooks mean the arms race compounds across sessions instead of resetting.

## Known risks / absurdities

Goodharting — predators learn to manufacture exotic non-issues, prey learn to
write deliberately bug-dense decoy code, and the ecosystem optimizes for drama
over correctness. A human judge over the kill log is probably required before
any score counts.
