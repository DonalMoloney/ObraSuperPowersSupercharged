# v3 Idea Candidates — Self-improving harness

**Date:** 2026-06-13
**Status:** Candidate list for selection — nothing here is committed to build yet.
**Source:** `/Users/donalmoloney/PycharmProjects/SelfImprovingAgent/TOPIDEAS.md` (the
ranked shortlist on top of that project's five research docs). `SelfImprovingAgent`
is a designated v3/v4 idea source per the root `CLAUDE.md`.
**Rule reminder (v3 README):** any built skill needs `tier: v3` + `status: experimental`
frontmatter and a short "Why this might be crazy enough to work" section. Graduating an
idea means rewriting it to v2 standards and moving it to `v2/`.

> **The one rule that governs everything (from TOPIDEAS):** self-improvement only works
> where outcomes are **verifiable**. Every idea below names its **fitness signal**. If an
> idea can't name one, it doesn't belong on this list. Build **#1 first** — without the
> eval suite, the rest is vibes.

These nine form one coherent theme — a **self-improving harness with eval-gated
evolution** — adjacent to but distinct from v3's existing *self-improving* (`skill-darwin`,
`skill-cannibal`, `skill-scar-tissue`) and *memory & learning* (`belief-ledger`,
`project-hippocampus`, `inherited-instincts`) clusters. The boundary blocks below say
exactly where each idea extends an existing skill vs. carves a new lane.

---

## The shortlist (ranked by leverage)

| # | Build | Fitness signal | Effort | Existing v3 overlap |
|---|---|---|---|---|
| 1 | **Eval suite mined from git history** | Each task ships a passing/failing test pulled from a real past commit | M | NEW (adjacent to `branch-historian`) |
| 2 | **Eval-gated evolution loop** (mine→diagnose→propose→gate) | Eval score rose vs. best-so-far, else revert | M | NEW — the engine |
| 3 | **Falsification ledger** (`DECISIONS.md`) | The predicted task actually flipped (CONFIRMED/FALSIFIED) | S | **OVERLAP → extend `belief-ledger`** |
| 4 | **8-component git-tracked harness** | Each component diffed on its own branch vs. the suite | M | NEW (a map across CC primitives) |
| 5 | **Two-speed loop** (cheap capture + gated overnight) | Fast: none (collection); slow: suite + ledger | M | NEW (adjacent to `inherited-instincts`) |
| 6 | **Ralph wrapper + `SCOREBOARD.md`** | Same as #2; scoreboard is the audit trail | S | NEW (`ralph-loop` exists only as an external plugin) |
| 7 | **Delta-memory** (ACE playbook, not rewrite) | Playbook entries carry a task ID; un-retriggered entries pruned | M | **OVERLAP → reference `project-hippocampus`** |
| 8 | **Evolve on Haiku, deploy on Opus** | Held-out eval slice re-run on Opus confirms transfer | S | NEW |
| 9 | **Skill Darwinism** (archive + auto-prune) | A/B delta on the suite; keep only if it lifts the score | M | **OVERLAP → reference `skill-darwin` + `skill-cannibal`** |

Anything not on this list (SuperClaude config layers, agent-farm scale-out, MCP memory
backends) is **deferred until the loop in #1–#6 demonstrably climbs a score.** Tooling
before a fitness function is premature.

---

## The skeleton (#1 → #2 → #6 is the whole thing)

```
1. MINE     run the eval suite → collect traces where the agent failed
2. DIAGNOSE read WHY from the trace (counterfactual), not just THAT it failed
3. PROPOSE  one targeted edit to the harness (CLAUDE.md rule / skill / subagent / routing)
4. GATE     re-run evals → keep only if score rose → else revert → archive the variant
        ↑________________________________________________________________|
                  (Ralph/`/loop` overnight; git history = memory between runs)
```

