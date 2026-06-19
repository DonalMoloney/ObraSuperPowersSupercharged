# v4 Idea Candidates — Karpathy / Cherny-inspired Claude Code tools

**Date:** 2026-06-10
**Status:** Candidate list for selection — nothing here is committed to build yet.
**Rule reminder (v4 README):** every built tool needs `tier: v4`, an `inspiration:`
frontmatter line naming the specific idea + originator, and a Provenance section
citing where the idea was published.

Component-type legend: **skill** (loaded guidance), **hook** (mechanical, fires
regardless of model memory), **agent** (dispatched subagent), **plugin** (hook +
script + command bundle).

---

## Karpathy pool

### K1. autonomy-slider — skill
- **Idea:** Partial autonomy products expose an *autonomy slider*; the human picks
  how much leash the agent gets per task, not per product.
- **Provenance:** Karpathy, "Software Is Changing (Again)" keynote, Y Combinator
  AI Startup School, June 2025 (the Cursor/Perplexity autonomy-slider examples).
- **The tool:** Defines explicit autonomy levels (L0 suggest-only → L1 single-file
  diffs → L2 multi-file with checkpoints → L3 full task, verify at end) with
  selection criteria: stakes, reversibility, test coverage, how recently the agent
  was wrong in this area. The skill makes Claude *declare* its level at task start
  and downgrade itself when criteria say so.
- **Boundary:** No existing tier item addresses autonomy calibration. Distinct from
  v1 `executing-plans` checkpoints (those are plan-structure, not autonomy policy).

### K2. short-leash-increments — skill
- **Idea:** "Keep the AI on a short leash" — small, individually verifiable chunks
  beat one big diff, because human verification is the bottleneck.
- **Provenance:** Same June 2025 keynote (generation–verification loop section);
  echoed in Karpathy's vibe-coding commentary that big diffs are where trust dies.
