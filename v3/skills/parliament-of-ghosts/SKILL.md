---
name: parliament-of-ghosts
description: Use when a decision is flagged irreversible or expensive — convenes five persistent persona-agents who debate, vote with track-record-weighted ballots, and file dissents that get re-read on failure.
tier: v3
status: experimental
---

# parliament-of-ghosts

For any major architectural decision, convene a fixed parliament of five
persistent persona-agents:

- **The Maintainer-in-Five-Years** — argues from future maintenance cost.
- **The Security Paranoiac** — argues from attack surface.
- **The Intern Who Inherits This** — argues from learnability.
- **The User at 3 AM** — argues from failure-mode experience.
- **The Accountant** — argues from cost and scope.

They debate, form coalitions, and vote. Crucially, each persona keeps a
cross-session memory file of its past votes and *whether reality vindicated
them* — a persona whose warnings keep coming true gains voting weight; one
whose doom never arrives loses it. The parliament is a slow ensemble learner
tuned to this specific project's failure modes.

Outvoted personas file written dissents. When a decision later causes a
failure, the dissents on that decision are mandatorily re-read — the ghosts
get to say "I told you so," and their weights update accordingly.

## Why this might be crazy enough to work

Weighted voting with track-record feedback turns a gimmicky persona debate
into a slow ensemble learner — the personas that predict this project's actual
failure modes literally accumulate power.

## Known risks / absurdities

Five personas sampled from one model may be a parliament with one voter wearing
five hats — correlated errors defeat ensembles. The dissent files could also
balloon into a haunted house of grudges nobody reads. Vindication-checking is
manual and honest only if the human plays referee.
