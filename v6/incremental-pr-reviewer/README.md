# Incremental PR Reviewer

Posts **line-level** review comments on the changes *since its last review* (not the
whole PR every time), plus a sticky summary comment that updates in place. The
last-reviewed SHA is stored in a hidden marker on the sticky comment, so each push
only sends the new delta to Claude.

## Install

Copy into a consuming repo:

| From (this folder) | To (consuming repo) |
|--------------------|---------------------|
| `workflow.yml` | `.github/workflows/pr-review.yml` |
| `scripts/review.mjs` | `.github/workflows/scripts/review.mjs` |
| `scripts/review-schema.json` | `.github/workflows/scripts/review-schema.json` |
| `../_cost-guardrail/` | `.github/actions/cost-guardrail/` |

Then add the `ANTHROPIC_API_KEY` secret. Optional repo variables:
`CLAUDE_REVIEW_MODEL` (default `claude-sonnet-4-6`), `CLAUDE_MONTHLY_CAP_USD`
(default `25`).

## Permissions

```yaml
permissions:
  contents: read
  pull-requests: write
```

## How it works

1. **build** (`review.mjs build`) — finds the sticky comment's `last-sha`, diffs
   `last-sha..head` (or `base..head` on first run), and writes a prompt file. If
   nothing changed since the last review, the job ends without calling Claude.
2. **cost-guardrail** — sends the diff to Claude with `review-schema.json`, returning
   structured findings.
3. **post** (`review.mjs post`) — creates a single review with inline comments, then
   upserts the sticky summary with the new `last-sha`.

## Caveats

- Inline comments must land on lines present in the diff; if GitHub rejects them
  (422), the findings fall back into the sticky summary instead.
- Diffs over ~50,000 characters are truncated before being sent.
- Forked-PR runs receive a read-only `GITHUB_TOKEN` by default — review comments
  won't post. Use this on same-repo PRs, or adopt a `pull_request_target` variant
  with the usual security caveats (do not check out untrusted code with write scope).
- The shared monthly spend ceiling lives in the cost-guardrail (`../_cost-guardrail`).
