---
name: parallel-judge-panel
description: Use experimentally when the solution space is wide and one-attempt iteration keeps re-converging on your first idea — spawns N solutions from deliberately different angles, scores them with a panel of independent blind judges, surfaces disagreement, then picks or synthesizes the winner.
tier: v3
status: experimental
---

# parallel-judge-panel

Iterating on a single first attempt anchors you to that attempt's framing.
This skill explores the space in *parallel* instead: generate several solutions
from deliberately different angles, score them against one rubric with
independent judges, then build from the winner while grafting the best of the
rest. Speculative because the value rides on whether LLM "judges" are actually
independent of each other and of the solvers — see the risks section.

**Boundary vs v2 `reviewer-lenses`:** that skill runs *multiple lenses over ONE
artifact* (security, perf, readability) to review what already exists. THIS
generates *N DIFFERENT candidate solutions* to one problem, then judges compete
them. Reviewer-lenses critiques; this one explores and selects.

## The loop

**1. Fix the rubric first.** Write 3-5 weighted scoring criteria *before* any
solution exists, so judges grade against an external standard, not against
whichever candidate they read first. e.g. correctness (×3), simplicity (×2),
risk/blast-radius (×2), fit-to-existing-patterns (×2), time-to-ship (×1). If you
can't state the rubric, you can't run the panel.

**2. Pick distinct angles, not retries.** Assign each solver a different
*framing* — MVP-first, risk-first, user-first, performance-first,
maintainability-first. Same angle three times is "try harder" and yields three
flavors of the same idea. Choose 3-4 angles.

**3. Dispatch solvers in parallel.** This is v1 `dispatching-parallel-agents`
applied to *solutions*: each solver gets the same problem + rubric, works in
isolated scratch space, and returns a proposed solution plus a one-paragraph
rationale. Cap at ~5-6 concurrent; scale rounds, not width. For richer per-solver
work, each angle can run as a v1 `subagent-driven-development` thread.

**4. Judge in parallel, blind to authorship.** Spawn 2-3 judge agents. Strip the
angle labels. Each judge scores *all* solutions on every criterion independently
and commits its verdict before seeing peers. Average the scores. Flag any
solution where judges disagree sharply (>3 point spread) — that's a signal the
rubric is ambiguous or the solution is polarizing, not a clean winner.

**5. (High-stakes only) Harden the verdict.** Run 1-3 debate rounds where judges
see peers' scores and may revise — but a judge that *shifts position without
citing new evidence* is flagged for sycophancy and the shift is discounted.
Unanimity across independent judges is a smell (correlated bias / leading
rubric), not a triumph — spot-check by hand. Any *new* deciding factor a judge
invents that no solver raised must be re-verified against the artifact before it
moves the ranking, so a confabulated remark can't pick the winner.

**6. Synthesize, don't just ship the top score.** Build from the winner as the
base, then graft the standout pieces from the runners-up (risk-mitigation from
one, the UX detail from another). Hand the fusion to v2 `merge-parallel-results`
to reconcile the grafts into one coherent design, and record *why* the winner
won so the discarded angles aren't silently lost.

**7. Verify the synthesis.** The merged design is a new artifact no judge scored.
Verify it against the *original* problem before claiming done — its parts scoring
well does not mean the integration works.

## Why this might be crazy enough to work

Diversity of starting angle beats depth of iteration when you don't yet know
which framing is right, and a single author can't hold three incompatible
framings in mind at once — but parallel agents can each commit fully to one. The
judge panel then externalizes selection away from the author's confirmation bias.
If the angles are genuinely orthogonal and the judges genuinely independent, the
panel samples regions of the solution space that one-attempt iteration would
never reach, and majority-with-disagreement-flagging gives a calibrated pick
rather than a coin flip.

## Known risks / absurdities

The whole thing collapses if the "independent" judges aren't independent — same
base model, same prompt scaffolding, same surface cues means their agreement is
correlated noise dressed as consensus, which is exactly why step 5 treats
unanimity as a smell. Cost scales as solvers × judges, so a 4×3 panel is 12+
agent runs for one decision; reserve it for genuinely high-leverage choices.
Open questions: do the angle framings actually produce orthogonal solutions or
just cosmetically different ones; can a judge that wrote no code reliably score
correctness; and does the synthesis step quietly reintroduce the author bias the
panel was meant to remove.

## Graduation path

Promote to v2 when: (a) on a real backlog of decisions, panel-picked solutions
measurably beat single-attempt-iterated ones (fewer reverts, faster acceptance);
(b) judge independence is demonstrated — disagreement spread is non-trivial and
unanimity correlates with genuinely easy calls, not anchoring; and (c) the
rubric, angle set, and judge count are stable defaults rather than per-run
guesses. At that point rewrite to v2 standards as a supporting skill for
`dispatching-parallel-agents` / `merge-parallel-results`.
