# v2 Idea Candidates — supporting skills that amplify v1 core

**Date:** 2026-06-18
**Status:** Candidate list for selection — nothing here is committed to build yet.
**Rule reminder (v2 README / root CLAUDE.md):** v2 is *new skill identities only* —
anything that already exists in upstream obra belongs in v1, not here. Every built v2 skill
needs a `supports:` frontmatter line naming the v1 skill(s) or workflow it amplifies, must
not duplicate v1 content (reference it), and gets added to the "Current skills" table in
`v2/README.md` once built. See `CHAINING-OPTIONS.md` before adding anything that hands off
to / builds on another skill.

> **v2 contract:** each idea names the **v1 skill it supports** and a **boundary** proving it
> does not restate that skill. Ideas that only re-describe a v1 skill don't belong here.

These six skills + one plugin came out of the 2026-06-18 brainstorm; they target gaps
*between* existing v2 skills rather than new ground (e.g. `loop-until-green` retries until
green — nothing catches when "green" was luck).

---

## The shortlist

| # | Build | Supports (v1) | Effort | Overlap |
|---|-------|---------------|--------|---------|
| V1 | **plan-drift-detector** | executing-plans, writing-plans | S | NEW — vs `done-gate`, `track-assumption` |
| V2 | **flaky-test-quarantine** | test-driven-development, verification-before-completion | M | NEW — inverse of `loop-until-green` |
| V3 | **bisect-the-regression** | systematic-debugging | M | NEW — vs `delta-debugger` |
| V4 | **review-feedback-triage** | receiving-code-review | S | NEW — vs `review-clarification-gate`, `reviewer-lenses` |
| V5 | **pr-description-synthesizer** | requesting-code-review, finishing-a-development-branch | S | NEW — vs `write-release-notes` |
| V6 | **dependency-upgrade-pilot** | test-impact-analysis, migrate-codebase | M | OVERLAP → v5 `dependency-risk-sweep` |
| P1 | **regression-guard** (plugin) | test-driven-development, systematic-debugging | M | bundles V2 + V3 + verifier hook |

---

## Detail per idea

### V1. plan-drift-detector
During plan execution, flags when actual changes diverge from the written plan — files
touched that aren't in the plan, steps skipped or reordered — and forces a reconcile before
continuing.
- **Supports:** `executing-plans` (drift mid-execution), `writing-plans` (feeds plan gaps back).
- **Boundary:** `done-gate` checks *completion* at the end; `track-assumption` watches
  *assumptions*. This watches *plan ↔ reality divergence* during execution. New lane.
- **Effort:** S.

### V2. flaky-test-quarantine
Re-runs a failing test N times, classifies it flaky vs real, quarantines the flaky one and
files a ticket — so nondeterminism never masks a real failure or gets silently "fixed" by a
retry.
- **Supports:** `test-driven-development`, `verification-before-completion`.
- **Boundary:** the deliberate inverse of `loop-until-green` (which retries until a verifier
  passes). This fires when a pass is *luck*. Natural `pairs-with: loop-until-green`.
- **Effort:** M.

### V3. bisect-the-regression
Wraps `git bisect` with an automated check script to localize a regression to a single
commit, then hands that commit to debugging.
- **Supports:** `systematic-debugging`.
- **Boundary:** `delta-debugger` minimizes the *failing input*; this minimizes *history*.
  Complementary — `chains-to: systematic-debugging` once the commit is found.
- **Effort:** M.

### V4. review-feedback-triage
Classifies each incoming review comment (blocking / nit / question / wrong) and routes it:
implement, push back with evidence, or clarify.
- **Supports:** `receiving-code-review`.
- **Boundary:** `review-clarification-gate` handles only the *clarify* branch; `reviewer-lenses`
  *generates* reviews. This is the *receiving-side triage* across all four branches.
- **Effort:** S.

### V5. pr-description-synthesizer
Builds a high-signal PR body from the diff + commits + linked spec: what / why / risk /
test evidence / rollback.
- **Supports:** `requesting-code-review`, `finishing-a-development-branch`.
- **Boundary:** `write-release-notes` is *user-facing* notes; this is the *reviewer-facing*
  PR body. Distinct audience and content.
- **Effort:** S.

### V6. dependency-upgrade-pilot
Reads the changelog, runs test-impact analysis, stages the bump behind a verify loop, and
rolls back on break.
- **Supports:** `test-impact-analysis`, `migrate-codebase`.
- **Boundary — OVERLAP with v5 `dependency-risk-sweep`.** That Forge import *assesses* risk;
  this *executes* the upgrade with a verify loop. Building V6 should trigger the v5
  promote/dedup decision (per root CLAUDE.md v5 rule) — fold the sweep in as the assessment
  step rather than shipping two dependency skills.
- **Effort:** M.

### P1. regression-guard (plugin)
Bundles `flaky-test-quarantine` (V2) + `bisect-the-regression` (V3) + a `Stop`/`PostToolUse`
hook that runs the project verifier and a `PreToolUse` guard.
- **Supports:** `test-driven-development`, `systematic-debugging`.
- **Why a plugin:** hooks make the verifier fire *mechanically*, independent of model memory
  (Cherny's hooks-as-enforcement principle) — a skill alone can be forgotten.
- **Effort:** M.

---

## Open questions for selection
1. V6 vs v5 `dependency-risk-sweep`: extend the v5 skill in place, or build V6 fresh and
   delete the v5 import?
2. P1 regression-guard: ship the two skills first and add the plugin wrapper later, or build
   the plugin from the start?
3. Should `pr-description-synthesizer` (V5) and `write-release-notes` share a diff-summary
   helper, or stay fully independent?

---

## Status tracker (2026-06-18)

| Idea | Status |
|------|--------|
| V1 plan-drift-detector | candidate — backlog (recommended build-first) |
| V2 flaky-test-quarantine | candidate — backlog (recommended build-first) |
| V3 bisect-the-regression | candidate — backlog |
| V4 review-feedback-triage | candidate — backlog |
| V5 pr-description-synthesizer | candidate — backlog |
| V6 dependency-upgrade-pilot | candidate — overlap; promote/dedup v5 `dependency-risk-sweep` |
| P1 regression-guard (plugin) | candidate — backlog (recommended build-first) |
