# v6 — Runnable AI-Powered GitHub Actions (CI/CD)

Production-grade GitHub Actions workflow templates that call **Claude** on repo events.
Unlike v1–v5 (which are Claude Code *skills*), v6 is a **runnable templates library**:
each folder is a drop-in workflow you copy into a consuming repo's
`.github/workflows/`, plus helper scripts and setup docs.

The defining discipline is the CI engineering around the model call, not the prompt:
least-privilege `permissions:`, `concurrency:`, event/path/label gating, idempotent
sticky comments, and a shared monthly **cost ceiling**.

> Design spec: `docs/superpowers/specs/2026-06-18-v6-ai-github-actions-design.md`.

## What's here

| Folder | Trigger | What it does |
|--------|---------|--------------|
| [`_cost-guardrail/`](_cost-guardrail/) | reusable composite action | Wraps one Anthropic API call with a per-run output ceiling + a persisted monthly USD spend ceiling. The other actions call it. |
| [`incremental-pr-reviewer/`](incremental-pr-reviewer/) | `pull_request` | Line-level review comments on the **delta since its last review**; sticky summary. |
| [`self-healing-ci-triage/`](self-healing-ci-triage/) | `workflow_run` (failure) | Reads the failed run's logs and posts a root-cause + suggested-fix diagnosis. |
| [`autonomous-issue-fixer/`](autonomous-issue-fixer/) | `issues` / `issue_comment` | Label-gated: Claude Code implements the fix on a branch and opens a **draft** PR. |

## Install (every template)

1. Copy the folder's `workflow.yml` into your repo at `.github/workflows/<name>.yml`.
2. Copy any `scripts/*` into `.github/workflows/scripts/`.
3. Copy `_cost-guardrail/` into `.github/actions/cost-guardrail/` (the reviewer and
   triage templates reference it as `./.github/actions/cost-guardrail`).
4. Add the secrets/variables below.

Per-folder READMEs give the exact mapping and caveats.

## Secrets & variables

| Name | Kind | Used by | Notes |
|------|------|---------|-------|
| `ANTHROPIC_API_KEY` | **secret** | all | Required. |
| `CLAUDE_REVIEW_MODEL` | variable | reviewer | Optional. Default `claude-sonnet-4-6`. |
| `CLAUDE_TRIAGE_MODEL` | variable | triage | Optional. Default `claude-sonnet-4-6`. |
| `CLAUDE_FIXER_MODEL` | variable | fixer | Optional. Default `claude-opus-4-8`. |
| `CLAUDE_MONTHLY_CAP_USD` | variable | reviewer, triage | Optional. Default `25`. Shared monthly ceiling. |

`GITHUB_TOKEN` is provided automatically; each workflow requests the narrowest
`permissions:` it needs.

## Models & cost

Defaults follow the design: **Sonnet 4.6** for high-volume review/triage, **Opus 4.8**
for the autonomous fixer. Bump any of them to a more capable model by setting the
matching repo variable above — no edit to the YAML required.

The cost-guardrail enforces a soft monthly ceiling using a rolling
`actions/cache` counter keyed by month. When the ceiling is exceeded the guarded step
**fails the check** before calling Claude, rather than silently spending. The counter
is best-effort (caches can be evicted) — treat it as a guardrail, not an invoice.

## Conventions every workflow follows

- **Least privilege** — an explicit `permissions:` block scoped to what it touches.
- **Concurrency** — superseded runs are cancelled (or serialized, for the fixer).
- **Idempotency** — a hidden marker on a sticky comment; re-runs update in place.
- **Gating** — path/label/event filters so it never fires on everything.
