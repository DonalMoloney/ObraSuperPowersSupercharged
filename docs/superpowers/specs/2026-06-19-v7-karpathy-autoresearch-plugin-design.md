# v7 — Karpathy AutoResearch as a Claude Code Plugin

**Date:** 2026-06-19
**Status:** Approved design, pre-implementation
**Topic:** New `v7/` tier: ports of notable published AI tools/artifacts as runnable
Claude Code plugins. First inhabitant: a domain-general port of Andrej Karpathy's
**AutoResearch** keep-or-revert optimization loop.

## Summary

Add a seventh tier, `v7/`, to the repo. Where v4 operationalizes Karpathy/Cherny
*ideas* as skills, v7 ports a **specific named published artifact** into a runnable
Claude Code plugin. The first port is **AutoResearch** (Karpathy, open-sourced
2026-03-07): a ~630-line single-file tool — a stripped-down nanochat training core — in
which an AI agent runs autonomous ML experiments via a tight loop: propose a change to a
training script → run a time-boxed experiment → measure validation loss → keep the change
only if the metric improves, else `git revert` → repeat, all night. Karpathy framed it as
*"a public recipe for building agentic research workflows… intended to be given to your own
AI agent and adapted to a target domain,"* not a turnkey tool.

This spec ports the **transferable core** — the measurable keep-or-revert loop — as a
domain-general engine, not an ML-only clone. The loop applies to any objective with: one
editable artifact set, one measurable metric, a time-boxed evaluator, and git as the
accept/reject mechanism (test pass-rate, benchmark runtime, bundle size, eval score, or
val loss).

The defining invariant, preserved from the original: **the agent proposes, the harness
judges.** The agent only *applies* a change; a bash harness — not the LLM — runs the eval,
compares the metric, and mechanically commits or reverts. The agent cannot rationalize
keeping a regression.

### Decisions locked during brainstorming

| Decision | Choice |
|---|---|
| Scope | Domain-general keep-or-revert optimization loop (not an ML-only port) |
| Execution | Headless harness drives fresh `claude -p` proposers; harness owns accept/reject |
| Safety | Isolated git worktree + hard caps + per-commit audit trail |
| Build size | Engine + `/autoresearch` command + proposer skill + one deterministic example |

## Tier definition (proposed CLAUDE.md row)

The row below is **proposed**. Per the v6 precedent, it is committed to the repo
`CLAUDE.md` only if the user wants it; decide at build time.

> **`v7/`** — Ports of notable published AI tools/artifacts as runnable Claude Code
> plugins (starting with Karpathy's). Each port = `v7/plugins/<name>/`: an installable
> plugin (`.claude-plugin/plugin.json` + `commands/` + `skills/` + `scripts/`, optional
> `hooks/`) that operationalizes a *specific named artifact*, not a distilled idea (that
> is v4). Every v7 plugin MUST: (1) name the source artifact + release date in a
> `## Provenance` section and the skill's `inspiration:` frontmatter; (2) preserve the
> source's core invariant (for autoresearch: the harness — not the LLM — owns
> accept/reject); (3) be runnable out of the box via a deterministic example; (4) carry
> `tier: v7` on its skill(s). `skill-auditor` applies to the skill(s); shell harnesses
> must be `shellcheck`-clean.

## Folder layout

```
v7/
├── README.md                              # tier intro + the v7 discipline contract
└── plugins/
    └── autoresearch/
        ├── .claude-plugin/plugin.json     # manifest (Claude Code plugin conventions)
        ├── README.md                      # install, config, launch, how to merge results
        ├── commands/
        │   └── autoresearch.md            # /autoresearch — interview→config→worktree→launch
        ├── skills/
        │   └── autoresearch-loop/
        │       └── SKILL.md               # proposer discipline + journal protocol
        ├── scripts/
        │   ├── autoresearch.sh            # the harness (the engine)
        │   └── lib/                        # metric-parse, worktree-setup, budget helpers
        └── examples/
            └── hillclimb/                  # deterministic toy: 1 file + eval emitting metric=<n>
```

This mirrors the existing repo plugin convention (`vN/plugins/<name>/` with
`.claude-plugin/plugin.json`, `commands/`, `skills/<name>/SKILL.md`, `scripts/`), as used
by `v2/plugins/*` and `v4/plugins/autonomy-control`.

## Architecture — the core split

The design rests on one invariant from the original: **the agent proposes, the harness
judges.**

```
┌─────────────────────── autoresearch.sh (bash harness) ───────────────────────┐
│  owns: worktree, baseline, the loop, eval execution, metric compare,          │
│        git accept/revert, the journal, budget caps, STOP-file kill switch     │
│                                                                               │
│   each iteration:                                                             │
│     1. read journal (prior attempts) ──┐                                      │
│     2. spawn FRESH `claude -p` ────────┴──► proposer applies ONE change       │
│                                             to the artifact (no eval, no git) │
│     3. harness runs eval_cmd (timeboxed) ──► parse metric                     │
│     4. better? ── yes ─► git commit (metric in msg), journal "kept"           │
│              └── no/err/timeout ─► git checkout -- . , journal "reverted"     │
│     5. budget check ─► loop or stop                                           │
└───────────────────────────────────────────────────────────────────────────────┘
```

