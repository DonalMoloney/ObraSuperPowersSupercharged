---
description: Run the v3 eval suite once and print the current fitness score as N/M (xx%) — the number the evolution loop optimizes
---

Report the harness's current fitness: the pass count on the eval suite mined by v3
`eval-suite-from-git` (`v3/skills/eval-suite-from-git/`). This is a **read-only
measurement** — it never edits the harness.

1. **Locate the suite.** The runner is `run-evals.sh` and the corpus is `evals/`,
   both produced by `eval-suite-from-git`. Look in the project root
   (`${CLAUDE_PROJECT_DIR:-$PWD}`) for `run-evals.sh`.
   - If it does not exist, **stop and say so**: the cold-start step is missing. Run
     the miner from `eval-suite-from-git` first to build `evals/` + `run-evals.sh`,
     then re-run `/harness-score`. Do **not** invent or estimate a score — no suite,
     no number.

2. **Run it.** Execute the suite runner from the project root:
   ```bash
   ./run-evals.sh
   ```
   It resets each task to its reproduced-bug state, runs every task's `check.sh`,
   and prints the score.

3. **Print the score verbatim** in the form `N/M (xx%)` — passes over total, with
   the percentage. If the runner emits per-task results, also list which task IDs
   failed (`task-007`, `task-012`, …); those are the candidates `/harness-run` will
   diagnose.

4. **State whether this is a new best.** Compare against the highest `score after`
   of any `kept` row in this plugin's `SCOREBOARD.md`
   (`${CLAUDE_PLUGIN_ROOT}/SCOREBOARD.md`). Report it as e.g.
   `14/20 (70%) — matches best-so-far` or `15/20 (75%) — NEW best-so-far`.
   `/harness-score` only **reports**; it does not write the SCOREBOARD (that is
   `/harness-run`'s job, tied to an actual kept/reverted edit).

> Boundary: this command is the MINE step's measurement only. To act on the failing
> tasks — diagnose, propose one edit, gate, and record the result — run
> `/harness-run`.
