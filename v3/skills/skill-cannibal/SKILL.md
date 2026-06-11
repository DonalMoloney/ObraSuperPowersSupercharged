---
name: skill-cannibal
description: Use monthly, or whenever the total skill corpus exceeds a context-budget threshold — runs a metabolism pass where skills compete for a fixed token budget and underperformers get eaten.
tier: v3
status: experimental
---

# skill-cannibal

Skills compete for a scarce resource: tokens in the context window. On each
metabolism pass:

1. **Score** every skill in the repo on invocations-per-week versus token
   weight (a ledger of invocation counts is described, not built).
2. **Eat** underperformers: extract the one or two genuinely useful lines from
   a low-scoring skill, absorb them into the strongest related skill, and move
   the husk to an `archive/` directory with a note naming where its organs
   went. Nothing is deleted — archival is reversible.
3. **Fuse:** when the ledger shows two skills habitually loaded together,
   propose fusing them into a hybrid offspring with a new name; the parents
   get archived with pointers to the child.

The pass produces a written digestion report (what was eaten, what absorbed
what, proposed fusions awaiting human approval) — eating and fusing are
proposals to the human, never autonomous deletions.

## Why this might be crazy enough to work

Context windows are a real scarce resource, and scarcity is the only forcing
function that ever produces genuine consolidation instead of endless accretion.
Every skill collection grows monotonically until something is allowed to eat.

## Known risks / absurdities

It might eat a low-frequency, high-criticality skill — the fire extinguisher
you use once a year — because frequency is a terrible proxy for value. The
human-approval gate and reversible archiving are load-bearing, not optional.