Rationale:

- **Fresh `claude -p` per iteration** — no context rot. The proposer's only memory across
  iterations is the journal (see below). Matches Karpathy's context-window-as-RAM
  discipline and the v4 `cognitive-prosthetics` "amnesia → durable notes" prosthetic.
- **Harness owns eval + compare + git** — the keep-or-revert decision is mechanical, not
  a model judgment. Matches Cherny's hooks/harness-as-enforcement principle.

## Component designs

### `autoresearch.sh` — the harness (the engine)

A bash script that owns the entire loop. Responsibilities: worktree setup, baseline
measurement, prompt composition, spawning the proposer, eval execution, metric parsing,
scope enforcement, git accept/revert, the journal, budget accounting, teardown. Detailed
mechanics in "The loop" below. Must be `shellcheck`-clean. JSON parsing via Node (or
`jq`) — same "preinstalled, no toolchain" reasoning as the v6 spec.

### `/autoresearch` — the command

Configures and launches a run. Either reads an existing `autoresearch.config.json` or
interviews the user to write one (which file(s) may be edited, which command measures
success, how to read the number, minimize/maximize, budget). After the config exists, it
sets up the worktree and launches `autoresearch.sh`. One-time setup; subsequent runs reuse
the config.

### `autoresearch-loop` — the proposer skill

Guides each fresh `claude -p` invocation. Carries `tier: v7`, an `inspiration:` line
naming Karpathy AutoResearch, and a `## Provenance` section. Instructs the proposer to:

- Read the recent journal tail before proposing; never re-try a reverted idea; build on
  kept ones.
- Propose and apply **exactly one** high-information-gain change to the artifact set.
- Stay strictly inside the artifact set (edits outside it are auto-reverted by the
  harness).
- **Never** run the eval and **never** commit — those belong to the harness.
- Write a one-line rationale for the change (recorded in the journal).

Also covers the in-session case: when a human asks for help setting up a run, how to write
a good config.

### `examples/hillclimb` — the deterministic example

A dependency-free toy that proves the loop end-to-end and serves as the out-of-the-box
demo: `artifact` is a single file with a numeric knob; `eval_cmd` prints
`metric=abs(value-target)`; `direction: minimize`. A real run must show the best metric
strictly improving toward the target with only improving commits in history.

## The config contract (`autoresearch.config.json`, in the target repo)

The config is what turns Karpathy's single hardcoded ML loop into a general engine: it
lifts the two ML-specific assumptions ("artifact = training script", "metric = val loss")
into declarative fields.

```json
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
```

