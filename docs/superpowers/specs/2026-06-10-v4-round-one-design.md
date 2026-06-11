# v4 Round One — Design

**Date:** 2026-06-10
**Status:** Approved by user (design review), pending spec review
**Scope:** 6 new v4 skills (the tier's first content). Skills-only — no hooks,
plugins, or agent definitions this round.

## Goal

Seed the v4 tier with six Claude Code skills, each operationalizing one specific
published idea from Andrej Karpathy or Boris Cherny, per the v4 tier rules
(`tier: v4` + `inspiration:` frontmatter, mandatory Provenance section).

## Selection basis

The full candidate list lives in `v4/IDEAS.md` (13 ideas, 7 Karpathy / 6 Cherny,
each with provenance, component type, and tier-boundary notes). The user selected
the "suggested six" — chosen for provenance solidity, clean non-duplication
against v1/v2/v5, and daily usefulness — and chose skills-only for round one
(simplest-thing-first; mechanical variants can follow once the skills prove out).

Deferred with reasons recorded in IDEAS.md: K3 `context-paging` and K7
`fix-the-dataset` (both collide with v5 Forge imports and would force
promote-or-delete bookkeeping — deliberately a separate round); K2, K4, C3, C5,
C6 (narrower or lower daily value).

## Shared skill template

Every skill is `v4/skills/<name>/SKILL.md`:

- **Frontmatter:** `name`, `description` (states WHEN to use it), `tier: v4`,
  `inspiration:` — one line naming originator + idea + source, e.g.
  `inspiration: "Karpathy — autonomy slider (YC AI Startup School keynote, June 2025)"`.
  Relational fields from the v2 convention where they apply (`pairs-with:`,
  `chains-to:`).
- **Body:** opens with a "Not this skill if" boundary block routing to the
  nearest neighbor in any tier; then the core procedure; then a mandatory
  `## Provenance` section: the idea, where it was stated (talk/post/interview),
  and how this tool operationalizes it.

## The six skills (`v4/skills/<name>/SKILL.md`)

### 1. verification-target-first
- **Pool:** Cherny — "Claude Code: Best practices for agentic coding", Anthropic
  engineering blog, April 2025 (TDD-target and screenshot-target workflows).
- **Core:** Pre-implementation gate. No implementation until a named target
  artifact exists: failing test, golden output, screenshot/mock — or an explicit
  waiver stating why no target is available. Includes a target taxonomy by change
  type.
- **Boundary:** v1 `test-driven-development` owns the test branch — reference it,
  never restate. This skill generalizes the target idea to non-test artifacts and
  adds the gate.

### 2. fast-verify-loop
- **Pool:** Karpathy — "Software Is Changing (Again)" keynote, YC AI Startup
  School, June 2025 (generation–verification loop speed; GUIs let humans verify
  fast). · **chains-to:** loop-until-green (v2)
- **Core:** Pick the *fastest sufficient* verifier before starting work, and
  pre-warm it. Verifier-latency ladder (type-check < single test file < full
  suite < e2e; screenshot < DOM dump for UI) plus sufficiency rules mapping
  change class → minimum rung.
- **Boundary:** v2 `loop-until-green` runs the loop; this picks the verifier and
  minimizes its latency. v2 `verify-command-suggester` finds canonical commands;
  this chooses the cheapest sufficient one.

### 3. autonomy-slider
- **Pool:** Karpathy — same June 2025 keynote (partial-autonomy apps; the
  autonomy slider).
- **Core:** Four declared autonomy levels: L0 suggest-only, L1 single-file diffs
  presented individually, L2 multi-file with checkpoints, L3 full task with
  verification at end. Selection criteria: stakes, reversibility, test coverage,
  recent error rate in this area. Claude declares its level at task start and
  must downgrade when a criterion trips mid-task (e.g., a surprise test failure
  in unfamiliar code).
- **Boundary:** v1 `executing-plans` checkpoints are plan structure, not autonomy
  policy. No tier item covers autonomy calibration.

### 4. fresh-context-review
- **Pool:** Cherny — April 2025 best-practices post (multi-Claude patterns:
  one writes, a separate fresh-context instance reviews).
- **Core:** Dispatch pattern for reviewer subagents: the reviewer receives the
  diff and the *original requirements only* — never the writer's conversation,
  plan, or self-assessment. Includes a contamination checklist of what must not
  be passed and why each item biases review.
- **Boundary:** v2 `reviewer-lenses` parallelizes *perspectives*; this isolates
  *context*. Composable — each lens reviewer should also be fresh-context — and
  the boundary block routes between them explicitly.

### 5. cognitive-prosthetics
- **Pool:** Karpathy — Dwarkesh Patel podcast interview, October 2025 (LLM
  "cognitive deficits": anterograde amnesia, jagged intelligence); jagged
  intelligence also from earlier Karpathy X posts. · **pairs-with:**
  decision-ledger (v2)
- **Core:** A deficit → prosthetic table: amnesia → durable notes/ledgers;
  jagged intelligence → never extrapolate competence across domains, re-verify
  in unfamiliar territory; confident hallucination → cite-or-check rule for
  factual claims. Consulted when entering unfamiliar ground.
- **Boundary:** v2 `decision-ledger` is one prosthetic instance; this is the map,
  not the territory.

### 6. bash-first-tooling
- **Pool:** Cherny — April 2025 best-practices post (give Claude your CLI tools;
  bash as the universal tool), expanded in his 2025 Latent Space interview.
- **Core:** Tool-acquisition decision ladder: existing CLI → one-liner →
  small script in repo → only then MCP server/dependency. Ends with a
  "teach the tool" step: document a newly-adopted CLI's invocation in CLAUDE.md
  so it persists across sessions.
- **Boundary:** New identity; no tier item covers tool-acquisition strategy.

## Build workflow

1. Each skill is designed by the `karpathy-boris-architect` agent, one at a time.
2. **Provenance is a hard gate:** the agent verifies the citation via web search
   while designing (talk title, venue, date, that the idea actually appears
   there). If a citation cannot be confirmed, the `inspiration:` line is
   corrected to what is verifiable — or the skill pauses. No skill ships on
   memory-cited provenance.
3. Each skill must pass a `skill-auditor` agent run (read-only; findings fixed
   in the main session) before it counts as done.
4. Build order (the verification pair first, then the rest):
   verification-target-first → fast-verify-loop → autonomy-slider →
   fresh-context-review → cognitive-prosthetics → bash-first-tooling.
   All six are independent; none blocks another.

## Bookkeeping

- `v4/README.md` gains a "Current tools" table (name, originator, idea,
  pairs/chains relations), mirroring the v2 README convention.
- `v4/IDEAS.md` gains a status column per idea: built (this round) / deferred
  (with reason already recorded).
- No v1, v2, v3, or v5 file is touched.

## Error handling and boundaries

- Every boundary block names its nearest neighbor explicitly:
  fast-verify-loop ↔ loop-until-green (v2), fresh-context-review ↔
  reviewer-lenses (v2), verification-target-first ↔ test-driven-development
  (v1), cognitive-prosthetics ↔ decision-ledger (v2).
- The K3/K7 v5 collisions stay deferred; building either later triggers the
  promote-or-delete bookkeeping defined in CLAUDE.md's v5 workflow.
- This project is intentionally not a git repository yet; this spec is saved but
  not committed (same deviation from the brainstorming default as the v2 round,
  per CLAUDE.md).

## Out of scope

- Hook/plugin variants (C1's edit-blocking hook is the named follow-up candidate
  once the skill proves out).
- The seven non-selected IDEAS.md candidates.
- v3 content; any v5 promotion.
