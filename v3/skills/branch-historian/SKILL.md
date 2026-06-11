---
name: branch-historian
description: Use when a project feels stuck or rotten, or when architecture stalls keep recurring — walks past decisions backwards and actually spikes the road not taken in throwaway worktrees, returning a regret report.
tier: v3
status: experimental
---

# branch-historian

A time-travel debugger for decisions. When a project feels stuck:

1. **Walk backwards:** read the decision history (v2 `decision-ledger` if
   present, otherwise commit messages and specs) and pick the 2–3 most
   contested past decisions — the ones with real alternatives rejected.
2. **Build the counterfactual:** for each, spawn an agent in a throwaway git
   worktree to *actually partially build* the road not taken, on a fixed
   budget (e.g. 30 minutes: "spike what this module looks like if we'd chosen
   SQLite"). The spike mechanics compose with v2 `spike-in-worktree` — this
   skill decides WHAT to spike and WHY; that skill handles the worktree
   discipline.
3. **File the regret report:** for each counterfactual — better / worse /
   same, with the artifact attached. The report either vindicates the past
   decision (now with evidence, not sunk-cost rationalization) or recommends
   a heresy: deliberately re-deciding it.

## Why this might be crazy enough to work

Worktrees make counterfactual histories *materially cheap* — instead of
arguing about the road not taken, you build 5% of it and look at it,
converting unfalsifiable hindsight debates into artifacts.

## Known risks / absurdities

Regret-driven development: a 30-minute spike always looks cleaner than three
months of accumulated reality, so the alternate timeline systematically wins
and the skill becomes a rewrite-everything machine. The regret report must
weight the champion's battle scars (handled edge cases, fixed bugs) or it is
structurally biased toward heresy.