- **The tool:** A working discipline for high-stakes changes: max one concern per
  diff, present-and-verify before the next increment, with concrete chunk-size
  heuristics (lines touched, files touched, "can the human verify this in under a
  minute?").
- **Boundary:** Complements K1 (this is the *technique* at low autonomy levels).
  Distinct from v1 `test-driven-development` (TDD is about tests driving design;
  this is about diff size driving verifiability).

### K3. context-paging — skill
- **Idea:** The LLM is a new OS: model = CPU, **context window = RAM**. RAM is
  scarce; the OS pages data in and out deliberately.
- **Provenance:** Karpathy, LLM-as-OS analogy — keynote June 2025 and earlier
  "LLM OS" posts on X (2023–2024).
- **The tool:** Context-budget discipline: before exploring, declare what question
  each read answers; "evict" by summarizing findings and not re-reading; track a
  rough page table of what is already in context. *(The tactical read mechanics —
  locate-then-range-read and trimming output at the source — were taken by
  `token-thrift` (built 2026-06-19); K3's remaining lane is the strategic
  accounting only.)*
- **Boundary:** v5 has `salience-compressor` and `sample-context-fairly` (Forge
  imports, verbatim). K3 must carve a distinct lane (budgeting/accounting *before*
  reading vs compressing *after*); the tactical *how* of a thrifty read now lives in
  `token-thrift`, so K3's residue is the page-table / question-per-read discipline.
  Still needs the v5 promote-or-delete round before building.

### K4. vibe-coding-guardrails — skill
- **Idea:** Vibe coding — "fully give in to the vibes, forget the code exists" —
  is explicitly for throwaway weekend projects, a nuance widely dropped when the
  term went viral.
- **Provenance:** Karpathy, X post coining "vibe coding", February 2025; nuance
  reiterated in the June 2025 keynote.
- **The tool:** A decision gate: classify the work (throwaway/demo vs maintained vs
  production) and set the discipline dial accordingly — full vibes allowed only
  when the blast radius is one session; mandatory review/tests as stakes rise.
  Operationalizes the *guardrail*, not the vibe.
- **Boundary:** New identity; v1 skills assume disciplined mode always. This skill
  legitimizes (and fences) the undisciplined mode.

### K5. fast-verify-loop — skill
- **Idea:** Agent productivity is bounded by the speed of the generation→
  verification loop; optimize verification *latency*, including visual/GUI
  verification, because humans verify images faster than text.
- **Provenance:** Karpathy, June 2025 keynote (gen–verify loop; "GUIs let humans
  verify fast").
- **The tool:** Before starting work, pick the *fastest sufficient* verifier and
  pre-warm it: single test file over full suite, type-check over test run for pure
  refactors, screenshot over DOM dump for UI, watch-mode over one-shot. Defines a
  verifier-latency ladder and when each rung is sufficient.
- **Boundary:** v2 `loop-until-green` runs a fix loop until a verifier passes; this
  skill *chooses* the verifier and minimizes loop latency. `chains-to:
  loop-until-green` is the natural shape. v2 `verify-command-suggester` finds
  canonical commands; this picks the cheapest one for the loop.

### K6. cognitive-prosthetics — skill
- **Idea:** LLMs have specific, nameable cognitive deficits — anterograde amnesia
  (no continual learning), jagged intelligence, hallucination under confidence —
  and workflows should compensate per-deficit rather than generically "be careful".
- **Provenance:** Karpathy, Dwarkesh Patel podcast interview, October 2025 (the
  "cognitive deficits" framing); jagged intelligence from his earlier X posts.
- **The tool:** A deficit→prosthetic table: amnesia → durable notes/ledgers;
  jaggedness → never extrapolate competence across domains, re-verify in unfamiliar
  territory; confident hallucination → cite-or-check rule for any factual claim.
  Claude consults it when entering unfamiliar ground.
- **Boundary:** Pairs with v2 `decision-ledger` (one prosthetic instance) without
  duplicating it — this is the *map*, the ledger is one *territory*.

### K7. fix-the-dataset — skill (dual provenance with Cherny)
- **Idea:** Software 2.0: the dataset *is* the code — fix recurring behavior at the
  source of behavior, not instance by instance. For Claude Code, the "dataset" is
  CLAUDE.md, skills, and hooks.
- **Provenance:** Karpathy, "Software 2.0", Medium, November 2017. Reinforced by
  Cherny: iterate on CLAUDE.md like you iterate on a prompt ("Claude Code: Best
  practices for agentic coding", Anthropic engineering blog, April 2025).
- **The tool:** When the user corrects Claude for the *second* time on the same
  class of mistake, stop and patch the steering layer: smallest edit to CLAUDE.md,
  the relevant skill, or a hook — then continue. Includes a decision table for
  *which* layer to patch (preference → CLAUDE.md; procedure → skill; must-happen →
  hook).
- **Boundary:** v5 `sync-claude-md` (Forge import) overlaps on the CLAUDE.md slice;
  building K7 should trigger the v5 promotion/removal decision for it.

---

## Cherny pool

### C1. verification-target-first — skill (optionally + hook)
- **Idea:** Claude performs dramatically better when given a concrete *target* to
  verify against — a failing test, a screenshot/mock, an expected output — before
  it starts writing.
- **Provenance:** Cherny, "Claude Code: Best practices for agentic coding",
  Anthropic engineering blog, April 2025 (the TDD-target and screenshot-target
  workflows).
- **The tool:** A pre-implementation gate: no implementation until a target
  artifact exists and is named (test, fixture, mock image, golden output, or an
  explicit "no target available because X" waiver). Optional hook variant blocks
  Edit/Write on source files until a target is registered for the task.
- **Boundary:** v1 `test-driven-development` covers the *test* target; this
  generalizes to non-test targets (screenshots, golden files) and adds the gate.
  Must reference TDD rather than restate it.

### C2. bash-first-tooling — skill
- **Idea:** Bash is the universal tool — Claude already has a computer. Before
  adding an MCP server, a dependency, or a custom integration, check whether bash
  plus existing CLIs already solve it.
- **Provenance:** Cherny, April 2025 best-practices post (give Claude your CLI
  tools); expanded in his 2025 interviews on Claude Code's design philosophy
  (Latent Space podcast).
- **The tool:** A tool-acquisition decision ladder: existing CLI → one-liner script
  → small script in repo → only then MCP/dependency. Includes the "teach the tool"
  step: document a newly-used CLI's invocation in CLAUDE.md so it sticks.
- **Boundary:** New identity; no tier item covers tool-acquisition strategy.

### C3. simplest-thing-gate — skill
- **Idea:** Do the simplest thing first. Claude Code itself is built this way —
  resist infrastructure until the dumb version has been tried.
- **Provenance:** Cherny, Latent Space podcast interview on Claude Code (2025) and
  the best-practices post's recurring "start simple" guidance.
- **The tool:** Before any multi-file change, state the *simplest version that
  could possibly work* in one sentence and either build that first or record why
  it's insufficient. A written-down YAGNI checkpoint with an artifact, not a vibe.
- **Boundary:** v1 `brainstorming` mentions YAGNI as a principle during design;
  this fires at *implementation* time on every multi-file change. Reference, don't
  restate.

### C4. fresh-context-review — skill or agent
- **Idea:** Multi-Claude workflows: one Claude writes, a *separate* Claude with
  fresh context reviews — the reviewer must not inherit the writer's assumptions.
- **Provenance:** Cherny, April 2025 best-practices post (multi-Claude patterns,
  one-writes-one-reviews; headless mode).
- **The tool:** A dispatch pattern: the reviewer subagent gets the diff and the
  *original requirements only* — never the writer's conversation, plan, or
  self-assessment — plus a contamination checklist of what must not be passed.
- **Boundary:** v2 `reviewer-lenses` parallelizes *perspectives*; this isolates
  *context*. Compatible and composable (each lens reviewer should also be
  fresh-context), but the boundary block must route between them explicitly.

### C5. checklist-working-memory — skill
- **Idea:** For large mechanical tasks (mass migrations, lint-fix sweeps), have
  Claude write a Markdown checklist and work it item by item — externalized
  working memory beats context memory.
- **Provenance:** Cherny, April 2025 best-practices post (the checklist/scratchpad
  pattern for large migrations).
- **The tool:** When a task is "N similar items" (N > ~10), generate the full item
  list to a file first, then process with check-off discipline and a resumption
  rule (the file, not the context, is the source of truth after any interruption).
- **Boundary:** v1 `executing-plans` is for *heterogeneous* planned work; this is
  for *homogeneous* sweeps where the plan is trivially "do all N". Pairs with v2
  `session-handoff` for resumption.

### C6. hook-the-must-happens — skill (a meta-skill that produces hooks)
- **Idea:** Rules that must *always* hold should be hooks, not prompts — a hook
  fires mechanically whether or not the model remembers; CLAUDE.md is steering,
  hooks are enforcement.
- **Provenance:** Cherny on hooks as the enforcement layer — best-practices post
  (April 2025) and subsequent Claude Code hooks documentation/talks he has given
  on must-happen rules.
- **The tool:** A classification procedure for any recurring instruction: is it
  preference (CLAUDE.md), procedure (skill), or invariant (hook)? For invariants,
  walks through choosing the hook event, writing the matcher, and the fail-soft
  rule (hooks must never brick the session).
- **Boundary:** Sibling of K7 (`fix-the-dataset`): K7 decides *when* to patch the
  steering layer; C6 is the *how* for the hook branch. Could be merged into one
  tool if the list needs trimming.

---

## Suggested first build set

If the round targets ~5–6 tools balanced across both pools, the strongest
candidates by (a) provenance solidity, (b) clean non-duplication, and (c) daily
usefulness:

| Pick | Why it makes the cut |
|------|----------------------|
| K1 autonomy-slider | The signature Karpathy idea; nothing like it in any tier |
| K5 fast-verify-loop | Clean chains-to with v2 `loop-until-green`; immediately useful |
| K6 cognitive-prosthetics | Strong, specific provenance; pairs with v2 `decision-ledger` |
| C1 verification-target-first | The signature Cherny idea; generalizes TDD without restating it |
| C2 bash-first-tooling | Simple, clean identity; no overlap anywhere |
| C4 fresh-context-review | Composes with v2 `reviewer-lenses` instead of colliding |

**Held back and why:** K3 (context-paging) and K7 (fix-the-dataset) collide with
v5 Forge imports and force promotion/deletion bookkeeping — better as a dedicated
second round. K2/C3/C5/C6 are good but narrower; K4 is fun but lowest daily value.

## Open questions for selection

1. Build set size — the suggested six, or trim/extend?
2. Should any pick get a hook/plugin component now (C1's blocking hook is the main
   candidate), or keep round one skills-only?
3. Tackle the v5-collision pair (K3, K7) this round with bookkeeping, or defer?

---

## Status tracker (round one — 2026-06-10)

| Idea | Status |
|------|--------|
| K1 autonomy-slider | built (round one) |
| K2 short-leash-increments | deferred — narrower; fold-in candidate for autonomy-slider |
| K3 context-paging | deferred & narrowed — tactical read mechanics taken by `token-thrift` (2026-06-19); residual lane is strategic accounting (page table / question-per-read); still needs v5 promote-or-delete round |
| K4 vibe-coding-guardrails | deferred — lowest daily value this round |
| K5 fast-verify-loop | built (round one) |
| K6 cognitive-prosthetics | built (round one) |
| K7 fix-the-dataset | deferred — v5 collision (sync-claude-md); needs promote-or-delete round |
| C1 verification-target-first | built (round one; blocking-hook variant is the named follow-up) |
| C2 bash-first-tooling | built (round one) |
| C3 simplest-thing-gate | deferred — narrower |
| C4 fresh-context-review | built (round one) |
| C5 checklist-working-memory | deferred — narrower |
| C6 hook-the-must-happens | deferred — possible merge with K7 next round |

---

## Round two — candidates (2026-06-18)

A second brainstorm. Same v4 contract: every tool cites a **specific published Karpathy or
Cherny idea** and a **boundary** against existing tier items. Net-new where possible; the two
deferred v5-collision picks (K3, K7) are *not* re-listed here.

| # | Build | Provenance | Effort | Overlap |
|---|-------|-----------|--------|---------|
| K8 | **headless-claude-pipelines** | Cherny — `claude -p` headless mode (best-practices, Apr 2025) | M | NEW — vs `bash-first-tooling` |
| K9 | **context-rot-monitor** | Karpathy LLM-as-OS (context=RAM) + Cherny `/clear` discipline | S | vs deferred K3 `context-paging` |
| C7 | **rich-feedback-channels** | Cherny — give Claude tools to see its output (tests/logs/browser) | S | vs `fast-verify-loop` |
| C8 | **permission-tiers** | Cherny — settings.json allowlists + permission modes | S | backs `autonomy-slider` |
| C9 | **commit-checkpoints** | Cherny — commit frequently as rollback points | S | NEW — vs v1 `finishing-a-development-branch` |
| K10 | **jagged-intelligence-guard** | Karpathy — "jagged intelligence" (X posts) | S | fold-in vs `cognitive-prosthetics` |
| CP | **autonomy-control** (plugin) | Cherny permissions + Karpathy autonomy slider | M | bundles K1 + C8 + C9 |

### K8. headless-claude-pipelines — skill
Write `claude -p` headless one-liners as programmable subroutines: CI gates, bulk labeling,
lint-fix sweeps, doc generation.
- **Provenance:** Cherny, "Claude Code: Best practices for agentic coding" (Anthropic eng
  blog, Apr 2025) — the headless-mode / `-p` automation section.
- **Boundary:** `bash-first-tooling` (C2) is general tool-acquisition; K8 is specifically
  *Claude-as-a-subroutine* in a shell pipeline. New identity.

### K9. context-rot-monitor — skill (optionally + hook)
Watches conversation length / staleness and prompts a compact/clear at the right moment,
tracking "context pressure."
- **Provenance:** Karpathy LLM-as-OS (context window = RAM, paged deliberately) + Cherny's
  `/clear`-between-tasks discipline (best-practices, Apr 2025).
- **Boundary:** deferred K3 `context-paging` budgets *reads before exploring*; K9 governs
  *when to clear/compact the running session*. Distinct lane — and K9 may be the cleaner one
  to build first since it sidesteps the v5 `salience-compressor` collision.

### C7. rich-feedback-channels — skill
Ensures every task has a readable observability channel (test output, logs, screenshots)
wired *before* work starts, so the agent can self-correct.
- **Provenance:** Cherny, best-practices (Apr 2025) — give Claude the ability to *see* results
  (run tests, read logs, view the browser) to close the loop.
- **Boundary:** `fast-verify-loop` (K5) *picks* the fastest verifier; C7 *guarantees the
  feedback channel exists and is legible*. C7 is the precondition; K5 is the choice.

### C8. permission-tiers — skill
settings.json permission templates matched to each `autonomy-slider` level, enforced by a
`PreToolUse` gate.
- **Provenance:** Cherny, best-practices (Apr 2025) — allowlists / permission modes /
  `--dangerously-skip-permissions` used deliberately.
- **Boundary:** `autonomy-slider` (K1) is the *policy* (which level); C8 is the *mechanism*
  (the settings.json that makes the level real). Pairs, doesn't duplicate.

### C9. commit-checkpoints — skill
Auto-commits at each verified increment so any step is revertible; resume from a clean state
after a wrong turn.
- **Provenance:** Cherny, best-practices (Apr 2025) — commit frequently as checkpoints to roll
  back to.
- **Boundary:** v1 `finishing-a-development-branch` is end-of-work integration; C9 is
  *mid-work checkpointing*. Pairs with deferred K2 `short-leash-increments`.

### K10. jagged-intelligence-guard — skill
Flags when a task enters a known-spiky domain (arithmetic, counting, spatial reasoning,
fresh/unseen APIs) and forces a tool or verify step instead of trusting the model.
- **Provenance:** Karpathy, "jagged intelligence" (X posts, 2024–2025).
- **Boundary — fold-in tension with `cognitive-prosthetics` (K6)**, which already lists
  jaggedness as *one* deficit row. K10 is the standalone *routing guard*. Decision at build
  time: deepen K6's row, or split K10 out as a guard that K6 references.

### CP. autonomy-control — plugin
Bundles `autonomy-slider` (K1) + `permission-tiers` (C8) + `commit-checkpoints` (C9) with a
`PreToolUse` gate that enforces the declared autonomy level at tool-call time.
- **Provenance:** Karpathy autonomy-slider + Cherny permissions / hooks-as-enforcement.
- **Boundary:** the plugin is the *enforcement bundle*; the three skills remain usable
  standalone. The hook makes the level mechanical, not advisory.

### Status tracker (round two — 2026-06-18)

| Idea | Status |
|------|--------|
| K8 headless-claude-pipelines | candidate — backlog (recommended build-first) |
| K9 context-rot-monitor | candidate — backlog (recommended build-first; cleaner than deferred K3) |
| C7 rich-feedback-channels | candidate — backlog |
| C8 permission-tiers | candidate — backlog (pairs `autonomy-slider`) |
| C9 commit-checkpoints | candidate — backlog (pairs deferred K2) |
| K10 jagged-intelligence-guard | candidate — fold-in vs `cognitive-prosthetics` |
| CP autonomy-control (plugin) | candidate — bundles K1 + C8 + C9 |

---

## Net-new builds (post round two)

Builds that did not come from either candidate list above — added as the lane became clear.

### TT. token-thrift — skill (built 2026-06-19)
Reduce the token cost of tool results and reads *at the point of the call*: trim output at the
source (`rg`/`head`/`--stat`/`jq`/`-q`), scope reads (locate with `Grep`/`git grep -n`, then
`Read` with `offset`+`limit`), and offload broad file-sweeps to a subagent that returns only the
conclusion + `file:line` pointers.
- **Provenance:** Cherny — CLI tools are "the most context-efficient way" to work + "use
  subagents ... tends to preserve context availability" (best-practices, Apr 2025); Karpathy —
  context-window-as-RAM / accuracy degrades with fill, cited as the *why*.
- **Boundary:** owns the *generation-side* footprint of each tool call. Distinct from
  `selective-priming` (what to load in at start), `context-rot-monitor` (when to clear/compact
  what is already in), v5 `salience-compressor` (compress after the fact), and
  `cognitive-prosthetics` (externalize state). Takes the *tactical read mechanics* from deferred
  K3 `context-paging`, leaving K3 its strategic accounting lane.

| Idea | Status |
|------|--------|
| TT token-thrift | built (net-new, 2026-06-19) |

---

## Round three — candidate (2026-06-19)

One net-new Cherny tool, prompted by the live `.claude/claude-md-drift.json` ledger this repo
already writes. Same v4 contract: cite a specific published idea, draw a boundary against the
drift machinery that already exists (v5 `claude-md-watcher`, v2 `plan-drift-detector`,
v4 `context-rot-monitor`).

| # | Build | Provenance | Effort | Overlap |
|---|-------|-----------|--------|---------|
| C10 | **claude-md-drift-guard** | Cherny — hooks make the must-happens deterministic + CLAUDE.md is a living, tuned file (best-practices, Apr 2025) | M | NEW — *enforces* what v5 `claude-md-watcher` only reconciles |

### C10. claude-md-drift-guard — skill + hook
Treat CLAUDE.md as **verifiable claims, not trusted prose.** Extract the machine-checkable
assertions a CLAUDE.md actually makes — counts ("14 skills"), paths that must exist, the default
branch, the setup/test commands that must run — and check them deterministically against the repo.
When the drift ledger is non-empty *and* a claim is provably false on disk, a `Stop` / pre-commit
hook **blocks the done/commit step** until CLAUDE.md is reconciled, instead of emitting the advisory
reminder the current watcher relies on (easy to ignore mid-task).
- **Provenance:** Cherny, "Claude Code: Best practices for agentic coding" (Anthropic eng blog,
  Apr 2025) — hooks used to make the must-happens *deterministic* rather than advisory, and CLAUDE.md
  treated as a living file you tune over time. The verification-loop framing ("give Claude tools to
  *see* results") applied to project memory: the doc's claims are checked, not trusted.
- **Boundary:**
  - vs v5 `claude-md-watcher` — the watcher *reconciles when invoked* (reads the ledger, patches the
    implicated section). C10 is the **enforcement + claim-extraction front end**: it decides *when a
    claim is provably stale* and *gates* on it, then hands the actual patching to the watcher. Guard
    detects-and-blocks; watcher edits. They chain, they don't duplicate.
  - vs v4 `context-rot-monitor` — that governs *session* staleness (conversation length); C10 governs
    *repo-vs-doc* staleness that persists across sessions.
  - vs v2 `plan-drift-detector` — plan-vs-implementation drift, not doc-vs-repo.
- **Open question:** auto-infer claims vs. annotate them. A `<!-- verify: skills==14 -->` marker
  convention makes each claim explicit and machine-checkable but asks the author to tag it; pure
  inference (regex for counts / referenced paths / fenced commands) needs no tags but is noisier.
  Likely answer: annotate the high-value claims, infer paths and commands.

| Idea | Status |
|------|--------|
| C10 claude-md-drift-guard | candidate — backlog (chains to v5 `claude-md-watcher`; cites the live drift ledger) |
