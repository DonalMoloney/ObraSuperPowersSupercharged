---
name: skill-scar-tissue
description: Use immediately after a verification failure or user correction — performs a post-incident graft, appending a dated quarantined rule to the skill that should have prevented the failure.
tier: v3
status: experimental
---

# skill-scar-tissue

Checklists that remember how they got hurt. After any session event where the
user corrects Claude or a verification step fails, run a post-incident graft:

1. **Attribute:** identify which skill *should* have prevented this failure.
   If no skill plausibly owns it, stop — do not graft (see risks).
2. **Graft:** append a dated, quarantined `## Scar` block to that skill — one
   line of rule derived from the specific failure, plus the date and a
   one-line incident reference. Scars live at the bottom of the skill,
   clearly marked as probationary.
3. **Promote or prune:** a scar that fires again (same failure pattern caught
   or repeated) gets promoted into the skill body proper, written in the
   skill's own voice. A scar that never fires again decays and is pruned
   after N sessions (suggest N=10, recorded in the scar line itself).

This triggers on failure and correction events, never on a schedule. The skill
evolves only when reality pushes back.

## Why this might be crazy enough to work

It mirrors how human checklists actually evolve — aviation checklists are
literally accident scar tissue — and quarantining new rules in a probation zone
solves the classic "self-edits slowly degrade the skill" problem: nothing enters
the skill body without recurring evidence.

## Known risks / absurdities

Blame attribution is the hard part — Claude may graft scars onto the wrong
skill, slowly turning every skill into a junk drawer of irrelevant warnings.
The "no plausible owner → no graft" rule is the only brake; whether it holds is
exactly what this experiment tests.