| Field | Meaning |
|---|---|
| `objective` | Human-readable goal, injected into every proposer prompt |
| `artifact` | Glob(s) the proposer may edit. **Edits outside this set are auto-reverted.** |
| `eval_cmd` | Time-boxed evaluation; must exit 0 and emit the metric. **Run only by the harness.** |
| `metric` | Extraction mode: `regex` (capture group) or `json` (path into eval's JSON output) |
| `direction` | `minimize` \| `maximize` |
| `budget` | Hard caps: `max_iterations`, `max_wallclock_min`, `per_iter_timeout_sec` |
| `stop_after_no_improve` | Early-stop after N consecutive reverts (plateau detection) |
| `baseline` | Optional known baseline; otherwise measured once at start |

## The loop (`autoresearch.sh`)

**Preflight:**

1. Require a clean git tree (`--allow-dirty` to override), so experiments never entangle
   with uncommitted work.
2. Validate the config (required fields present; `eval_cmd` resolvable).
3. Create an isolated worktree:
   `git worktree add ../.autoresearch/<run-id> -b autoresearch/<run-id>`. All edits and
   commits happen there; the user's working tree is untouched.
4. Measure the **baseline**: run `eval_cmd` once on the unchanged artifact → parse metric
   → record as `best`. If `baseline` is given in config, verify it once.
5. Initialize the journal with run metadata.

**Each iteration** (while iterations < `max_iterations` AND wall-clock <
`max_wallclock_min` AND no `STOP` file AND no-improve-streak < `stop_after_no_improve`):

1. Compose the proposer prompt = `objective` + artifact paths + current `best` +
   `direction` + the **journal tail** + the `autoresearch-loop` skill rules.
2. Spawn a fresh `claude -p` with working dir = worktree and an edit allowlist for the
   artifact set → it applies one change (no eval, no commit).
3. **Scope guard:** `git diff --name-only`; if anything outside `artifact` was touched →
   revert, journal "out-of-scope", next iteration.
4. Run `timeout <per_iter_timeout_sec> eval_cmd`; capture stdout + exit code.
5. Parse the metric. If eval failed / timed out / metric unparseable → treat as
   no-improvement.
6. Compare the new metric to `best` per `direction`:
   - **Improved** → `git add -A && git commit` (metric in the message) → update `best`,
     reset the no-improve streak, journal **KEPT**.
   - **Not improved** → `git checkout -- . && git clean -fd` → no-improve streak++,
     journal **REVERTED**.
7. Budget accounting: iterations++, check wall-clock, check the `STOP` file.

**Teardown:** write a summary (baseline → best, total iterations, kept count, wall-clock,
cumulative diff `baseline..HEAD`) to the journal and stdout; leave the branch/worktree for
inspection; print the exact merge (`git merge autoresearch/<run-id>`) or discard
(`git worktree remove …`) commands. Nothing is auto-merged or auto-pushed.

## The journal (`autoresearch/journal.md`)

The journal is both the audit trail and the proposer's only cross-iteration memory.
Markdown, so it is human-readable and cheap to append/tail.

```markdown
# autoresearch run 20260619-0231
objective: Minimize p95 latency …   direction: minimize   baseline: 142.0   budget: 40 iters / 480 min

## iter 1 — KEPT  Δ -8.0  (142.0 → 134.0)
change: memoized the tokenizer in src/search/index.ts        commit: a1b2c3d

## iter 2 — REVERTED  (137.5 vs best 134.0)
change: switched Map→object for the cache; slower            reason: metric worse

## iter 3 — REVERTED  (out-of-scope)
change: edited src/db/pool.ts (outside artifact set)
```

Each entry: iteration #, KEPT/REVERTED, metric delta, the proposer's one-line rationale,
and the commit SHA when kept. The fresh proposer reads the recent tail so it will not
re-try reverted ideas and can build on kept ones.

## Safety & budget — concrete mechanisms

1. **Worktree isolation** — all edits/commits on `autoresearch/<run-id>`; the user's
   working tree is never touched; **nothing is auto-merged or auto-pushed**.
2. **Clean-tree precondition** — refuse to start on a dirty tree unless `--allow-dirty`.
3. **Three hard caps** — `max_iterations` (primary budget ≈ cost proxy), `max_wallclock_min`
   (the "all night" bound), `per_iter_timeout_sec` (a hung eval = no-improvement → revert).
   Plus `stop_after_no_improve` plateau early-stop.
4. **STOP-file kill switch** — `touch autoresearch/STOP` → graceful stop after the current
   iteration, with the summary written.
5. **Scoped proposer permissions + post-hoc scope guard** — the allowlist prevents
   out-of-scope edits; the diff-scope check catches and reverts anything that slips
   through. Defense in depth.
6. **Full audit trail** — every accept is its own commit (metric in the message); the
   journal logs every attempt (kept / reverted / out-of-scope / eval-failed).

This is the autonomy-slider shape: high autonomy *inside* the sandbox, human gate at the
boundary.

## Provenance

- **Source artifact:** Andrej Karpathy, **AutoResearch**, open-sourced 2026-03-07 — a
  ~630-line single-file Python tool derived from the nanochat training core; an AI agent
  runs autonomous, time-boxed ML experiments and keeps a change only if validation loss
  improves, else `git revert`s. Karpathy framed it as a public *recipe* to adapt to your
  own domain, not a turnkey tool.
- **What this port operationalizes:** the transferable core — the measurable keep-or-revert
  loop with the agent-proposes/harness-judges split — as a domain-general Claude Code
  plugin.

## Cross-cutting decisions

- **Harness in bash; JSON config parsed via Node/`jq`** — no extra toolchain, matching the
  v6 spec's reasoning.
- **Fresh context per iteration** — the journal, not the conversation, is the proposer's
  memory.
- **Harness owns accept/reject** — the source's load-bearing invariant; preserved exactly.
- **No auto-merge / no auto-push** — terminal state hands control back to the human.
- **Iteration cap is the enforceable budget** — a dollar cap is deferred (YAGNI); per-run
  token usage is logged if `claude -p` reports it.

## Out of scope (this batch)

- Domain presets beyond the `hillclimb` example (e.g., test-runtime, bundle-size, ML
  training presets). Documented as extensions; not built now.
- A dollar-denominated cost cap (iteration + wall-clock caps suffice for cut one).
- Parallel/multi-armed experimentation (multiple proposers exploring concurrently).
- Auto-merge of the winning branch.

## Verification

- **Mock-proposer invariant test (no LLM, deterministic):** swap the proposer for a stub
  that makes a known-good edit, then a known-bad edit, then an out-of-scope edit. Assert:
  good → committed; bad → reverted + tree clean; out-of-scope → reverted. This proves the
  keep-or-revert judge without burning LLM calls — the most important test.
- **`examples/hillclimb` end-to-end run:** baseline recorded → best metric strictly
  improves vs baseline → only improving commits in history → journal shows kept/reverted
  entries.
- **Static checks:** `shellcheck scripts/autoresearch.sh` clean; config validation rejects
  malformed configs with a clear error.
- **Tooling gates:** `skill-auditor` on `autoresearch-loop/SKILL.md`; `plugin-validator`
  on the plugin structure.
