---
description: Run ONE eval-gated evolution round — score, diagnose a failing task, propose one harness edit, re-run, keep-or-revert, and append a row to SCOREBOARD.md
---

Drive exactly **one** round of the self-improving loop and record it. The
keep-or-revert **gate logic is defined in the v3 skill `eval-gated-evolution-loop`**
(`v3/skills/eval-gated-evolution-loop/`) — follow it there; this command does not
restate the rules, it sequences them and writes the audit trail.

Preconditions: `run-evals.sh` + `evals/` exist (built by `eval-suite-from-git`,
`v3/skills/eval-suite-from-git/`). If not, stop and tell the user to mine the suite
first — there is no loop without a fitness function.

## The one round

1. **MINE.** Run `/harness-score` (or `./run-evals.sh`) to get the baseline
   `N/M (xx%)`. This is **score before**. Set best-so-far = the highest `kept`
   `score after` in `${CLAUDE_PLUGIN_ROOT}/SCOREBOARD.md` (or this baseline if the
   board has no kept rows yet). Collect the failing tasks; compress each failing
   trace to a short sourced summary so the diagnosis fits in context.

2. **DIAGNOSE.** Pick **one** failing task. Read *why* it failed counterfactually —
   the missing trigger, the wrong routing, the absent skill — per the DIAGNOSE step
   of `eval-gated-evolution-loop`. Write the diagnosis as a falsifiable prediction
   ("this edit flips `task-007`") *before* editing anything.

3. **PROPOSE one edit.** Make exactly **one** targeted harness edit on a fresh
   branch (`evo/iter-NNN`): a `CLAUDE.md` rule, a skill's text or its `description:`
   trigger, a `.claude/agents/` subagent, or a routing change. One edit per round is
   non-negotiable — it is what makes the gate attributable. Do **not** edit `evals/`
   or `run-evals.sh` (that is reward-hacking the gate).

4. **GATE.** Re-run the full suite from a clean state to get **score after**, then
   apply the gate from `eval-gated-evolution-loop`:
   - **score after > best-so-far** → **KEEP**: merge the branch, bump best-so-far,
     mark the prediction CONFIRMED/FALSIFIED in the ledger.
   - **score after ≤ best-so-far** → **REVERT**: delete the `evo/iter-NNN` branch and
     **archive** the variant (diff + diagnosis) under `evo/archive/`. Reverting only
     ever deletes the throwaway branch — never production data, history, or remotes.

5. **RECORD.** Append exactly one row to `${CLAUDE_PLUGIN_ROOT}/SCOREBOARD.md`:
   `| <date> | <iter> | <what changed> | <score before> | <score after> | kept | `
   (or `reverted`). This row is the climbing-curve audit trail; the SCOREBOARD's
   `score after` column over time is the fitness signal — it should trend up.

## Human approval gate

`/harness-run` evolves the **harness** (markdown + config) on disposable branches —
reversible by design. **Pause for explicit human approval before anything
irreversible: pushes, deletes outside the `evo/` branches, or external/network
calls.** If a round would require one of those, stop and ask; do not proceed
autonomously.

> For overnight autonomy, wrap repeated `/harness-run` rounds in the external
> `ralph-loop` / `/loop` primitive (idea #6 / RP in `v3/IDEAS.md`). The exit
> condition is a token/iteration budget, not a green suite — the suite is never
> expected to hit 100%.
