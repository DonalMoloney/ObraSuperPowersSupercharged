---
name: adversarial-self-distillation
description: Use right after the agent passes a task — it writes a deliberately harder variant of that task, attempts it, and on self-defeat promotes the variant into the eval suite as a new escalating-curriculum task.
tier: v3
status: experimental
---

# adversarial-self-distillation

A passed task is a dead end: it tells you the agent *can* do something, never
where the edge of that ability is. This skill makes the agent walk itself off
its own cliff and bottle the fall.

**Escalate:** the moment a task goes green, the agent must author a *harder
variant* of the same task — same shape, more adversarial inputs, tighter
constraints, an added edge case, a hostile environment. The mutation is
described, not free-form: turn one assumption into its violation, scale one
dimension past its comfort zone, remove one affordance the passing solution
leaned on. The harder variant ships with its own machine-checkable test before
the agent is allowed to attempt it.

**Self-attack:** the agent then attempts its own harder variant. A pass means
the cliff edge is still ahead — escalate again, raising difficulty until it
breaks. A failure is the prize, not a setback: the agent just discovered a task
at the boundary of its competence, one nobody had to hand-author.

**Distill:** each self-defeat is promoted into the eval suite as a new task,
tagged with the difficulty rung it sits on relative to its parent. The suite
grows from the agent's own losses — an escalating curriculum mined not from
history but from the live frontier of what the agent *cannot quite* do yet.

**Boundary:** v2 `red-team-spec` attacks SPECS pre-implementation; v3
`predator-prey-review` attacks CODE with co-evolving adversaries. This skill
attacks neither — it generates ESCALATING TASKS. It is a new lane that *feeds*
v3 `eval-suite-from-git`: that skill recovers regression tasks from `.git`
(yesterday's verified mistakes); this one manufactures frontier tasks from
self-defeats (tomorrow's not-yet-mistakes). Both emit into the same
`evals/` suite under the same admission gate; neither writes the other's tasks.

**Fitness signal:** difficulty-calibrated pass rate — the suite tracks, per
escalation rung, what fraction of self-generated variants the agent passes, and
the rung at which it consistently fails is the explicit, machine-checked
boundary of current competence. The signal is verifiable because every promoted
variant carries its own binary test (red on the self-defeat, the same admission
round-trip `eval-suite-from-git` enforces); a variant only enters the suite if
its check provably fails for the attempting agent. The curriculum *is* the
agent's own generated tasks, and the suite grows precisely from its losses.

## Why this might be crazy enough to work

Frontier difficulty is exactly the data a self-improvement loop is starving
for and exactly what history can't supply: git only holds bugs someone already
fixed, never the tasks just past the agent's current ceiling. An agent that
just solved something is the cheapest available oracle for "what's one notch
harder than this" — it has the solved instance in context and can perturb it
locally. Pairing that generator with a hard pass/fail gate means difficulty is
never asserted, only demonstrated by an actual self-defeat, so the curriculum
calibrates itself to the real edge instead of to a guess about it.

## Known risks / absurdities

The agent will write *weird*-hard, not *meaningfully*-hard — variants that are
unsolvable, ill-posed, or hard for irrelevant reasons (a longer prompt, a
flakier test) rather than along any axis of real capability, Goodharting "make
me fail" into "make me fail trivially." Unbounded escalation is a difficulty
runaway: every win spawns a harder child, and the suite bloats with
impossible-by-construction tasks that teach nothing. Calibration assumes the
agent attempting the variant is the same one whose competence the rung claims
to measure — model swaps and context drift desync the rungs from reality. A
sanity filter (the parent test must still pass; the variant must be a strict
superset of the parent's constraints; cap escalation depth) and a human or
sibling-agent check on whether a self-defeat is *legitimate* are probably
required before any rung counts as real.

## Likely graduation criteria (path to v2)

Promote to v2 when: (1) the mutation operators are concrete and bounded (a fixed
menu of escalation axes, not free-form "make it harder"), and each emitted
variant provably passes the admission round-trip into `eval-suite-from-git`'s
suite; (2) self-defeats are filtered for legitimacy at a documented precision —
ill-posed / irrelevant-hard variants are rejected, not promoted; (3) the
difficulty-calibrated pass rate is reproducible (same agent + same parent →
same rung assignment) and runaway escalation is capped; and (4) the curriculum
demonstrably surfaces failure modes that `eval-suite-from-git` does not, on at
least two real projects. At that point it becomes a frontier-mining counterpart
to the regression miner — rewrite to v2 standards and move it.
