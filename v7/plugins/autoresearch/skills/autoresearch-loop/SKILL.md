---
name: autoresearch-loop
description: Use when proposing a single change inside an autoresearch optimization run, or when helping a user configure one. Governs how to read the journal, propose one high-information change, stay in scope, and never eval or commit.
tier: v7
inspiration: "Karpathy — AutoResearch (keep-or-revert agent loop, open-sourced 2026-03-07)"
---

# autoresearch-loop

You are one iteration of a keep-or-revert optimization loop. A bash harness owns the
truth: it runs the evaluation, compares the metric, and commits or reverts. **You only
propose and apply one change.**

## Each iteration

The proposer runs inside an isolated git worktree (branch `autoresearch/<run-id>`) at
`$AR_WORKTREE`, so its edits never touch the user's main working tree.

1. **Read the journal tail** (`AR_JOURNAL`). It is your only memory of prior iterations —
   what was tried, the resulting metric, and whether it was KEPT or REVERTED.
2. **Pick one high-information change** toward the objective. Prefer the change most likely
   to move the metric. Do not repeat anything the journal shows was reverted; build on what
   was kept.
3. **Apply exactly one change** to files matching the artifact globs (`AR_ARTIFACTS`).
   Keep it small and reversible.
4. **Write a one-line rationale** as your final output — it is recorded in the journal.

## Hard rules

- Edit ONLY files in the artifact set. Edits outside it are auto-reverted (wasted iteration).
- Do NOT run the evaluation. Do NOT commit. The harness does both, deterministically.
- One concern per iteration — a large diff is harder to attribute to a metric change.

## Helping a human configure a run

When asked to set up autoresearch, produce a complete `autoresearch.config.json`. All of
these fields are required by the harness validator (`scripts/lib/config.mjs`):

- `objective` — a one-line description of the goal.
- `artifact` — a non-empty array of globs naming the files the proposer may edit; use the
  narrowest set that contains the thing worth changing.
- `eval_cmd` — a command that exits 0 and prints the metric, fast enough to run many times.
- `metric` — an object: `{ "type": "regex", "pattern": "...(capture group)..." }` or
  `{ "type": "json", "path": "a.b.c" }`.
- `direction` — `"minimize"` or `"maximize"`.
- `budget` — an object with three positive numbers: `max_iterations`,
  `max_wallclock_min`, `per_iter_timeout_sec`. Start conservative (e.g. `max_iterations: 10`)
  for the first run.
- Optional: `stop_after_no_improve` (plateau early-stop) and `baseline`.

See the plugin `README.md` for a complete example.

## Provenance

Andrej Karpathy, **AutoResearch**, open-sourced 2026-03-07 — a ~630-line nanochat-derived
tool where an agent runs autonomous, time-boxed ML experiments and keeps a change only if
validation loss improves, else `git revert`s. This skill ports the proposer's discipline
from that loop; the v7 harness ports the judge.

## Boundaries

- The harness, not this skill, enforces accept/reject — see `scripts/autoresearch.sh`.
- Related v4 ideas: `cognitive-prosthetics` (journal = amnesia prosthetic),
  `fast-verify-loop` (fast evaluator), `autonomy-slider` (unattended-in-sandbox autonomy).
