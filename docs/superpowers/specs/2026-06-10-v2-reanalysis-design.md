# v2 Re-Analysis — Design

**Date:** 2026-06-10
**Status:** Approved by user (design review), pending spec review
**Supersedes:** `2026-06-10-v2-additions-design.md` (and its plan `docs/superpowers/plans/2026-06-10-v2-additions.md`)
**Scope:** 8 new v2 skills — 5 net-new, 3 promoted from v5. No plugins this round.

## Goal

Replace the morning's v2 additions spec with a portfolio re-derived from scratch.
The 7 unbuilt items of the old spec competed on equal footing with v5 promotion
candidates and fresh findings; only evidence-backed items survived.

## Research basis (three parallel streams, run 2026-06-10)

**Stream 1 — v1 gap re-read.** All 14 v1 skills re-read for instruction-without-
procedure gaps. Strongest cluster: `subagent-driven-development` — the only
workflow v1 skill with zero v2 support — has two HIGH-rated gaps: model selection
per task (signals listed, no decision matrix) and BLOCKED-status handling (four
remediation paths given, zero diagnosis criteria).

**Stream 2 — v5 promotion scan.** All 88 Forge-imported v5 skills triaged against
the v2 qualifying rules (supports a v1 workflow; not a shadow of an obra core
skill; no duplication of the 7 existing v2 skills; agent-invokable, not
repo-specific tooling). 12 candidates shortlisted, 11 rated strong.

**Stream 3 — external research.** Community comparisons (superpowers vs gstack vs
GSD: dev.to, Pulumi, Particula, two Medium analyses, HN), obra's own blog/lab, and
the upstream issue tracker. Top corroborated gaps: cross-session decision memory
("context rot", 4+ sources), multi-perspective review (4 sources), no post-merge
ship/retro loop (3 sources), no security review discipline (3 sources). obra
himself names "more aggressive task decomposition" as his next direction.

**Selection rule:** evidence-pooled portfolio (Approach A of three considered;
coverage-first and promotion-first rejected). Every selected item needs a specific
v1 gap or independent external validation. Tie-breaker: where a net-new idea and a
v5 candidate fill the same gap with equal evidence, promote the v5 skill.

## The eight skills (`v2/skills/<name>/SKILL.md`)

All follow the v2 house style: frontmatter (`name`, `description` stating WHEN,
`author`, `tier: v2`, `supports:`, `type:`, optional `chains-to:`/`pairs-with:`),
a `## Not this skill if` boundary block, numbered procedure, and a `PROVEN BY:`
verification block.

### 1. compile-goal-to-contract (v5 promotion)
- **supports:** [subagent-driven-development, writing-plans] · **type:** technique · **chains-to:** dispatch-triage
- Turns a vague goal into a verifiable pre-dispatch contract: acceptance criteria,
  out-of-scope list, done-when, constraints. Gates autonomous dispatch on contract
  completeness.
- **Replaces** the old spec's `context-sufficiency-check` via the tie-breaker —
  same gap (under-specified dispatch prompts), content already exists in v5.
- **Evidence:** subagent-driven-development gives no definition of "enough
  context" before dispatch; v5 scanner rated the existing content excellent.

### 2. dispatch-triage (net-new)
- **supports:** [subagent-driven-development] · **type:** decision · **pairs-with:** compile-goal-to-contract
- Two decision tables the v1 skill lacks: (a) model-tier selection — mapping
  (file count, spec completeness, integration scope) → model choice; (b) BLOCKED-
  return diagnosis — a question ladder distinguishing context problem vs reasoning
  complexity vs oversized task vs wrong plan, each mapped to its remediation.
  Carries the old `context-sufficiency-check` re-dispatch cap: max 2 re-dispatches,
  then escalate with the diagnosis trail.
- **Evidence:** both gaps rated HIGH in the fresh re-read (Gaps 11 and 12);
  subagent-driven-development previously unsupported.

### 3. delta-debugger (v5 promotion)
- **supports:** [systematic-debugging, test-driven-development] · **type:** technique · **pairs-with:** loop-until-green
- Mechanized fault localization: ddmin input minimization plus git-bisect commit
  localization, driven by a reproducible predicate script, with a cross-validation
  step.
- **Boundary:** `loop-until-green` iterates fix→verify; this finds *where* the
  fault is before any fix is attempted.
- **Evidence:** v5 scanner rated excellent; fills systematic-debugging's mechanics
  gap without overlapping existing v2 debugging support.

### 4. done-gate (v5 promotion)
- **supports:** [verification-before-completion, requesting-code-review] · **type:** process · **chains-to:** reviewer-lenses
- Unified completion gate: runs the verification battery, computes a blast-radius
  risk score, and routes review depth by risk — low risk passes with evidence,
  high risk chains into `reviewer-lenses`.
- **Boundary:** `loop-until-green` is the iterate-to-green loop; done-gate is the
  single final gate after it.
- **Evidence:** v5 scanner rated excellent; verification-before-completion has no
  procedure for deciding how much review a change needs.

### 5. decision-ledger (net-new, survived from old spec)
- **supports:** [brainstorming, writing-plans, executing-plans] · **type:** process · **pairs-with:** session-handoff
- Append-only `docs/superpowers/DECISIONS.md`: each entry = decision, date, why,
  rejected alternatives, optional `Supersedes:`. Written at design approval and
  mid-execution pivots; read at every resume. Reversals append, never edit.
