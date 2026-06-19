# Self-Healing CI Triage

When a watched workflow fails, this reads the failing run's logs and posts a
**root-cause + suggested-fix** diagnosis on the associated PR (or, if there is none,
as a commit comment). Re-runs of the same failing commit update one sticky comment.

## Install

| From (this folder) | To (consuming repo) |
|--------------------|---------------------|
| `workflow.yml` | `.github/workflows/ci-triage.yml` |
| `scripts/diagnose.mjs` | `.github/workflows/scripts/diagnose.mjs` |
| `../_cost-guardrail/` | `.github/actions/cost-guardrail/` |

**Required edit:** set `workflows: ["CI"]` in `workflow.yml` to the exact `name:` of
the workflow(s) you want triaged — `workflow_run` does not accept wildcards.

Add the `ANTHROPIC_API_KEY` secret. Optional variables: `CLAUDE_TRIAGE_MODEL`
(default `claude-sonnet-4-6`), `CLAUDE_MONTHLY_CAP_USD` (default `25`).

## Permissions

```yaml
permissions:
  contents: read
  actions: read
  pull-requests: write
```

## How it works

1. **build** (`diagnose.mjs build`) — `gh run view --log-failed` for the failing run,
   tails it to ~16,000 chars, and writes a prompt with the workflow/branch/commit
   context.
2. **cost-guardrail** — sends it to Claude for a structured diagnosis.
3. **post** (`diagnose.mjs post`) — upserts a sticky comment on the PR, keyed by
   workflow + failing commit. Falls back to a commit comment when no PR exists.

## Caveats

- `workflow_run` runs in the context of the **default branch's** copy of this file —
  changes only take effect once merged to the default branch.
- It diagnoses; it does not push fixes. (Auto-fixing failed builds is the
  `autonomous-issue-fixer`'s job, gated behind explicit human authorization.)
- Logs are tailed, so the root cause must appear near the end of the failing step's
  output. Very large multi-job failures may need a bigger `max-tokens`.
