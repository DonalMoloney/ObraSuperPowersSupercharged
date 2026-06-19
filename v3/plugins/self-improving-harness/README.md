# self-improving-harness (v3 plugin) — **EXPERIMENTAL**

> `status: experimental` · `tier: v3`. Creativity over polish. This plugin is the
> **orchestration shell** for an idea, not a finished product. Read the
> "What's real vs aspirational" section before you trust anything here.

A v3 self-improving agent has three moving parts that already exist as v3 skills:
a way to **measure** itself, a way to **edit** itself, and a **gate** that keeps
only the edits that helped. This plugin doesn't reinvent any of them — it
**packages** them as two slash commands plus a `SCOREBOARD.md` audit trail and a
fail-soft capture hook, so the loop is something you *run* instead of something you
*remember to do by hand*.

## The loop

```
        ┌───────────────────────────────────────────────────────────┐
        ▼                                                           │
  MINE      run the eval suite → N/M (xx%); collect the failing traces
        │
        ▼
  DIAGNOSE  read WHY one task failed (counterfactual), not just THAT it failed
        │
        ▼
  PROPOSE   make exactly ONE harness edit (a CLAUDE.md rule / a skill's text or
        │   description: trigger / a subagent / a routing change) on a branch
        ▼
  GATE      re-run the full suite from a clean state:
        │     score rose vs best-so-far → KEEP   (merge, bump best-so-far)
        │     score did not rise        → REVERT (delete branch) + ARCHIVE the variant
        │
        └──→ append one row to SCOREBOARD.md, then loop ───────────────┘
```

The gate logic — strict `>` against a monotonic best-so-far, archive-don't-delete
the losers, write a falsifiable prediction before editing — is **defined in the v3
skill `eval-gated-evolution-loop`**, not restated here. This plugin only invokes it.

## The fitness signal (named explicitly)

**Fitness = the eval suite's pass count, compared to best-so-far.** A round's edit
is kept iff `new_score > best_so_far` (ties revert, to resist drift). Across a run
the SCOREBOARD's `score after` column should trace a **monotonic climbing curve** —
that curve *is* the evidence the harness is improving. A round where nothing in the
`kept` column ever fires, or where the curve is flat, means the loop is doing
nothing useful. This is the only success metric; do not substitute model self-praise.

## The SCOREBOARD as the climbing-curve audit trail

`SCOREBOARD.md` is the visible record and the emotional payoff: every round appends
one row — `date · iter · what changed · score before · score after · kept/reverted`.
Read top-to-bottom it is the 50%→85% climb (or the honest flat line). It is also the
loop's between-runs memory: best-so-far is whatever the highest `score after` of a
`kept` row is. The capture hook (below) can drop a friction note onto the same trail
mid-session so the next round has a head start on what to diagnose.

## The three referenced skills (NOT vendored)

This plugin references — does not copy — these v3 skills. They are the source of
truth; edit them there, not here.

| Skill | Repo path | Role in the loop |
|-------|-----------|------------------|
| `eval-suite-from-git` | `v3/skills/eval-suite-from-git/` | MINE — mines regression tasks from git bug-fix history and ships `run-evals.sh`, which prints `N/M (xx%)`. The fitness function. |
| `eval-gated-evolution-loop` | `v3/skills/eval-gated-evolution-loop/` | DIAGNOSE → PROPOSE → GATE — the keep-iff-score-rose engine, the one-edit rule, the archive discipline, the falsification ledger. |
| Ralph wrapper / `SCOREBOARD.md` (idea #6 / RP) | `v3/IDEAS.md` (§6, §RP) | The autonomy wrapper + scoreboard concept this plugin operationalizes. The `/loop` mechanism itself comes from the external `ralph-loop` / `/loop` primitive. |

## Human approval stays on anything irreversible (deletes, pushes, external calls)

The loop edits the *harness* — markdown and config — and gates on a deterministic
suite. That is reversible by design (git branches). **Human approval stays mandatory
on anything irreversible: deletes outside the `evo/` branches, pushes, and any
external/network call.** Reverting a losing variant means deleting its throwaway
branch, never touching production data, history outside the evo branches, or remotes.

## Files

```
self-improving-harness/
├── .claude-plugin/plugin.json
├── README.md                  (this file)
├── SCOREBOARD.md              (climbing-curve audit trail; ships with one sample row)
├── commands/
│   ├── harness-score.md       (/harness-score — run the suite, print N/M (xx%))
│   └── harness-run.md         (/harness-run   — one full evolution round)
└── hooks/
    ├── hooks.json             (Stop hook → capture-friction.sh)
    └── capture-friction.sh    (fail-soft: append one note to SCOREBOARD/scratch log)
```

## What's real vs aspirational (be honest — this is v3)

**Real today:**
- The two commands and the hook exist and are wired up.
- The capture hook is fail-soft: it drains stdin, handles missing files, and
  exits 0 on every path, so it can never brick a session.
- `SCOREBOARD.md` ships as a working template with a clearly-marked sample row.

**Aspirational / depends on the referenced skills:**
- `/harness-score` and `/harness-run` assume `eval-suite-from-git` has already been
  run so that `run-evals.sh` and an `evals/` corpus exist. With no suite, there is
  no loop — the commands say so and stop, they do not fabricate a number.
- The keep-or-revert gate, the archive, and the falsification ledger live in
  `eval-gated-evolution-loop`; this plugin orchestrates them but does not enforce
  the reward-hacking guardrails (immutable `evals/`, clean-checkout gate) — those
  are open problems documented in that skill's "Known risks" section.
- The climbing curve is a hypothesis until a real project's SCOREBOARD shows it.

When this stack drives a measured climb on a real repo's mined suite, the path is
to graduate `eval-suite-from-git` and `eval-gated-evolution-loop` to v2 (per their
own graduation criteria), then re-cut this plugin against the graduated skills.
