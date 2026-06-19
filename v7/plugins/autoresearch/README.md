# autoresearch

A domain-general port of Andrej Karpathy's **AutoResearch** loop: an agent proposes one
change, a harness runs your evaluation, and the change is kept only if your metric improves
— otherwise it's reverted. Repeats unattended until a budget is hit.

**Invariant:** the harness, not the LLM, decides keep vs revert.

## Requirements

Node.js ≥ 18, git, and a shell. (`shellcheck` only needed to develop the plugin.)

## Configure

Create `autoresearch.config.json` in your repo (or run `/autoresearch` to generate it):

\`\`\`json
{
  "objective": "Minimize p95 latency of the search endpoint",
  "artifact": ["src/search/**/*.ts"],
  "eval_cmd": "npm run bench:search",
  "metric": { "type": "regex", "pattern": "p95=([0-9.]+)ms" },
  "direction": "minimize",
  "budget": { "max_iterations": 40, "max_wallclock_min": 480, "per_iter_timeout_sec": 120 },
  "stop_after_no_improve": 8,
  "baseline": null
}
\`\`\`

- `artifact` — globs the proposer may edit; edits outside this set are auto-reverted.
- `eval_cmd` — must exit 0 and print the metric; run only by the harness.
- `metric` — `{ "type": "regex", "pattern": "...(group)..." }` or `{ "type": "json", "path": "a.b.c" }`.

## Run

\`\`\`bash
bash scripts/autoresearch.sh [autoresearch.config.json] [--allow-dirty]
\`\`\`

The run is isolated in a git worktree on branch `autoresearch/<run-id>`. Stop early with
`touch .autoresearch/<run-id>/STOP`. When it finishes it prints how to merge or discard:

\`\`\`bash
git merge autoresearch/<run-id>                 # keep the winning changes
git worktree remove .autoresearch/<run-id>/worktree && git branch -D autoresearch/<run-id>
\`\`\`

Nothing is auto-merged or auto-pushed.

## Provenance

Andrej Karpathy, **AutoResearch**, open-sourced 2026-03-07 — a ~630-line single-file tool
(a stripped-down nanochat training core) in which an agent runs autonomous, time-boxed ML
experiments and keeps a change only if validation loss improves, else `git revert`s.
Karpathy framed it as a public *recipe* to adapt to your own domain. This plugin ports the
transferable core — the measurable keep-or-revert loop — as a domain-general engine.
