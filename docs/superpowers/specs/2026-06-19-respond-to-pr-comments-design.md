# Design: `respond-to-pr-comments` (v2 skill)

**Date:** 2026-06-19
**Tier:** v2 (supporting skill — new identity, not core obra)
**Supports:** `receiving-code-review`, `requesting-code-review`

## Problem

When a PR gets reviewer comments, there's no skill that *fetches* incoming feedback,
separates genuinely new comments from already-handled ones, and separates real human
reviewers from bots. The v1 `receiving-code-review` skill governs *how to react* to
feedback once you have it — not how to pull it off GitHub, dedupe it across runs, or
filter out Copilot/CI noise. This skill fills that gap and hands the human comments to
the `receiving-code-review` discipline for drafting.

## Decisions (from brainstorming)

| Dimension | Decision |
|---|---|
| Trigger model | One-shot skill, runnable continuously by wrapping with the existing `/loop` skill |
| Response action | **Draft replies for approval** — nothing posts to GitHub automatically; no autonomous code edits |
| New-comment detection | **Local per-PR watermark file**; advances only for comments actually handled (posted or explicitly skipped) |
| Human filter | Real humans only — exclude `user.type == "Bot"`, `[bot]`-suffix logins, an explicit bot denylist (**Copilot**, CodeRabbit, github-actions), and your own login |
| Comment scope | All three GitHub PR comment types: inline review comments, conversation (timeline) comments, review summary bodies |
| Packaging | One v2 skill + one helper script; reuse `/loop` for watching (no dedicated watch command) |
| Internals | **Approach A** — helper script owns deterministic fetch/filter/state; SKILL.md owns triage/draft/approve/post |

## Architecture & layout

```
v2/skills/respond-to-pr-comments/
├── SKILL.md                  # drives triage → draft → approve → post
└── scripts/
    └── pr_comments.sh        # bash + gh + jq: fetch | reply (deterministic parts)
```

Division of labor:
- **Script** answers "*which* comments are new and human" — pure data, deterministic,
  same answer every run, unit-testable.
- **Skill** answers "*what should I say back*" — judgment, routed through
  `receiving-code-review`.

Putting the watermark/filter logic in the script (not prose) prevents per-run
re-derivation drift that would silently re-process or drop comments.

### Frontmatter

```yaml
name: respond-to-pr-comments
description: Use when a PR has new reviewer comments you want to answer — fetches
  new human comments (excluding Copilot/bots/yourself), drafts replies for your
  approval, and posts only what you approve. Run on demand or wrap with /loop to watch.
author: Donal Moloney
tier: v2
supports: [receiving-code-review, requesting-code-review]
type: technique
chains-to: receiving-code-review
pairs-with: loop-until-green
```

## Helper script — `pr_comments.sh`

Two subcommands.

### `fetch [PR]` — emit new human comments as a JSON array

1. Resolve context:
   - owner/repo: `gh repo view --json owner,name`
   - PR number: passed arg, else `gh pr view --json number -q .number` (auto-detect from branch)
   - your login: `gh api user -q .login`
2. Pull all three comment types (paginated with `gh api --paginate`):
   - inline review comments → `GET /repos/{o}/{r}/pulls/{n}/comments`
   - conversation comments → `GET /repos/{o}/{r}/issues/{n}/comments`
   - review summaries → `GET /repos/{o}/{r}/pulls/{n}/reviews` (keep only non-empty `body`)
3. **Human filter** (jq): drop `user.type == "Bot"`; drop logins ending in `[bot]`;
   drop your own login; drop an explicit denylist constant at the top of the script —
   `copilot`, `github-copilot[bot]`, `copilot-pull-request-reviewer[bot]`, `Copilot`,
   `coderabbitai[bot]`, `github-actions[bot]` (easy to extend).
4. **New filter:** drop any `id` already in the watermark's `handled_ids`.
5. Normalize each survivor to:
   `{id, type, author, created_at, body, path?, line?, diff_hunk?, in_reply_to_id?, url}`
   and print as a JSON array.

### `reply <id> <type> <body-file>` — post one approved reply and record it

- inline → `POST /repos/{o}/{r}/pulls/{n}/comments/{id}/replies`
- conversation → `POST /repos/{o}/{r}/issues/{n}/comments`
- review summary → `POST /repos/{o}/{r}/issues/{n}/comments` (@-mention the reviewer;
  GitHub has no "reply to a review" endpoint)
- On success, add `id` to `handled_ids`.
- `--skip <id>` flag: record an id as handled *without* posting (for declined drafts).

### Watermark file

Path: `.git/pr-comment-watermarks/<pr>.json` — inside `.git/`, so per-clone, never
committed, survives branch switches.

Shape:
```json
{ "pr": 123, "last_poll": "2026-06-19T12:00:00Z", "handled_ids": [101, 102] }
```
`handled_ids` is the authoritative dedup; `last_poll` is informational only.

## Skill workflow (SKILL.md)

1. **Preflight** — verify `gh auth status` and that a PR exists for the branch; if not,
   stop and tell the user to pass a PR number explicitly. No partial actions.
2. **Fetch** — run `pr_comments.sh fetch`. If empty → report "No new human comments
   since last check" and stop (clean, quiet no-op — important for the `/loop` case).
3. **Triage** — classify each new comment via `receiving-code-review`
   (question / change-request / nit / praise). For inline comments, include the
   `diff_hunk` and any parent comment as context.
4. **Draft** — write a reply per comment. For change-requests the reply acknowledges +
   states intent and the skill *surfaces the proposed code change* but does **not** edit
   code; implementing is an explicit, separate hand-off to `receiving-code-review`/TDD
   that the user opts into.
5. **Present all drafts together** in the terminal — each tagged with author, type, and
   a link. Per comment the user chooses: **approve / edit / skip / defer**.
6. **Post** — approved/edited → `reply` (advances watermark); skipped → `--skip` (won't
   resurface); deferred → untouched (resurfaces next run).
7. **Summarize** what was posted vs deferred.

## Continuous mode

No new code. Reuse `/loop`: `/loop 5m respond-to-pr-comments`. Each tick re-runs the
skill; the watermark guarantees only genuinely new human comments surface, and the
quiet no-op keeps idle ticks silent. The skill documents this one-liner rather than
owning an interval.

## Error handling & edge cases

- **Not authed / no PR / not a git repo** → explicit message, no partial actions.
- **A new comment that is a reply in a thread** → include the parent for context.
- **Large PRs** → `gh api --paginate` everywhere.
- **Pure-praise comment** → reply optional (offer "skip with no reply").
- **Posting fails** (thread resolved/locked) → report the error, do *not* advance the
  watermark for that id, continue with the rest.

## Testing & verification

- **Unit (script):** fixture-based — feed canned `gh api` JSON and assert the human/new
  set is correct (Copilot + bots + self dropped; second run with a populated watermark
  returns empty). The deterministic core is where tests live.
- **Live verification** (repo requires concrete evidence): run against a real PR that
  has both a Copilot comment and a human comment → returns only the human one; run twice
  → second run returns empty (proves watermark dedup).
- Run `skill-auditor` before committing.

## Out of scope (YAGNI)

- Autonomous code edits / commits from comments (explicit opt-in hand-off only).
- A dedicated `/watch-pr-comments` command (reuse `/loop`).
- Reaction-marker or reply-thread dedup strategies (chose local watermark).
- Cross-machine state sync (watermark is intentionally per-clone).
