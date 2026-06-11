# v2 Additions — Design

> **Superseded by** `2026-06-10-v2-reanalysis-design.md` (fresh evidence-pooled re-analysis; its 7 unbuilt items re-competed and only 3 survived). Task 1 (`review-clarification-gate`) was built and stands.

**Date:** 2026-06-10
**Status:** Superseded
**Scope:** 6 new v2 skills + 2 new v2 plugins (first plugins in the tier)

## Goal

Fill the evidenced gaps in the v1 tier with supporting skills and plugins, per the
v2 tier rules (new identities only, `supports:` frontmatter, no v1 duplication).

## Research basis

**Internal:** All 14 v1 skills were read and gap-analyzed. Four v1 skills had no v2
support at all: `requesting-code-review`, `receiving-code-review`,
`subagent-driven-development`, `using-superpowers`. The dominant gap pattern is
*missing decision criteria*: v1 skills say "stop and handle X" without a procedure
(unclear review feedback, re-dispatch context, architecture-vs-bug calls,
over-scoped specs, unknown verification commands, deferred review items).

**External:** Community analysis of the superpowers ecosystem (dev.to stack
comparison of superpowers/gstack/GSD; obra/superpowers-lab) independently names two
structural gaps: long-horizon decision memory across sessions ("context rot") and
multi-perspective review lenses. Both converge with internal findings.

**Selected approach:** Evidence-weighted portfolio (Approach A of three considered).
Every item below has direct file:line evidence in a v1 skill or external validation.
Rejected candidates: parallel-change conflict resolution (duplicates v2
`merge-parallel-results`), PR-description checker and skill-priority tiebreaker
(thin evidence), maximal ~12-item sweep (dilutes quality bar).

## The six skills (`v2/skills/<name>/SKILL.md`)

All follow the existing v2 frontmatter pattern (`name`, `description` stating WHEN,
`author`, `tier: v2`, `supports:`, `type:`, optional `chains-to:`/`pairs-with:`)
and open with a "Not this skill if" boundary block.

### 1. review-clarification-gate
- **supports:** [receiving-code-review, requesting-code-review] · **type:** process · **chains-to:** receiving-code-review
- When any review feedback item is unclear or technically questionable, block
  implementation of ALL items until each is classified: understood /
  needs-clarification / push-back. Provides the clarification-request template
  (quote the item, state candidate interpretations, ask which) and an escalation
  path: reviewer → human partner.
- **Evidence:** receiving-code-review says "STOP, do not implement anything yet"
  with no procedure for getting unstuck; no tracking of which items are resolved.

### 2. reviewer-lenses
- **supports:** [requesting-code-review, dispatching-parallel-agents] · **type:** technique · **chains-to:** merge-parallel-results
- For significant work, dispatch parallel reviewers each locked to ONE lens:
  correctness, architecture, security, test quality, product/UX. Merge findings
  via v2 `merge-parallel-results`.
- **Boundary:** `red-team-spec` attacks specs pre-implementation; this reviews code
  post-implementation.
- **Evidence:** external — gstack comparison names multi-perspective review as
  superpowers' missing layer; requesting-code-review has no v2 support.

### 3. context-sufficiency-check
- **supports:** [subagent-driven-development, dispatching-parallel-agents] · **type:** decision
- Pre-dispatch checklist scored before any dispatch or re-dispatch: task statement,
  success criteria, exact file paths, interface contracts, constraints, one worked
  example. Rule: if a NEEDS_CONTEXT return cannot be mapped to a specific missing
  checklist item, the problem is the task split, not the context. Hard cap: 2
  re-dispatches, then escalate to the human.
- **Evidence:** subagent-driven-development says "provide more context and
  re-dispatch" without defining "enough" — open re-dispatch-loop risk.

### 4. architecture-stall-detector
- **supports:** [systematic-debugging, test-driven-development] · **type:** decision
- Triggered when 3+ fixes have failed. Red-flag checklist: fix in layer A breaks
  layer B; shared mutable state; abstraction leaks; tests requiring heavy mocking.
  Produces a verdict (implementation bug vs architecture problem) plus the
  structured questions to bring to the human partner.