Everything else is a discipline (#3), a decomposition (#4), or an efficiency
(#5, #7, #8, #9) bolted onto this loop. Build the skeleton first.

---

## Detail per idea

### 1. Eval suite mined from git history — *build this first*
A script walks `.git` for bug-fix / reverted commits, reconstructs each pre-fix state as
a task, and uses the fix's own test as `check.sh`. Newly-fixed bugs auto-promote into the
suite — sourced from *your* real failures, not hand-written.
- **Layout:** `evals/task-NNN/{prompt.md,check.sh}` + `run-evals.sh` → prints `14/20 (70%)`.
- **Fitness:** built in — every task already carries a passing/failing test from history.
- **Boundary:** `branch-historian` (v3) also walks git history, but to *spike roads not
  taken* and return a regret report — it does not build a scored, repeatable test suite.
  This is a new lane; it could later feed `branch-historian` candidate tasks.
- *Source: TOPIDEAS §1 (`harness-research.md` B4; `make-it-epic.md` §1).*

### 2. Eval-gated evolution loop — *the engine*
A runner scores the suite, feeds failing traces to Claude Code, asks for **one** targeted
harness edit, applies it on a branch, re-runs, and **keeps it only if the score rose** —
else reverts and **archives the variant** (Darwin-style population, not greedy
hill-climbing). Use **GEPA** as the edit-proposal engine: reflect on natural-language
feedback, maintain a Pareto front; ~20–100 evals per round.
- **Fitness:** eval score vs. best-so-far.
- **Boundary:** `skill-darwin` (v3) evolves a single *skill's text* via competing variant
  phrasings; this evolves the *whole harness* (CLAUDE.md / skills / subagents / routing)
  against the #1 suite. #2 is the superset engine; `skill-darwin` is one mutation operator
  inside it. #9 (Skill Darwinism) is the skill-scoped instance of this same gate.
- *Source: TOPIDEAS §2 (`make-it-epic.md` §2; `harness-research.md` A2/A3 — GEPA, archive).*

### 3. Falsification ledger (`DECISIONS.md`) — *the differentiator*
Every proposed edit writes a row **before** it's tested:
`| iter | component | failing task targeted | root cause | edit | PREDICTED: flips task-007 |`.
The **next** iteration's first job is to check the prediction and mark
`CONFIRMED`/`FALSIFIED`. Falsified edits revert *and* the agent is told its diagnosis was
wrong — sharpening the next one.
- **Fitness:** the flip itself.
- **Boundary — OVERLAP with `belief-ledger` (v3).** `belief-ledger` already tracks
  load-bearing assumptions as probabilities and audits decisions when a belief collapses.
  #3 is the *edit-prediction* specialization: a prediction per harness edit, resolved
  CONFIRMED/FALSIFIED next iteration. **Do not build a parallel ledger** — extend
  `belief-ledger` with an edit-prediction row type, or build #3 as a thin caller of it.
- *Source: TOPIDEAS §3 (`harness-research.md` B2/A2 — AHE decision observability).*

### 4. 8-component git-tracked harness
Decompose the scaffold and map each part to a real CC primitive so each is independently
evolvable and revertible (AHE showed this is what gives cross-model transfer):

| Component | CC home | | Component | CC home |
|---|---|---|---|---|
| System prompt | `CLAUDE.md` | | Middleware | hooks (`Pre/PostToolUse`, `Stop`) |
| Agent config | `.claude/settings.json` | | Skills | `.claude/skills/` |
| Tool descriptions | skill/agent `description:` | | Sub-agents | `.claude/agents/` |
| Tool implementations | `.claude/skills/*/scripts/` | | Long-term memory | `MEMORY.md` + `agent-memory/` |

- **Fitness:** each component diffed on its own branch against the suite.
- **Boundary:** this is a *map / reference*, not a single behavioral skill — likely a v3
  reference doc the loop (#2) consults to know which layer it's mutating. Note it overlaps
  the v4 Karpathy "LLM-as-OS" framing (`v4/IDEAS.md` K3 context-paging cites the same
  analogy); keep #4 about *harness decomposition for evolution*, not context budgeting.
- *Source: TOPIDEAS §4 (`harness-research.md` B1).*

### 5. Two-speed loop
- **Fast (in-session, free):** a background **Haiku** observer captures friction signals to
  a scratch queue — no gate, no main-thread tokens.
- **Slow (overnight, gated):** Ralph/`/loop` drains the queue, turns candidates into edits,
  runs the suite (#1), gates via the ledger (#3), commits.
- **Fitness:** fast = none (collection only); slow = suite + ledger.
- **Boundary:** `inherited-instincts` (v3) is a *cross-project* reflex genome surfaced as
  gut feelings; #5's fast loop is a *within-session* friction capture feeding *this* repo's
  overnight evolution. Complementary — the fast queue could become an instinct source.
- *Source: TOPIDEAS §5 (`harness-research.md` B5; `self-improving-claude-code-ways.md` §3).*

### 6. Ralph wrapper + `SCOREBOARD.md`
Wrap the loop in `while true` / `/loop`, commit each kept improvement, and log every
iteration to `SCOREBOARD.md` (date · what changed · score before/after · kept-or-reverted).
The 50%→85% climbing curve is the emotional payoff and the audit trail. Human approval stays
on anything irreversible (deletes, pushes, external calls).
- **Fitness:** same as #2; the scoreboard is the visible record.
- **Boundary:** the external `ralph-loop` plugin and the `/loop` skill provide the
  autonomy mechanism; #6 is the *self-improvement wrapper + scoreboard* on top of it, not a
  re-implementation of the loop primitive.
- *Source: TOPIDEAS §6 (`make-it-epic.md` §3; `ideas.md` — Ralph).*

### 7. Delta-memory (ACE playbook)
Replace wholesale CLAUDE.md auto-rewrite (which erodes detail over iterations) with the
**Generator → Reflector → Curator** triad: the main session generates traces, a Stop-hook
subagent reflects lessons, a curator merges them as **append-only structured deltas** into a
`playbook/` dir with periodic compaction.
- **Fitness:** entries carry the task ID that justified them; un-retriggered entries pruned.
- **Boundary — OVERLAP with `project-hippocampus` (v3).** Both fight context collapse via
  consolidated, decaying memory. `project-hippocampus` does *episodic* session memories with
  an Ebbinghaus forgetting curve replayed as a briefing; ACE does *append-only structured
  deltas* with usage-based pruning. **Reference, don't duplicate** — frame #7 as the
  playbook/curator variant and cite `project-hippocampus` for the forgetting-curve mechanics.
- *Source: TOPIDEAS §7 (`harness-research.md` B3 — ACE).*

### 8. Evolve on Haiku, deploy on Opus
Run the *entire* evolution loop with **Haiku** under test (cheap, fast rollouts), freeze the
winning harness, deploy it driving **Opus** for real work. AHE's frozen harness transferred
across models; Harness-Bench shows the gains are partly model-portable.
- **Fitness:** re-run a held-out eval slice on Opus before trusting the frozen harness.
- **Boundary:** new lane — no v3 skill addresses cross-model evolve/deploy. Touches the same
  cost-discipline instinct as v4 Cherny/Karpathy efficiency ideas, but the mechanism (freeze
  on cheap model, transfer to expensive) is specific to this loop.
- *Source: TOPIDEAS §8 (`harness-research.md` B6 — AHE transfer; Harness-Bench).*

### 9. Skill Darwinism
When a skill is synthesized, **shadow-run** the next N matching tasks with and without it;
keep it only if it lifts the score, else **archive** (don't delete — population for later
recombination).
- **Fitness:** A/B delta on the suite.
- **Boundary — OVERLAP with `skill-darwin` + `skill-cannibal` (v3).** `skill-darwin` evolves
  skill *text* by variant selection; `skill-cannibal` runs a token-budget metabolism pass
  that eats underperformers. #9 is the *eval-gated keep/archive* decision for a *newly
  synthesized* skill, scored on the #1 suite. **Reference both** — #9 is the gate that feeds
  `skill-cannibal`'s population and uses `skill-darwin`'s archive discipline; it should not
  re-implement either.
- *Source: TOPIDEAS §9 (`harness-research.md` B7; `self-improving-claude-code-ways.md` §5).*

---

## Overlap handling (the three that must not duplicate)

| Idea | Existing v3 skill | Decision |
|---|---|---|
| #3 Falsification ledger | `belief-ledger` | **Extend** with an edit-prediction row type, or build as a thin caller — one ledger, not two. |
| #7 Delta-memory (ACE) | `project-hippocampus` | **Reference** the forgetting-curve mechanics; #7 is the append-only playbook/curator variant. |
| #9 Skill Darwinism | `skill-darwin`, `skill-cannibal` | **Reference** both; #9 is the eval-gated keep/archive gate that feeds their population. |

When any of these graduate from backlog to build, the first step is an overlap pass against
the named skill — not a fresh directory.

---

## Phased build order (per TOPIDEAS)

1. **#1 Eval suite from git history** — cold-start solved; do this even if nothing else.
2. **#2 + #6 Evolution loop + Ralph/scoreboard** — the engine and the visible climb.
3. **#3 Falsification ledger** — cheap, highest signal; makes the loop honest (extend `belief-ledger`).
4. **#4 8-component decomposition** — makes everything revertible per layer.
5. **#5 + #7 Two-speed loop with delta-memory** — affordable real-time capture, collapse-proof.
6. **#8 Evolve-cheap/deploy-expensive** — once the loop works, make it affordable.
7. **#9 Skill Darwinism** — last, once you trust the gate (reference `skill-darwin`/`skill-cannibal`).

---

## Adjacent: Sinai (parallel-teams)
`SelfImprovingAgent/docs/superpowers/specs/2026-06-13-sinai-parallel-teams-design.md` — an
approved design for a CC plugin that turns one slash command into a coordinated team of
role-specialized agents in isolated worktrees, merged through a review gate. **Adjacent, not
on the critical path:** it's an *orchestration* multiplier (how to later parallelize the
evolution runs), not part of the core loop. Note the overlap with the v2 `parallel-plan-executor`
/ `dispatching-parallel-agents` lane if it is ever pulled in.

---

## Lift, don't reinvent (reference implementations)
- **`neosigmaai/auto-harness`** — BYO-agent, auto-mine failures, gate regressions,
  suite-promotion. Closest drop-in to #1/#2. (0.56→0.78 on Tau3.)
- **`raphaelchristi/harness-evolver`** — a CC plugin that already does trace-driven prompt/
  routing evolution. Literally this use case.
- **Homunculus (`JavanC` / `humanplane`)** — `/hm-night` overnight loop + gaming-detection;
  the background-Haiku instinct learner for #5.
- **`affaan-m/everything-claude-code`** — `continuous-learning-v2` + a real eval harness for #1.
- **`gepa-ai/gepa`** — the edit-proposal engine for #2.

Full evidence base: the `SelfImprovingAgent` repo's `harness-research.md` (Part A) and each
doc's Sources section.

---

## Open questions for selection
1. Build-set size — just the skeleton (#1, #2, #6), or pull #3 forward since it extends an
   existing skill cheaply?
2. For the three overlaps (#3/#7/#9), extend the existing v3 skill in place, or build a thin
   new skill that calls it? (Affects whether these even become new directories.)
3. #4 and #8 are arguably reference docs / config conventions, not behavioral skills — keep
   them in this backlog as notes rather than promoting them to `v3/skills/`?
4. Does any piece (e.g. #6 Ralph wrapper) belong as a v2/v4 *plugin* with hooks rather than a
   v3 experimental skill, once it stabilizes?

---

## Status tracker (2026-06-13)

| Idea | Status |
|------|--------|
| #1 Eval suite from git history | candidate — backlog (build-first per TOPIDEAS) |
| #2 Eval-gated evolution loop | candidate — backlog (the engine) |
| #3 Falsification ledger | candidate — overlap; extend `belief-ledger` |
| #4 8-component harness | candidate — likely a reference map, not a skill |
| #5 Two-speed loop | candidate — backlog |
| #6 Ralph wrapper + scoreboard | candidate — backlog (pairs with #2) |
| #7 Delta-memory (ACE) | candidate — overlap; reference `project-hippocampus` |
| #8 Evolve on Haiku / deploy on Opus | candidate — backlog |
| #9 Skill Darwinism | candidate — overlap; reference `skill-darwin`/`skill-cannibal` |

---

## Round two — net-new candidates (2026-06-18)

A second brainstorm, independent of the SelfImprovingAgent shortlist above. Same v3
contract: every idea names a **fitness signal**; ideas overlapping an existing v3 skill say
*extend* or *reference*, never duplicate.

| # | Build | Fitness signal | Effort | Overlap |
|---|-------|----------------|--------|---------|
| R1 | **regression-immune-system** | reinfection rate of bug-classes → 0 | M | adjacent to `eval-suite-from-git` |
| R2 | **counterfactual-replay** (ablation) | measured score delta per component | M | feeds `skill-cannibal`; vs `ghost-run` |
| R3 | **dream-consolidation** | next-day cold-start score: consolidated vs raw log | M | OVERLAP → reference `project-hippocampus` |
| R4 | **adversarial-self-distillation** | difficulty-calibrated pass rate (self-curriculum) | M | vs `red-team-spec`, `predator-prey-review` |
| R5 | **confidence-calibration-ledger** | Brier score / calibration error → down | S | OVERLAP → extend `belief-ledger` |
| R6 | **skill-phylogenetics** | redundant skill-pairs found & merged | M | vs `skill-graph` (deps vs lineage) |
| RP | **self-improving-harness** (plugin) | suite score climbs round-over-round | M | packages #1 + #2 + #6 (this file) |

### R1. regression-immune-system
Every fix auto-synthesizes a minimal "antibody" reproduction test injected into the suite;
tracks the *reinfection rate* (same bug-class recurring).
- **Fitness:** reinfection rate trends to zero.
- **Boundary:** `eval-suite-from-git` (#1) *mines history* into tasks in batch; R1 is
  *real-time, per-fix*, with an immune-memory metric. Adjacent — R1 could feed #1's suite.

### R2. counterfactual-replay (ablation)
Re-runs a completed task with one harness variable flipped (a skill removed, autonomy
lowered) to measure that component's causal contribution.
- **Fitness:** measured score delta attributable to the flipped variable.
- **Boundary:** the eval-gated loop (#2) tests *proposed edits*; R2 *ablates existing
  components* to find dead weight. Output feeds `skill-cannibal`. Distinct from `ghost-run`
  (dry-run preview) — R2 is a controlled A/B against the suite.

### R3. dream-consolidation
An overnight "sleep" pass replays the day's traces, extracts patterns, and rewrites memory
into compressed schemas (generative replay, REM-style).
- **Fitness:** next-day cold-start task score using consolidated memory vs the raw log.
- **Boundary — OVERLAP with `project-hippocampus`.** That does *episodic* memories on an
  Ebbinghaus forgetting curve; R3 does *generative replay / schema extraction*. **Reference,
  don't duplicate** — frame R3 as the consolidation pass that writes what hippocampus stores.

### R4. adversarial-self-distillation
The agent writes a *harder* variant of each task it just passed; if it then fails its own
harder task, that becomes a new eval — a self-generated curriculum.
- **Fitness:** difficulty-calibrated pass rate; the agent's own tasks become the curriculum.
- **Boundary:** `red-team-spec` attacks *specs*, `predator-prey-review` attacks *code*; R4
  generates *escalating tasks* for the eval suite. New lane; feeds #1.

### R5. confidence-calibration-ledger
Logs a confidence value before each answer/action, scores it against the outcome, and shows
the agent its own miscalibration to correct over time.
- **Fitness:** Brier score / calibration error trends down.
- **Boundary — OVERLAP with `belief-ledger`.** That tracks *assumption* probabilities and
  audits when a belief collapses; R5 tracks *self-confidence vs outcome* calibration.
  **Extend** `belief-ledger` with a confidence-vs-outcome row type rather than a parallel store.

### R6. skill-phylogenetics
Builds a family tree of skills (which was forked/derived from which), detects convergent
evolution (two skills drifting to the same purpose), and recommends merges.
- **Fitness:** redundant skill-pairs detected and merged; library entropy down.
- **Boundary:** `skill-graph` maps *dependencies*; `skill-cannibal` *eats* underperformers.
  R6 maps *lineage/ancestry* and finds convergence — the analysis that *feeds*
  `skill-cannibal`'s merge decisions. New lane.

### RP. self-improving-harness (plugin)
Packages the skeleton from this file — #1 `eval-suite-from-git` + #2 `eval-gated-evolution-loop`
+ #6 Ralph wrapper / `SCOREBOARD.md` — as a hook+command plugin (`/harness-run`,
`/harness-score`, capture hooks).
- **Fitness:** suite score climbs round-over-round (the SCOREBOARD curve).
- **Boundary:** directly answers this file's **open question #4** (does #6 belong as a plugin
  with hooks?). RP is the packaging, not a re-implementation of #1/#2/#6.

### Status tracker (round two — 2026-06-18)

| Idea | Status |
|------|--------|
| R1 regression-immune-system | candidate — backlog |
| R2 counterfactual-replay | candidate — backlog (feeds `skill-cannibal`) |
| R3 dream-consolidation | candidate — overlap; reference `project-hippocampus` |
| R4 adversarial-self-distillation | candidate — backlog (feeds eval suite) |
| R5 confidence-calibration-ledger | candidate — overlap; extend `belief-ledger` |
| R6 skill-phylogenetics | candidate — backlog |
| RP self-improving-harness (plugin) | candidate — packages #1/#2/#6 |
