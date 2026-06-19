# SCOREBOARD — self-improving-harness climbing curve

The audit trail for the eval-gated evolution loop. `/harness-run` appends **one row
per round**; the capture hook may append a one-line friction/score note between
rounds. Read top-to-bottom, the `score after` column is the fitness curve — it
should climb round-over-round (the only success metric for this plugin).

Columns:
- **date** — ISO date of the round.
- **iter** — round number (`evo/iter-NNN`).
- **what changed** — the ONE harness edit proposed this round.
- **score before** — suite score at MINE (`N/M (xx%)`).
- **score after** — suite score after the edit, re-run from a clean state.
- **kept/reverted** — `kept` iff `score after > best-so-far`, else `reverted` (the
  variant is archived under `evo/archive/`, not deleted).

| date | iter | what changed | score before | score after | kept/reverted |
|------|------|--------------|--------------|-------------|---------------|
| 2026-06-19 | 001 | _SAMPLE ROW — delete me._ Added a CLAUDE.md rule routing "stack trace" phrasing to systematic-debugging | 14/20 (70%) | 15/20 (75%) | kept |

<!--
SAMPLE ROW above is illustrative only — delete it before a real run.
A reverted round looks like this (kept the loser archived, score did not rise):

| 2026-06-19 | 002 | Broadened skill X's description: trigger | 15/20 (75%) | 15/20 (75%) | reverted |

best-so-far = the highest `score after` among `kept` rows. Ties revert (strict >).
-->