- **Evidence:** systematic-debugging says "If 3+ fixes failed: question
  architecture … discuss with your human partner" with no recognition framework.

### 5. scope-decomposition
- **supports:** [brainstorming, writing-plans] · **type:** technique · **chains-to:** writing-plans
- Concrete over-scope heuristics (count of independent user flows, distinct data
  stores, "and"-junctions in the one-sentence project description) plus a procedure
  for splitting into dependency-ordered sub-projects, each getting its own
  spec → plan cycle.
- **Evidence:** brainstorming and writing-plans both warn about over-scope; neither
  gives a detection heuristic or splitting procedure.

### 6. decision-ledger
- **supports:** [brainstorming, writing-plans, executing-plans] · **type:** process · **pairs-with:** session-handoff
- Append-only `docs/superpowers/DECISIONS.md`; each entry = decision, date, why,
  alternatives rejected. Written at design approval and at any mid-execution pivot;
  read at session start when resuming work.
- **Boundary:** `session-handoff` is a one-shot state transfer between two sessions;
  this is durable decision memory across many sessions.
- **Evidence:** external — GSD comparison names persistent decision/spec anchoring
  ("context rot") as superpowers' structural gap; internal — executing-plans has no
  resumption procedure after clarification.

## The two plugins (`v2/plugins/<name>/`)

Standard Claude Code plugin layout (`plugin.json` manifest, scripts, hooks), with
v2 discipline (`tier: v2`, `supports:`) documented in each plugin's README. They
are plugins, not skills, because both gaps need mechanical enforcement — a hook
fires whether or not the model remembers to check.

### 7. deferred-work-tracker
- **supports:** [receiving-code-review, finishing-a-development-branch]
- A script that appends deferred review items to `docs/superpowers/deferred.md`
  (date, source review/branch, item text), and a `Stop`-event hook that surfaces a
  one-line count of open deferred items at session end.
- **Failure mode handled:** v1's "Note minor issues for later" has no tracking —
  deferred work silently evaporates.
- **Fail-soft:** if `deferred.md` is absent, the hook stays silent.

### 8. verify-command-suggester
- **supports:** [verification-before-completion] (also referenced by v2 `loop-until-green`)
- A detection script mapping project markers to canonical verification commands:
  `package.json` → the test/lint/build scripts it actually finds; `pyproject.toml`
  → pytest/ruff; `Cargo.toml` → cargo test/clippy; `go.mod` → go test ./...;
  `Makefile` → test/check targets. Exposed as a `/verify-commands` slash command.
- **Suggests only — never executes the commands.**
- **Fail-soft:** if no marker is found, say so; do not guess.

## Build workflow

1. Draft each skill via the project `support-builder` agent, one at a time.
2. Every skill must pass v2 `skill-lint` and a `skill-auditor` agent run.
3. Plugins are validated with the `plugin-validator` agent; scripts get a smoke
   test (run the suggester against this repo; append + read back a deferred item
   in a temp file).
4. Build order (unsupported-v1 gaps first, then externally-validated, then
   plugins): review-clarification-gate → context-sufficiency-check →
   architecture-stall-detector → scope-decomposition → reviewer-lenses →
   decision-ledger → deferred-work-tracker → verify-command-suggester.
5. All 8 items are independent; none blocks another.

## Error handling and boundaries

- Every skill's "Not this skill if" block routes to its nearest neighbor
  (decision-ledger ↔ session-handoff, reviewer-lenses ↔ red-team-spec,
  context-sufficiency-check ↔ merge-parallel-results) so the no-duplication rule
  is enforced in the text.
- Nothing in v5 is touched; all items are new identities — no promotion or
  deletion bookkeeping this round.
- This project is intentionally not a git repository yet; this spec is saved but
  not committed (deviation from the brainstorming skill default, per CLAUDE.md).

## Out of scope

- v3/v4 content (still empty by design this round).
- Promoting any v5 Forge skill.
- Modifying any v1 skill.
- `using-superpowers` support (its skill-priority-tiebreaker gap was judged too
  thin for a standalone skill this round; revisit if it recurs).
