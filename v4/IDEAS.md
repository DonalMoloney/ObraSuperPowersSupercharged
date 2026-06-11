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
  each read answers; prefer targeted reads over whole-file loads; "evict" by
  summarizing findings and not re-reading; track a rough page table of what is
  already in context.
- **Boundary:** v5 has `salience-compressor` and `sample-context-fairly` (Forge
  imports, verbatim). This must either carve a distinct lane (budgeting *before*
  reading vs compressing *after*) or trigger promotion/deletion bookkeeping for
  the v5 items. Flagged as the riskiest overlap in this list.

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