- **Boundary:** `session-handoff` is one-shot state transfer to the next session;
  the ledger is durable decision memory across many sessions. (v5 `write-adr`
  stays in v5: repo-facing ADR documents, not session decision memory.)
- **Evidence:** external stream's strongest finding — "context rot" named by 4+
  independent sources as the structural superpowers gap.

### 6. reviewer-lenses (net-new, survived from old spec)
- **supports:** [requesting-code-review, dispatching-parallel-agents] · **type:** technique · **chains-to:** merge-parallel-results
- Parallel reviewers, each locked to ONE lens: correctness, architecture,
  security, test quality, product/UX. Lens count scales with risk (default 3).
  The security lens explicitly covers the externally-named gap (OWASP-style
  checks, injection-aware review of tool output). Merge via
  `merge-parallel-results`; process via v1 receiving-code-review.
- **Boundary:** `red-team-spec` attacks specs pre-implementation; lenses review
  code post-implementation.
- **Evidence:** external — multi-perspective review (4 sources) + security review
  discipline (3 sources).

### 7. scope-decomposition (net-new, survived from old spec)
- **supports:** [brainstorming, writing-plans] · **type:** technique · **chains-to:** writing-plans
- Four over-scope heuristics (independent user flows, distinct data stores,
  "and"-junctions, plan-size projection); any "yes" → split into dependency-
  ordered sub-projects, spec only the first, re-check ordering after each ships.
- **Evidence:** internal — brainstorming says "flag this immediately" with no
  detection criteria; external — obra names aggressive task decomposition as his
  explicit next direction (author-authoritative).

### 8. post-merge-retro (net-new)
- **supports:** [finishing-a-development-branch] · **type:** process
- Picks up where finishing-a-development-branch ends (merge/PR decision): a ship
  checklist (changelog, deploy/release step if one exists, smoke check) and a
  structured retro — what did this feature teach, and does any learning belong in
  CLAUDE.md, a skill, or the decision ledger. Fail-soft: items that don't apply
  (no deploy pipeline) are skipped explicitly, not silently.
- **Evidence:** external — three sources independently note the lifecycle ends at
  merge with no ship/retro/learning loop.

## Rejected and re-routed (with reasons)

**Old-spec items that lost the competition:**
- `architecture-stall-detector` — not re-surfaced by the fresh v1 re-read;
  systematic-debugging is now well-served by delta-debugger + loop-until-green.
  Revisit if the 3-failed-fixes stall recurs in practice.
- `deferred-work-tracker`, `verify-command-suggester` (both plugins) — evidence
  not re-corroborated this round; revisit on recurrence.

**Fresh v1 gaps re-routed to v1 supercharging** (work orders to add to
`v1/SUPERCHARGING-OPTIONS.md`, not v2 skills — they improve existing v1 content
in place): spec self-review rubric (brainstorming), RED-phase validation
checklist (test-driven-development), diagnostic instrumentation recipes
(systematic-debugging), task-granularity heuristic (writing-plans).

**v5 shortlist candidates left in v5** (strong content, thin direct v1-gap
evidence this round): task-dag-planner, wave-runner, conflict-graph-scheduler,
hypothesis-ranker, self-repair-loop, evidence-trail, parallel-judge-panel,
consensus-decision.

**External findings explicitly not built:** framework token cost (upstream's
problem), browser/visual verification (better as a v4 verification-loop tool),
task-triage ceremony scale-down (philosophically contested), skill evals
(revisit alongside v5 `skill-test-harness`), multi-model adherence (out of
scope). `using-superpowers` remains intentionally unsupported.

## Promotion mechanics and bookkeeping

- Each promoted skill (`compile-goal-to-contract`, `delta-debugger`, `done-gate`)
  is **rewritten** under v2 discipline — frontmatter, boundary block, PROVEN BY —
  not copied verbatim; then the original directory is **deleted** from
  `v5/skills/` (per the CLAUDE.md promotion rule).
- The old spec and plan each get a one-line `Superseded by` header pointing here.
- `v2/README.md` "Current skills" table gains all 8 new rows **plus** the missing
  `review-clarification-gate` row (pre-existing drift, fixed in passing).

## Build workflow

1. One skill at a time; every skill passes the 7-point `skill-lint` checklist and
   a `skill-auditor` agent run before the next begins.
2. Build order — subagent-driven-development coverage first, then remaining
   promotions, then remaining net-new:
   compile-goal-to-contract → dispatch-triage → delta-debugger → done-gate →
   decision-ledger → reviewer-lenses → scope-decomposition → post-merge-retro.
3. All 8 items are independent; none blocks another.
4. The four v1-supercharging work orders are appended to
   `v1/SUPERCHARGING-OPTIONS.md` as a final bookkeeping task.
5. No git commits — the project is intentionally not a git repository
   (deviation from the brainstorming skill default, per CLAUDE.md).

## Error handling and boundaries

- Every skill's "Not this skill if" block routes to its nearest neighbor
  (done-gate ↔ loop-until-green, delta-debugger ↔ loop-until-green,
  decision-ledger ↔ session-handoff, reviewer-lenses ↔ red-team-spec,
  dispatch-triage ↔ compile-goal-to-contract) so the no-duplication rule is
  enforced in the text.
- Promotions that fail rewrite (content turns out not to fit v2 discipline) fall
  back to staying in v5 and the gap re-enters the next analysis round — do not
  force a bad fit.

## Out of scope

- v3/v4 content; promoting any other v5 skill; modifying v1 skill bodies
  (supercharging work orders are listed, not executed, this round).
- Building any plugin.
