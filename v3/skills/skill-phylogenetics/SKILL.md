---
name: skill-phylogenetics
description: Use when the skill library has grown by forking/copy-pasting and you suspect duplicates under different names — reconstructs the lineage of every skill and flags convergent evolution (skills that drifted to the same purpose) as merge candidates.
tier: v3
status: experimental
---

# skill-phylogenetics

Skills are not authored from scratch; they are forked. Someone copies the
nearest existing SKILL.md, renames it, and edits. Over time the library carries
hidden ancestry — and worse, two unrelated lineages quietly evolve toward the
same job. This skill reconstructs the family tree and catches that convergence.

**Lineage:** for each skill, infer its parent — the skill it was most plausibly
forked from — using shared section scaffolding, copied phrasing, identical
pitfall tables, and frontmatter relation overlap. The output is a phylogenetic
tree (described, not built): node = skill, edge = "derived from," with a
confidence on each edge. Roots are the genuine originals; deep subtrees reveal
the templates the library actually breeds from.

**Convergence:** the payoff is detecting *convergent evolution* — two skills on
DIFFERENT branches whose purpose, trigger conditions, and steps have drifted
into near-identity despite different names and no shared ancestor. These are the
redundant pairs: independent answers to the same question, accreted because
nobody noticed the other already existed. Each detected pair is scored by
purpose-overlap and emitted as a merge candidate, ranked.

**Drift:** along a single lineage, measure how far each descendant has diverged
from its parent. A skill that drifted far has earned its independence; one that
barely changed is a near-clone fork that should probably collapse back into its
parent. Drift distinguishes legitimate speciation from accidental duplication.

**Boundary:** v2 `skill-graph` maps DEPENDENCIES between skills (chains-to /
pairs-with / supports) — who calls whom. v3 `skill-cannibal` EATS underperformers
on a token budget and proposes fusions from co-load frequency. skill-phylogenetics
maps LINEAGE/ANCESTRY and finds CONVERGENCE from content similarity, not call
edges or usage counts. It is the analysis that FEEDS skill-cannibal: this skill
names *which* pairs are truly redundant; skill-cannibal decides whether the
budget justifies eating one. Produce the merge-candidate list here; hand it off
there. Do not duplicate either.

**Fitness signal:** count of redundant skill-pairs detected and merged per pass,
and library entropy (a duplication index — total content mass divided by distinct
purposes) trending down release over release. A pass that surfaces zero
convergent pairs in a still-growing library is failing to see real duplication.

## Why this might be crazy enough to work

Biology already solved this: convergent evolution is detectable precisely because
shared function without shared ancestry leaves a different signature than
inheritance does. A skill library forked by copy-paste carries exactly that
phylogenetic signal in its prose — copied scaffolding is heredity, independent
near-identical purpose is convergence — and the same tree-reconstruction logic
that distinguishes a wing from a wing should distinguish a real fork from an
accidental reinvention.

## Known risks / absurdities

Inferred ancestry is a just-so story until a real git-history or authorship trail
confirms it — content similarity can mislabel a sibling as a parent. And
"convergent" is a slippery threshold: set it loose and it will demand merging two
skills that share a template but genuinely differ in scope, collapsing useful
specialization into one bloated skill. The merge candidates must stay
recommendations to skill-cannibal and a human, never automatic fusions, and the
convergence score needs calibration against at least a few known-good pairs
before anyone trusts it.
