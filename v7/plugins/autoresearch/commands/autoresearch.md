---
description: Configure and launch a Karpathy-style keep-or-revert optimization run.
---

# /autoresearch

Set up and start an autoresearch run in the current repo.

## Steps

1. **Find or create config.** If `autoresearch.config.json` exists, validate it:
   `node ${CLAUDE_PLUGIN_ROOT}/scripts/lib/config.mjs validate autoresearch.config.json`.
   If it does not exist, interview the user for: the editable file globs (`artifact`),
   the command that measures success (`eval_cmd`), how to read the number (`metric`:
   regex capture group or json path), `direction` (minimize/maximize), and a starting
   `budget` (default `{max_iterations:10, max_wallclock_min:120, per_iter_timeout_sec:120}`).
   Write the JSON and validate it.

2. **Confirm safety.** Ensure the working tree is clean (the harness refuses a dirty tree
   unless `--allow-dirty`). Confirm `.autoresearch/` will be git-ignored (the harness adds
   it automatically).

3. **Launch.** Run:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/autoresearch.sh autoresearch.config.json`
   Each iteration spawns a fresh `claude -p`. Edits, evaluation, and accept/revert all
   happen in an isolated worktree on branch `autoresearch/<run-id>`.

4. **Report.** When it finishes, surface the journal path, the baseline → best metric, and
   the printed `git merge` / `git worktree remove` commands. Do not merge or push
   automatically — the user decides.

## Notes

- Stop early: `touch .autoresearch/<run-id>/STOP`.
- The harness owns accept/reject; the proposer only edits files (see the
  `autoresearch-loop` skill).
