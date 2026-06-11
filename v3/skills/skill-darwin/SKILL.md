---
name: skill-darwin
description: Use when a high-traffic skill feels stale, contested, or chronically half-followed — evolves the skill text itself by maintaining competing variant phrasings and letting session outcomes select the winner.
tier: v3
status: experimental
---

# skill-darwin

Natural selection for skill text. For any skill on its watch list, maintain a
small population of 2–4 variant phrasings — e.g. three different wordings of the
same debugging checklist, one terse, one narrative, one checklist-with-threats.
At session start, a hook (described, not built) rolls dice and loads exactly one
variant. The session proceeds normally.

At session end, a fitness scorer updates a per-variant ledger
(`v3/skills/skill-darwin/fitness.json`, described only) with cheap outcome
signals: did the task pass verification on the first try? How many times did the
user correct course? Did the skill get abandoned mid-session? Variants
accumulate win rates. Periodically, the weakest variant is mutated — Claude
rewrites its lowest-performing section while keeping the skill's intent — and
the cycle repeats. Strong variants breed: their best sections get spliced into
new candidates.

## Why this might be crazy enough to work

A/B testing prompt text is the one optimization loop where the artifact
(markdown) and the mutation operator (Claude rewriting markdown) are the same
medium — zero infrastructure beyond a JSON ledger and a dice-roll hook.

## Known risks / absurdities

The fitness signal is hopelessly noisy at n=5 sessions; you may evolve skills
that won the coin flips, not the arguments. Mitigation to explore at graduation
time: minimum sample sizes per variant before any selection event, and never
mutating the current champion.
