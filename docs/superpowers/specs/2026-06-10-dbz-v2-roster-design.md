# Design: Dragon Ball v2 roster — five supporting skills

**Date:** 2026-06-10
**Status:** Approved by user
**Tier:** v2 (supporting skills, not core obra)

## Goal

Add five super-practical v2 skills whose names (and metaphors) are Dragon Ball
themed but whose content is rigorous and workflow-focused. The roster is
gap-first: it prioritizes v1 skills with no existing v2 support
(`using-superpowers`, `subagent-driven-development`) before deepening
already-covered areas.

## Constraints (from CLAUDE.md and v2/README.md)

- New skill identities only — nothing that duplicates a v1 obra skill.
- Each SKILL.md frontmatter: `name`, `description` (states WHEN to use),
  `author: Donal Moloney`, `tier: v2`, `supports:` naming v1 skill(s),
  plus `type:` and `chains-to:`/`pairs-with:` per existing v2 house style.
- Body opens with a `## Not this skill if` boundary section (house style).
- Reference v1 content; never duplicate it.
- Layout: `v2/skills/<skill-name>/SKILL.md`, one skill per directory.
- After adding: update the "Current skills" table in `v2/README.md`, then run
  the `skill-auditor` agent on each new skill before any commit.

## Gap analysis (why these five)

Existing v2 coverage: `loop-until-green` (TDD, verification, debugging),
`merge-parallel-results` (parallel agents, verification), `red-team-spec`
(brainstorming, plans, parallel agents), `review-clarification-gate`
(receiving/requesting code review), `session-handoff` (executing/writing
plans), `skill-lint` (writing-skills), `spike-in-worktree` (worktrees,
finishing a branch).

Uncovered v1 skills: **using-superpowers**, **subagent-driven-development**.
Thin areas: fault localization within debugging, post-fix learning capture,
mid-task state recovery.

## The five skills

### 1. `scouter` — pre-task power-level triage

- **Type:** process
- **Supports:** using-superpowers, writing-plans, brainstorming
- **Chains-to:** brainstorming (over-9000 band) or writing-plans (medium band)
- **Fills:** the `using-superpowers` gap.

**Mechanism.** Before engaging any non-trivial task, take a scouter reading on
three dials:

| Dial | Question | Low | High |
|---|---|---|---|
| Scope | How many files/systems touched? | 1 file | cross-cutting |
| Risk | How reversible is a mistake? | trivially | hard to undo |
| Unknowns | Questions you cannot yet answer? | none | several |

The reading maps to a band with a prescribed action:

- **Low** — act directly; finish with v1 verification-before-completion.
- **Medium** — plan first via v1 writing-plans.
- **Over 9000** — the task is multiple projects wearing a trench coat;
  decompose into sub-projects per v1 brainstorming's decomposition guidance
  before any other work.

Each band also names the skills to invoke, making this a practical front door
for v1 using-superpowers ("which skill applies?").

**Not this skill if:** the task is a single trivially-reversible edit, or the
user already supplied an explicit plan.

### 2. `shenron-wish` — precise subagent task specification

- **Type:** technique
- **Supports:** subagent-driven-development, dispatching-parallel-agents
- **Pairs-with:** merge-parallel-results
- **Fills:** the `subagent-driven-development` gap.

**Mechanism.** Shenron grants exactly what you ask — no more. Every subagent
prompt must contain five clauses before summoning:

1. **Context** — everything the agent cannot infer on its own.
2. **Task** — one wish per dragon: exactly one task per agent.
3. **Forbidden actions** — side effects the wish must not cause.
4. **Done criteria** — objectively checkable completion conditions.
5. **Report format** — what must come back, in what shape.

Hard rule: if you cannot write the done criterion, you are not ready to
summon. The skill provides the wish template and a pre-summon checklist.

**Not this skill if:** you are doing the work yourself in-session.

### 3. `zenkai-boost` — get stronger from every near-death

