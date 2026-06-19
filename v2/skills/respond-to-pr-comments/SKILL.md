---
name: respond-to-pr-comments
description: Use when a PR has new reviewer comments you want to answer — fetches new human comments (excluding Copilot/bots/yourself), drafts replies for your approval, and posts only what you approve. Run on demand or wrap with /loop to watch.
author: Donal Moloney
tier: v2
supports: [receiving-code-review, requesting-code-review]
type: technique
chains-to: receiving-code-review
pairs-with: loop-until-green
---

## Not this skill if

- You already have the feedback in hand and just need to act on it — use `receiving-code-review` directly.
- You want to *request* a review — use `requesting-code-review` / `reviewer-lenses`.
- You want to auto-implement changes from comments without a human gate — out of scope; this skill drafts and posts replies only.

## Overview

Pull *new* *human* comments off a PR, draft replies, and post only what the user approves. The deterministic work (which comments are new and human) lives in `scripts/pr_comments.sh`; this skill owns the judgment (what to say back).

**Core principle:** nothing reaches GitHub without explicit approval. The watermark advances only for comments actually handled.

## Workflow

1. **Preflight.** Run `gh auth status`. Confirm a PR exists for the branch (`gh pr view --json number`). If unauthenticated or no PR, stop and ask the user to authenticate or pass a PR number — take no other action.

2. **Fetch new human comments:**

   ```bash
   bash scripts/pr_comments.sh fetch          # auto-detects PR from branch
   bash scripts/pr_comments.sh fetch 123      # explicit PR
   ```

   Output is a JSON array of `{id, type, author, created_at, body, url, path, line, diff_hunk, in_reply_to_id}`. If it is `[]`, report **"No new human comments since last check."** and stop. (This quiet no-op is what makes watch mode unobtrusive.)

3. **Triage** each comment using `receiving-code-review`: classify as question / change-request / nit / praise. For `inline` comments, read `path`, `line`, and `diff_hunk` for context; if `in_reply_to_id` is set, treat it as a reply within a thread and fetch the parent for context.

4. **Draft** one reply per comment. For change-requests, the reply acknowledges and states intent, and you *surface the proposed code change* — but do **not** edit code here. Implementing a change is a separate, explicit hand-off the user opts into (then follow `receiving-code-review` / TDD).

5. **Present all drafts together**, each tagged with author, type, and `url`. For each, the user chooses:
   - **approve** — post as drafted
   - **edit** — user revises, then post
   - **skip** — don't reply, but mark handled (won't resurface)
   - **defer** — leave untouched (resurfaces next run)

6. **Post** approved/edited replies, then record them:

   ```bash
   printf '%s' "$REPLY_BODY" > /tmp/reply.txt
   bash scripts/pr_comments.sh reply <id> <type> /tmp/reply.txt   # posts + records
   bash scripts/pr_comments.sh skip  <id>                         # mark handled, no post
   ```

   `<type>` is the comment's `type` field (`inline` | `conversation` | `review`). If a post fails (e.g. resolved/locked thread), report the error and do **not** mark that id handled; continue with the rest.

7. **Summarize** what was posted vs deferred.

## Watch mode

No extra machinery — wrap this skill with the existing `/loop` skill:

```
/loop 5m respond-to-pr-comments
```

Each tick re-runs the workflow; the watermark guarantees only genuinely new human comments surface, and the step-2 no-op keeps idle ticks silent.

## Human filter

`fetch` keeps a comment only if the author is a real person other than you: it drops `user.type == "Bot"`, `[bot]`-suffix logins, your own login, and an explicit denylist (`copilot`, `github-copilot[bot]`, `copilot-pull-request-reviewer[bot]`, `coderabbitai[bot]`, `github-actions[bot]`). Extend the denylist by editing `DENYLIST_JSON` at the top of the script.

## State & scope notes

- **Watermark:** per-PR file at `${PR_WATERMARK_DIR:-$(git rev-parse --git-dir)/pr-comment-watermarks}/<pr>.json` — local to the clone, never committed. `handled_ids` is the authoritative dedup set.
- **`--paginate`:** `fetch` slurps and merges all pages (`jq -s 'add | ...'`), so PRs with many comments are handled correctly.
- **Reply routing:** inline → the review thread (`/pulls/<pr>/comments/<id>/replies`); conversation and review-summary → a timeline comment (`/issues/<pr>/comments`), since GitHub has no "reply to a review" endpoint.

## Verification

- Run the unit suite: `bash tests/run_tests.sh` → `failed=0`. Covers the human filter (Copilot/bots/self dropped), handled-id dedup, output shape, paginated multi-page merge, full `fetch` across all three comment types, and `reply`/`skip` watermark recording (all via fixtures + a fake `gh`).
- Live check: run `fetch` against a real PR that has both a Copilot comment and a human comment → only the human appears; run again → `[]` (watermark dedup).
