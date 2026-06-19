# v6 — Runnable AI-Powered GitHub Actions (CI/CD)

**Date:** 2026-06-18
**Status:** Approved design, pre-implementation
**Topic:** New `v6/` tier: a library of production-grade GitHub Actions workflow templates that call Claude on repo events.

## Summary

Add a sixth tier, `v6/`, to the repo. Unlike v1–v5 (which are Claude Code *skills*),
v6 is a **runnable templates library**: each idea is a drop-in GitHub Actions workflow
plus helper scripts and short setup docs. The defining discipline is the CI engineering
around the model call — least-privilege permissions, concurrency, event/path/label
gating, idempotency, and a shared cost ceiling — not the prompt itself.

This first cut ships the flagship trio plus the shared infrastructure piece they route
through:

1. `_cost-guardrail` (#11) — reusable composite action: token + spend ceiling + caching.
2. `incremental-pr-reviewer` (#1) — delta-only, line-level PR review.
3. `self-healing-ci-triage` (#2) — diagnose failed CI runs from logs.
4. `autonomous-issue-fixer` (#3) — label-gated Claude Code fix → draft PR.

The remaining menu items (#4–#10) are deferred to later v6 batches.

## Tier definition (to be added to repo `CLAUDE.md`)

> **`v6/`** — Runnable AI-powered GitHub Actions (CI/CD). Production-grade workflow
> templates that call Claude on repo events. Each idea = `v6/<action-name>/` containing
> a drop-in `workflow.yml`, helper `scripts/`, and a short `README.md` (install steps,
> required secrets, permissions, cost notes). No `SKILL.md`. Every workflow MUST:
> declare least-privilege `permissions:`, set `concurrency:`, gate by event/path/label,
> be idempotent (update a sticky comment rather than posting new ones), and route AI
> calls through the v6 `_cost-guardrail`.

The `CLAUDE.md` tier-table row is **proposed** as part of the build and committed only
if the user wants it.

## Folder layout

```
v6/
├── README.md                          # tier intro + install/secrets matrix
├── _cost-guardrail/                   # #11 reusable composite action (build first)
│   ├── action.yml
│   └── scripts/budget.mjs
├── incremental-pr-reviewer/           # #1
│   ├── workflow.yml
│   ├── scripts/review.mjs
│   └── README.md
├── self-healing-ci-triage/            # #2
│   ├── workflow.yml
│   ├── scripts/diagnose.mjs
│   └── README.md
└── autonomous-issue-fixer/            # #3
    ├── workflow.yml
    └── README.md
```

Each `workflow.yml` is written to be copied into a consuming repo's
`.github/workflows/`. The README in each folder states exactly where to copy it, which
secrets/variables to set, and the expected monthly cost envelope.

## Component designs

### #11 — `_cost-guardrail` (composite action)

Built first; the other three reference it.

- **Type:** composite GitHub Action (`action.yml`).
- **Responsibility:** wrap a single Anthropic Messages API call with cost safety.
- **Inputs:** `prompt`, `model`, `max-tokens`, `monthly-cap-usd`, `cache-key`.
- **Behavior:**
  - Enforces a per-run output ceiling via `max_tokens`.
  - Maintains a monthly USD spend counter in a repo variable; fails an emitted check
    when `monthly-cap-usd` is exceeded, before making the call.
  - Caches responses with `actions/cache` keyed on a content hash so re-runs on an
    unchanged input are free.
- **Output:** `response` (model text), `spent-usd` (running monthly total).
- **Depends on:** `ANTHROPIC_API_KEY`, `actions/cache`, repo variable for the counter.

### #1 — `incremental-pr-reviewer`

- **Trigger:** `pull_request: [opened, synchronize]`.
- **Permissions:** `contents: read`, `pull-requests: write`.
- **Concurrency:** keyed on the PR number; cancels superseded runs.
- **Behavior:**
  - Reads a hidden marker in a sticky comment to find the last-reviewed SHA.
  - Computes the diff **since that SHA** (full diff on first run) so re-reviews only
    cover new changes.
  - Sends the delta to Claude (default **Sonnet**, high volume) via `_cost-guardrail`.
  - Posts **line-level review comments** through the Reviews API with severity tags
    (`blocker` / `warning` / `nit`).
  - Edits a **sticky summary comment** in place; updates the marker SHA.
- **Depends on:** `_cost-guardrail`, `GITHUB_TOKEN`, `ANTHROPIC_API_KEY`.

### #2 — `self-healing-ci-triage`

- **Trigger:** `workflow_run: { types: [completed] }`; runs only when
  `conclusion == failure`.
- **Permissions:** `contents: read`, `actions: read`, `pull-requests: write`.
- **Behavior:**
  - Downloads the failed run's logs, extracts the failing step's tail.
  - Sends the failing excerpt to Claude (default **Sonnet**) for a root-cause +
    suggested-fix diagnosis via `_cost-guardrail`.
  - Posts the diagnosis as a comment on the associated PR, **deduped** against prior
    diagnoses (sticky marker keyed on the failing job + commit).
- **Depends on:** `_cost-guardrail`, `GITHUB_TOKEN`, `ANTHROPIC_API_KEY`.

### #3 — `autonomous-issue-fixer`

- **Trigger:** `issues` / `issue_comment`, **hard-gated** on the `claude-fix` label or
  an `@claude` mention so it never fires unprompted.
- **Permissions:** `contents: write`, `pull-requests: write`, `issues: write`.
- **Behavior:**
  - Posts a **plan-first comment** describing the intended fix before editing.
  - Uses the official `anthropics/claude-code-action` to implement the change on an
    **isolated branch** (default model **Opus**).
  - Opens a **draft** PR linked to the issue.
- **Depends on:** `anthropics/claude-code-action`, `GITHUB_TOKEN`, `ANTHROPIC_API_KEY`.

## Cross-cutting decisions

- **Helper scripts in Node (`.mjs`)** — runs on the runner's preinstalled Node, no extra
  toolchain install.
- **Models:** Sonnet for high-volume review/triage; Opus for the autonomous fixer. Exact
  model IDs confirmed against the `claude-api` skill at build time.
- **Per-folder `README.md`** — usage docs for a runnable template (secrets, copy target,
  cost), not a `SKILL.md`.
- **Idempotency everywhere** — sticky comments with hidden markers, never new comments
  on re-run.
- **Least privilege** — each workflow declares the narrowest `permissions:` block that
  works.

## Out of scope (this batch)

- Menu items #4 (semantic triage & routing), #5 (release notes), #6 (flaky-test
  detective), #7 (dependency-update risk analyst), #8 (docs-drift guardian), #9 (security
  triage on diff), #10 (PR description autofill). Deferred to later v6 batches.
- A v6 `MANIFEST.md` / repo-manifest update — handled separately if desired.

## Verification

- `actionlint` (or equivalent) parses every `workflow.yml` without error.
- Each workflow declares an explicit `permissions:` block and a `concurrency:` group.
- Each AI-calling workflow routes through `_cost-guardrail`.
- Each folder has a `README.md` naming required secrets and the copy target.
