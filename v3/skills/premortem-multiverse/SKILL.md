---
name: premortem-multiverse
description: Use when a change touches data, auth, money, or anything flagged irreversible — parallel obituary agents each write the future incident report from a different doom genre, and convergent failure chains become mandatory tests.
tier: v3
status: experimental
---

# premortem-multiverse

Forward "what could go wrong?" brainstorming reliably misses risks that
backwards reasoning from a stipulated disaster finds — the premortem effect.
This skill industrializes it:

1. **Fork doom worlds:** spawn 3–4 parallel obituary agents, each assigned a
   different doom genre — data-loss world, performance-collapse world,
   security-breach world, angry-user world.
2. **Write the incident report:** each agent is told: *it is six months later
   and this change destroyed the project — write the incident report
   explaining exactly how.* Reports MUST cite real files and real code paths
   in the actual codebase; uncited doom is discarded.
3. **Mine for convergence:** failure chains that two or more independent
   reports cite through the same code are the signal. Each convergent chain
   becomes a mandatory test or a plan amendment before the change proceeds.

## Why this might be crazy enough to work

Backwards reasoning from a stipulated disaster reliably extracts risks that
forward brainstorming misses, and forcing citations to real files keeps the
fiction anchored to the actual codebase instead of generic catastrophe.

## Known risks / absurdities

Four creative-writing exercises may converge on generic doom ("the migration
had no rollback") and add ceremony to every scary-sounding change. The
convergence filter is the only defense — if the reports agree on something
boring, the answer is a boring test, not a longer ritual.
