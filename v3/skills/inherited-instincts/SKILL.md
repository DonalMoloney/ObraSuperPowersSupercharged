---
name: inherited-instincts
description: Use as a pre-task scan in any repo — surfaces firing instincts from a cross-project genome of pattern-to-emotion reflexes, presented as gut feelings rather than directives.
tier: v3
status: experimental
---

# inherited-instincts

Cross-project transfer fails when you copy rules, because context differs. But
*instincts* — terse, context-free pattern→emotion pairs — are exactly the part
of senior-engineer intuition that does transfer:

- `dread: config that works locally`
- `twitch: any function named process()`
- `comfort: a test that failed before it passed`

The genome lives in a single global instinct file (described, not built) that
travels across all repos. Before starting a task, scan the genome: any instinct
whose pattern matches the current situation *fires* and is surfaced as a gut
feeling — "something here smells like config drift" — never as a directive.

**Selection:** an instinct that fires and proves right gets strengthened
(dominant). One that fires and proves wrong in the new context gets marked
recessive — still carried, no longer surfaced, revivable if it starts being
right again. New instincts are bred from repeated episodes (a natural output
of project-hippocampus, if both exist).

## Why this might be crazy enough to work

Instincts are deliberately context-free pattern→emotion pairs, which is the
transferable core of intuition — and the dominant/recessive mechanic handles
negative transfer instead of pretending it won't happen.

## Known risks / absurdities

This is deliberately engineering prejudices into the model. A wrong dominant
instinct ("dread: ORMs") could silently bias every project's architecture for
months before enough contradicting evidence demotes it. The genome needs an
occasional human eugenics review, which is as uncomfortable as it sounds.