- **Type:** process
- **Supports:** systematic-debugging, test-driven-development
- **Chains-to:** verification-before-completion

**Mechanism.** Immediately after any bug fix is verified, before moving on:

1. **Regression test** — write the test that would have caught the bug;
   confirm it fails on pre-fix code and passes post-fix.
2. **One-line lesson** — record it in the project's gotchas (CLAUDE.md or
   equivalent).
3. **Sibling sweep** — search for other instances of the same bug class
   before closing.

The fight is not over until the failure has made the codebase permanently
stronger.

**Not this skill if:** the failure was environmental/flaky with no code-level
cause.

### 4. `instant-transmission` — teleport to the fault

- **Type:** technique
- **Supports:** systematic-debugging
- **Chains-to:** systematic-debugging (entering at its hypothesis phase)

**Mechanism.** A fault-localization ladder run before the full debugging
loop, cheapest rung first:

1. Exact-match grep on the error signature.
2. Known regression → `git bisect` driven by a repro script.
3. Recent breakage → `git diff` / `git blame` on the suspect window.
4. Binary-search instrumentation (halve the search space with logging).

Prerequisite — a **ki signature**: a reproducible failure signal to lock onto.
No repro means no teleport; build the repro first.

**Not this skill if:** the fault location is already known — go straight to
v1 systematic-debugging.

### 5. `senzu-bean` — full recovery mid-fight

- **Type:** process
- **Supports:** executing-plans
- **Pairs-with:** session-handoff (v2)
- **Chains-to:** executing-plans

**Mechanism.** When resuming after context compaction, a crash, or a long
interruption, rehydrate from durable artifacts — never from memory:

1. Read the plan doc; verify which steps are genuinely checked off.
2. `git status` / `git diff` / `git log` for actual workspace state.
3. Run the test suite for ground truth.
4. Diff *claimed* state against *actual* state; resume at the first
   discrepancy.

Rule: artifacts over recollection.

**Not this skill if:** a current v2 session-handoff document exists — read it
first; senzu-bean complements handoffs, it does not replace them.

## Out of scope

- No plugins in this batch — plain skills only.
- No changes to v1 skills or existing v2 skills.
- ~~Candidate names considered and deferred: dragon-radar, kaioken,
  gravity-chamber, fusion-dance (available for a future batch).~~
  **Superseded (2026-06-10):** user approved building these four as Batch 2 —
  see the addendum below and
  `docs/superpowers/plans/2026-06-10-dbz-v2-roster-batch2.md`.

## Acceptance

- Five new directories under `v2/skills/`, each with a SKILL.md meeting the
  constraints above.
- `v2/README.md` "Current skills" table lists all five with their v1 supports.
- `skill-auditor` agent run on each new skill reports no blocking findings.

## Addendum (2026-06-10): Batch 2 — the four deferred skills

Approved after Batch 1 shipped. Same constraints and house style as above.

| Skill | Type | Supports (v1) | One-line mechanism |
|---|---|---|---|
| `dragon-radar` | technique | verification-before-completion, systematic-debugging | Enumerate every occurrence of a pattern (multi-band scan + ledger), fix or exclude each, re-sweep to zero before claiming done |
| `kaioken` | process | dispatching-parallel-agents, systematic-debugging | Declared, budgeted escalation burst (trigger/multiplier/budget/exit) with mandatory cooldown verification |
| `gravity-chamber` | technique | test-driven-development, verification-before-completion | Graded test-rigor levels (1g happy path → 10g edge matrix → 50g repetition → 100g property/fuzz → 150g adversarial); every failure becomes a permanent test |
| `fusion-dance` | technique | brainstorming, writing-plans | Synthesize two competing designs: equal-power-level precondition, axis table, compose along winning axes, Veku check that the fusion beats both donors |

Acceptance: four new directories under `v2/skills/`, README table at 16 rows,
skill-auditor reports no blocking findings.
