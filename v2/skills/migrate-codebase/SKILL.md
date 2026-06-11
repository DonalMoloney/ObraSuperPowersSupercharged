---
name: migrate-codebase
description: Use for large mechanical migrations (framework bump, API rename, dependency swap) — discover every call site, transform each in its own worktree, verify each independently with no barrier between stages. The codemod harness.
author: Donal Moloney
tier: v2
supports: [dispatching-parallel-agents, using-git-worktrees]
type: process
chains-to: finishing-a-development-branch
---

## Not this skill if
- The change touches one or two files — just edit them directly.
- Sites share mutable state and can't be transformed independently — use v1 **executing-plans**.
- The migration is exploratory (you don't yet know what needs to change) — use v1 **brainstorming** first to pin down what the change actually is.
- You need to run the same read-only audit on every file — use a read-only parallel sweep via v1 **dispatching-parallel-agents** instead.

# migrate-codebase — pipeline a migration across every call site

## Purpose

Turn a sweeping mechanical change into a per-site pipeline: each site flows discover → transform →
verify on its own, so one failure drops that site and skips its stages instead of stalling the batch.

## Core rule

> **Rule:** One worktree per concurrently-mutated site, verify each site in isolation, never advance
> a site whose tests don't pass. Report dropped sites loudly — silent truncation reads as success.

## Triggers

**Use when:**
- A framework or major library version bump rewrites import paths or API signatures.
- A symbol, function, or module is renamed across the entire repo.
- A dependency is swapped out and every call site needs the new calling convention.
- A codemod can be expressed as a deterministic before → after rule and applied per file independently.
- The work-list is large enough (≥ 5 sites) that sequential editing is error-prone or slow.

**Don't use when:**
- Fewer than 3–4 files are affected — edit them directly; worktree overhead is not worth it.
- Sites share mutable state (e.g., a single config file written by multiple agents) — sequence the writes with v1 **executing-plans**.
- The migration requires human judgment at each site (not mechanical) — use v1 **subagent-driven-development** with human checkpoints instead.
- You haven't confirmed the before → after rule yet — spike it on one file first, then return here.

## The pattern (multi-agent pipeline)

```
discover → [per-site: transform → verify] → collect → merge-back → v1 finishing-a-development-branch
```

Each stage is described below. The pipeline is not symmetric: discover and merge-back run once;
transform and verify run once per site, in isolated worktrees, in parallel.

## Steps

### 1. Define the transform precisely

Before touching any file, write out the transform rule as a concrete before → after example.

- State the old pattern (import path, function signature, config key, etc.).
- State the new pattern it must become.
- Note any edge cases: overloaded names, auto-generated files, vendored copies, test fixtures that intentionally keep the old pattern.
- If the transform is non-trivial, express it as a codemod script (GritQL, jscodeshift, OpenRewrite recipe) so it runs deterministically at every site.

Do not proceed to discovery until the rule is unambiguous.

### 2. Discover every call site

Run the discovery pass against the full repo:

- Use grep, ripgrep, or an AST-aware tool (GritQL / jscodeshift `--dry-run`) to find every match.
- Log the total count before any filtering: `Found N call sites in M files.`
- Flag ambiguous matches separately — sites where the pattern appears but the context is unclear. Do not auto-transform ambiguous sites; add them to a manual review list.
- If the count exceeds the concurrency cap (≈16 parallel worktrees), split into batches and document the batch plan before starting.

### 3. Transform each site in its own worktree

For each site in the work-list:

- Check out a short-lived worktree (v1 **using-git-worktrees**, one per site) branched from the migration branch.
- Apply the codemod to that site only.
- Do not touch adjacent files unless the transform rule explicitly requires it.
- Log the exact change applied (file path, line range, diff summary).

Run sites in parallel up to the concurrency cap. Do not let one site's transform block another.

### 4. Verify each site in isolation

Immediately after the transform in the same worktree:

- Run only the tests that exercise the transformed site (unit tests, integration tests scoped to the module). Do not run the full suite per site — that defeats the isolation model.
- If tests pass: mark the site `applied` and stage the worktree for merge-back.
- If tests fail: mark the site `failed`, log the failure output, discard the worktree, and continue with the remaining sites. Do not block the pipeline on a single failure.
- If the site is ambiguous or was flagged during discovery: mark it `skipped` with the reason.

### 5. Collect results

After all per-site pipelines complete, produce the results table:

| Site (file:line) | Status | Notes |
|---|---|---|
| `src/api/auth.ts:42` | applied | import path updated |
| `src/legacy/old.ts:17` | failed | type mismatch after rename |
| `test/fixtures/old-api.ts:3` | skipped | intentional fixture — keep old pattern |

Print the totals: applied N / failed N / skipped N. Do not omit any category even if zero.

### 6. Merge passing sites

Merge each `applied` worktree back to the migration branch in sequence (to avoid write conflicts).
Resolve any conflicts that arise — typically import ordering or adjacent-line changes — and log each resolution.

After all merges: run the full test suite on the migration branch. A clean run here confirms the
integration is sound. If it fails, investigate whether a passing per-site verification missed a
cross-site interaction; treat this as a new defect to isolate.

### 7. Hand off

Pass the migration branch to v1 **finishing-a-development-branch** for final cleanup, PR preparation, and CI confirmation.

Surface the dropped-site list prominently in the PR description so reviewers know which sites were
not migrated and why.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Silent dropped sites — the report shows only applied sites | Always print failed and skipped counts even when zero; list every dropped site with its reason |
| Running the full test suite per site | Scope tests to the transformed module only; full-suite per site multiplies wall time and obscures which site caused a failure |
| Transforming ambiguous matches automatically | Flag ambiguous sites during discovery and add them to a manual review list; never auto-apply when context is unclear |
| Starting merge-back before all per-site pipelines finish | Collect all results first; only then begin sequential merge-back |
| A single site failure aborts the whole pipeline | Catch per-site failures, mark them dropped, and continue; the pipeline must reach collect even with failures |
| Applying the codemod to vendored or generated files | Exclude `vendor/`, generated output dirs, and intentional fixture files from the work-list during discovery |
| Using one branch for all concurrent transforms | Each site gets its own worktree; shared-branch transforms produce interleaved conflicts that are hard to unwind |

## Proof

Hand the merged migration branch to v1 **finishing-a-development-branch** once the full-suite run is clean.

The output must contain:

- Per-site results table (site path | status | notes) covering every discovered site.
- Totals: applied N / failed N / skipped N.
- Explicit list of every dropped site (failed or skipped) with the reason each was dropped.
- Full-suite test result on the merged migration branch (pass/fail + run identifier).
- `EVIDENCE:` the per-site pipeline log (worktree IDs or explicit per-site confirm lines), the full-suite run output, and the merge log showing which worktrees were integrated.

## Adapt from
- **`getgrit/gritql`** / **`facebook/jscodeshift`** — declarative codemod engines for the transform
  stage. <https://github.com/getgrit/gritql> · <https://github.com/facebook/jscodeshift>
- **`openrewrite/rewrite`** — recipe-based large-scale migration model.
  <https://github.com/openrewrite/rewrite>
