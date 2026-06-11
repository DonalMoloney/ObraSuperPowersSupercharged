# v2 Additions Implementation Plan

> **Superseded by** the spec `docs/superpowers/specs/2026-06-10-v2-reanalysis-design.md`. Do not execute Tasks 2–9; Task 1 (`review-clarification-gate`) was completed before supersession.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 6 supporting skills and 2 plugins to the v2 tier, covering the evidenced v1 gaps per `docs/superpowers/specs/2026-06-10-v2-additions-design.md`.

**Architecture:** Each skill is a single `v2/skills/<name>/SKILL.md` following the existing v2 house style (frontmatter with `tier: v2` + `supports:`, a `## Not this skill if` boundary block, explicit numbered steps, a `PROVEN BY:` verification block). Each plugin is a standard Claude Code plugin directory under `v2/plugins/<name>/` (`.claude-plugin/plugin.json`, scripts, hooks/commands). Validation replaces tests: every SKILL.md must pass the 7-point checklist in `v2/skills/skill-lint/SKILL.md` and a `skill-auditor` agent run; plugin scripts get executable smoke tests with expected output.

**Tech Stack:** Markdown (SKILL.md), bash (plugin scripts), JSON (plugin manifests/hooks).

**Deviations from defaults (intentional):**
- **No git commits.** This project is deliberately not a git repository yet (per CLAUDE.md). Commit steps are replaced by lint/audit verification steps.
- **No `support-builder` agent.** CLAUDE.md names it, but it does not exist in `.claude/agents/`. The drafting content is therefore inlined in this plan; validation uses the real agents `skill-auditor` (and `plugin-dev:plugin-validator` for plugins). The existing `skill-supercharger` agent may optionally review drafts, but the inline content below is authoritative.

**skill-lint pass criteria (used in every skill task):** (1) frontmatter has `name`, `description`, `tier: v2`, `supports:` with real v1 skills; (2) description starts with `Use when`; (3) a `## Not this skill if` or `## When to use`/`## Triggers` section exists; (4) a numbered or checkbox list with ≥2 steps exists; (5) `PROVEN BY` / `verify` / `verification-before-completion` appears; (6) no TODO/TBD/placeholder strings; (7) every referenced skill resolves to a real directory (`v1/<name>/`, `v2/skills/<name>/`).

---

### Task 1: review-clarification-gate skill

**Files:**
- Create: `v2/skills/review-clarification-gate/SKILL.md`

- [ ] **Step 1: Write the skill file**

Write `v2/skills/review-clarification-gate/SKILL.md` with exactly this content:

````markdown
---
name: review-clarification-gate
description: Use when received review feedback contains any item that is unclear, ambiguous, or technically questionable — freezes implementation of ALL items until every one is classified, and provides the clarification-request template plus an escalation path when the reviewer is unavailable.
author: Donal Moloney
tier: v2
supports: [receiving-code-review, requesting-code-review]
type: process
chains-to: receiving-code-review
---

## Not this skill if

- Every feedback item is unambiguous and technically sound — implement directly via v1 **receiving-code-review**.
- You understand the item fully but disagree with it — that is push-back, handled inside v1 **receiving-code-review**; this gate only manufactures missing clarity.
- The spec (not the code) is what's being challenged — use v2 **red-team-spec** before implementation, not a review gate after it.

# Review Clarification Gate

## Purpose

v1 **receiving-code-review** commands "STOP, do not implement anything yet" when feedback is unclear — but provides no procedure for getting unstuck. This gate is that procedure: classify every item, extract real answers for the unclear ones, and only then hand the batch back to v1 **receiving-code-review** for implementation.

**Core rule:** one unclear item freezes the whole batch. Partial implementation against a half-understood review is how wrong fixes ship with green checkmarks.

## The gate

1. **List** every feedback item verbatim in a classification table (one row per item).
2. **Classify** each row: `UNDERSTOOD` (meaning and motivation are both clear), `NEEDS-CLARIFICATION` (could be read ≥2 ways, or the motivation is opaque), or `PUSH-BACK` (understood, but you have evidence it's wrong).
3. For each `NEEDS-CLARIFICATION` row, send the clarification request using the template below. Never guess-and-implement.
4. If the reviewer does not respond or is unavailable, escalate one rung at a time: reviewer → your human partner → defer the item explicitly (record it as deferred, do NOT silently drop it).
5. Re-classify on each answer. The gate opens only when zero rows remain `NEEDS-CLARIFICATION`.
6. Chain to v1 **receiving-code-review** to implement `UNDERSTOOD` items and argue `PUSH-BACK` items with evidence.

## Clarification request template

> Re: "<quoted feedback item, verbatim>"
>
> I can read this at least two ways:
> (a) <concrete interpretation A — what code would change>
> (b) <concrete interpretation B — what code would change>
>
> Which did you mean? If neither, a one-sentence restatement would unblock me.

Stating candidate interpretations forces you to demonstrate you engaged with the item, and lets the reviewer answer with one letter.

## Escalation ladder

| Rung | When | Action |
|---|---|---|
| Reviewer | Always first | Send the template; wait for the answer before touching related code |
| Human partner | Reviewer unavailable or answer still ambiguous after one round-trip | Present the item + both interpretations; ask them to adjudicate |
| Explicit deferral | Nobody can adjudicate now | Record item + open question where deferred work is tracked; exclude it from this batch visibly |

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Implementing the "obvious" items while one is unclear | The gate freezes the whole batch — answers to unclear items often change "obvious" ones |
| Asking "what do you mean?" with no interpretations | Use the template; make the reviewer's answer a one-letter choice |
| Treating silence as agreement with your favorite reading | Silence escalates the ladder; it never resolves a row |
| Reclassifying an item PUSH-BACK to avoid asking | PUSH-BACK requires evidence you understand it; if you can't state the reviewer's motivation, it's NEEDS-CLARIFICATION |

## After

Verify before implementing: re-read the classification table and confirm zero `NEEDS-CLARIFICATION` rows remain, then proceed via v1 **receiving-code-review**.

PROVEN BY: the pasted classification table with every row resolved to `UNDERSTOOD` or `PUSH-BACK` (with answers quoted) before any implementation begins. Implementing with an open `NEEDS-CLARIFICATION` row is invalid under this skill.
````

- [ ] **Step 2: Run the skill-lint checklist against the new file**

Apply all 7 checks from `v2/skills/skill-lint/SKILL.md` to `v2/skills/review-clarification-gate/SKILL.md` and emit the report table.
Expected: `Overall: PASS — all 7 structural checks green.` (Check 7 references resolve: `receiving-code-review`, `requesting-code-review` in `v1/`; `red-team-spec` in `v2/skills/`.)

- [ ] **Step 3: Dispatch the skill-auditor agent**

Dispatch the project `skill-auditor` agent (defined in `.claude/agents/skill-auditor.md`; read-only) with prompt: "Audit v2/skills/review-clarification-gate/SKILL.md against the v2 tier rules in CLAUDE.md. Report pass/fail with evidence."
Expected: PASS. If findings are reported, fix them in the file and re-run Step 2.

---

### Task 2: context-sufficiency-check skill

**Files:**
- Create: `v2/skills/context-sufficiency-check/SKILL.md`

- [ ] **Step 1: Write the skill file**

Write `v2/skills/context-sufficiency-check/SKILL.md` with exactly this content:

````markdown
---
name: context-sufficiency-check
description: Use when about to dispatch a subagent, and ALWAYS before re-dispatching after a NEEDS_CONTEXT or failed return — scores the prompt against a six-element checklist, maps the failure to a specific missing element, and caps re-dispatches at 2 before escalating.
author: Donal Moloney
tier: v2
supports: [subagent-driven-development, dispatching-parallel-agents]
type: decision
---

## Not this skill if

- The subagent returned results that need merging — that is v2 **merge-parallel-results**.
- The task itself is wrong (not under-specified) — re-plan via v1 **writing-plans**; no amount of context fixes a bad task split.

# Context Sufficiency Check

## Purpose

v1 **subagent-driven-development** says "if it's a context problem, provide more context and re-dispatch" — without defining "enough context". That's an open invitation to a re-dispatch loop: each retry adds a vague paragraph, burns a dispatch, and fails the same way. This check makes "enough" measurable before the first dispatch and turns every retry into a targeted fix.

**Core rule:** a re-dispatch is only allowed if you can name the specific checklist element that was missing. "More detail" is not an element.

## The six elements

Score the dispatch prompt before sending. Each element is present or absent — no partial credit.

| # | Element | Present means |
|---|---|---|
| 1 | Task statement | One sentence saying what to produce, in imperative form |
| 2 | Success criteria | The agent can self-judge done/not-done without asking you |
| 3 | Exact file paths | Every file to read or touch is named — no "find the relevant file" |
| 4 | Interface contracts | Signatures/shapes the work must conform to are spelled out |
| 5 | Constraints | What must NOT change or be touched is explicit |
| 6 | Worked example | One concrete input→output example, or a pointer to an existing analogous implementation by exact path |

## Procedure

1. Draft the dispatch prompt.
2. Score it: list elements 1–6 with present/absent. Any absent element → fix the prompt before dispatching, or consciously waive it with a one-line reason (e.g., "no contract exists yet — agent defines it").
3. Dispatch.
4. On a `NEEDS_CONTEXT` or wrong-result return: map the failure to a numbered element. If you cannot name the missing element, the problem is the task split, not the context — STOP and re-plan via v1 **writing-plans**.
5. Fix exactly that element; re-dispatch. Maximum 2 re-dispatches per task.
6. After the 2nd failed re-dispatch, escalate to your human partner with the score table and both failure mappings.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Re-dispatching with "be more careful" appended | Name the missing element; fix that element |
| Pasting the whole repo as context | Sufficiency is the six elements, not volume — over-stuffed prompts bury the contract |
| Counting a reworded retry as a fresh task | The 2-re-dispatch cap follows the task, not the prompt wording |
| Skipping the score on "trivial" dispatches | Trivial dispatches that fail still burn a full round trip; the score takes 30 seconds |

## After

Verify the loop is closed: the final return satisfies element 2's success criteria as written, then proceed per v1 **subagent-driven-development** review flow.

PROVEN BY: the pasted six-element score table for the dispatch (and, for any re-dispatch, the named missing element it fixed). A re-dispatch without a named element is invalid under this skill.
````

- [ ] **Step 2: Run the skill-lint checklist against the new file**

Apply all 7 checks from `v2/skills/skill-lint/SKILL.md`.
Expected: `Overall: PASS — all 7 structural checks green.` (Check 7: `subagent-driven-development`, `dispatching-parallel-agents`, `writing-plans` in `v1/`; `merge-parallel-results` in `v2/skills/`.)

- [ ] **Step 3: Dispatch the skill-auditor agent**

Same dispatch as Task 1 Step 3, targeting `v2/skills/context-sufficiency-check/SKILL.md`.
Expected: PASS. Fix findings and re-run Step 2 if not.

---

### Task 3: architecture-stall-detector skill

**Files:**
- Create: `v2/skills/architecture-stall-detector/SKILL.md`

- [ ] **Step 1: Write the skill file**

Write `v2/skills/architecture-stall-detector/SKILL.md` with exactly this content:

````markdown
---
name: architecture-stall-detector
description: Use when 3 or more attempted fixes for the same bug have failed — runs a red-flag checklist to produce a verdict (implementation bug vs architecture problem) and the structured questions to bring to your human partner, instead of attempting fix #4 blind.
author: Donal Moloney
tier: v2
supports: [systematic-debugging, test-driven-development]
type: decision
pairs-with: loop-until-green
---

## Not this skill if

- Fewer than 3 fixes have failed — stay inside v1 **systematic-debugging** phases; this detector fires at the "question architecture" threshold, not before.
- The loop is still converging (each fix reduces failures) — that is v2 **loop-until-green** making progress, not a stall.

# Architecture Stall Detector

## Purpose

v1 **systematic-debugging** says: "If 3+ fixes failed: question architecture … discuss with your human partner." But it gives no way to recognize an architectural failure versus a hard implementation bug, and no structure for that discussion. This detector supplies both — so the conversation with your human starts with evidence, not "it's still broken." Under v1 **test-driven-development**, flag 4 is the loudest early warning: code that can only be tested through a mock fortress is the design telling you its boundaries are wrong.

**Core rule:** after the 3rd failed fix, the next action is a verdict, never a 4th fix.

## Red-flag checklist

For each flag, answer yes/no with one line of evidence from the failed fixes.

| # | Red flag | What it looks like |
|---|---|---|
| 1 | Layer whack-a-mole | Fix in layer A made something break in layer B (or a previously passing test fail elsewhere) |
| 2 | Shared mutable state | ≥2 fixes touched the same state written from multiple places |
| 3 | Abstraction leak | A fix required knowledge of another component's internals to write |
| 4 | Mock fortress | Testing the fix needed heavy mocking just to isolate the unit |
| 5 | Contradictory invariants | Two fixes were mutually exclusive — making one case pass breaks another by design |

## Procedure

1. Confirm the trigger: list the 3+ failed fixes — what each changed, what each was supposed to prove, how each failed.
2. Run the five red flags against that list; record yes/no + evidence.
3. Verdict:
   - **0–1 flags yes → implementation bug.** Return to v1 **systematic-debugging** Phase 1; your root-cause hypothesis is wrong, the structure is fine.
   - **≥2 flags yes → architecture problem.** Stop fixing. Go to step 4.
4. Bring to your human partner: the failed-fix list, the flag table, and these three questions:
   - "Which component owns <the contested state/behavior>? Right now the answer is <N> components."
   - "Is <invariant from flag 5> actually required, or an accident of the current design?"
   - "If we redesigned <boundary>, fixes 1–3 would have been one-line changes. Is that redesign in scope?"
5. Do not resume fixing until the verdict (and any redesign decision) is explicit.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Counting variations of one fix as 3 fixes | 3 distinct hypotheses must have failed, not one hypothesis retried 3 times |
| Declaring "architecture problem" to escape a hard bug | ≥2 flags with evidence, or it's an implementation bug — the table keeps you honest |
| Bringing your human "it's still broken" | Bring the failed-fix list, the flag table, and the three questions |
| Quietly starting a redesign after the verdict | Redesign is a scope decision — your human partner makes it |

## After

Verify the verdict was acted on: either v1 **systematic-debugging** restarted at Phase 1 with a new hypothesis, or a scoped redesign decision is recorded before any further fixes.

PROVEN BY: the pasted flag table (5 rows, yes/no + evidence) and the explicit verdict line. A 4th fix attempted without a verdict is invalid under this skill.
````

- [ ] **Step 2: Run the skill-lint checklist against the new file**

Apply all 7 checks from `v2/skills/skill-lint/SKILL.md`.
Expected: `Overall: PASS — all 7 structural checks green.` (Check 7: `systematic-debugging`, `test-driven-development` in `v1/`; `loop-until-green` in `v2/skills/`.)

- [ ] **Step 3: Dispatch the skill-auditor agent**

Same dispatch as Task 1 Step 3, targeting this file. Expected: PASS; fix findings and re-lint if not.

---

### Task 4: scope-decomposition skill

**Files:**
- Create: `v2/skills/scope-decomposition/SKILL.md`

- [ ] **Step 1: Write the skill file**

Write `v2/skills/scope-decomposition/SKILL.md` with exactly this content:

````markdown
---
name: scope-decomposition
description: Use when a project idea or spec might be too large for a single spec/plan cycle — applies four concrete over-scope heuristics, and if any fire, splits the work into dependency-ordered sub-projects that each get their own spec → plan cycle.
author: Donal Moloney
tier: v2
supports: [brainstorming, writing-plans]
type: technique
chains-to: writing-plans
---

## Not this skill if

- The scope is plainly single-feature sized — proceed with v1 **brainstorming** directly.
- The spec is right-sized but possibly wrong — attack it with v2 **red-team-spec**; decomposition fixes size, not correctness.

# Scope Decomposition

## Purpose

v1 **brainstorming** says "if the project is too large for a single spec, help the user decompose" and v1 **writing-plans** warns that multi-subsystem specs "should have been broken into sub-project specs" — but neither says how to detect "too large" or how to split. This skill supplies the detection heuristics and the splitting procedure.

## Over-scope heuristics

Run all four against the one-paragraph project description. Any single "yes" means decompose.

| # | Heuristic | Yes when |
|---|---|---|
| 1 | Independent user flows | ≥2 flows where a user could complete one without the other existing (e.g., "chat" and "billing") |
| 2 | Distinct data stores | The description implies ≥2 unrelated schemas/stores owned by different parts of the system |
| 3 | "And"-junctions | The one-sentence summary needs ≥2 "and"s joining capabilities (not joining steps of one capability) |
| 4 | Plan-size projection | An honest task list would exceed ~10 tasks or one implementation plan document |

## Procedure

1. Write the project as one sentence. Count capabilities, not adjectives.
2. Run heuristics 1–4; record yes/no each.
3. If all four are "no": stop — return to v1 **brainstorming** for a normal single spec.
4. If any "yes": list candidate sub-projects, one per independent capability/flow.
5. For each pair of sub-projects, record the dependency: A-blocks-B, B-blocks-A, or independent. Justify each non-independent edge in one line (shared schema, shared API, shared component).
6. Order sub-projects: dependencies first; among independents, highest user value first.
7. Confirm the split and the order with the user.
8. Take ONLY the first sub-project into v1 **brainstorming** → v1 **writing-plans**. The rest wait — their specs will be better informed by what shipping the first one teaches.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Splitting by technical layer (frontend/backend/db) | Split by capability — each sub-project ships working, testable software end-to-end |
| Speccing all sub-projects upfront | Spec only the first; later specs improve with shipped knowledge |
| Counting steps of one flow as separate flows | "Sign up and verify email" is one flow; "sign up and export reports" is two |
| Treating the order as fixed | Re-run the dependency check after each sub-project ships; edges change |

## After

Verify the decomposition held: the first sub-project's spec stands alone (no "see other sub-project" references needed to implement it), then chain to v1 **writing-plans**.

PROVEN BY: the pasted heuristic table (4 rows, yes/no) plus, when decomposing, the dependency-ordered sub-project list confirmed by the user. Speccing a multi-"yes" project as one unit is invalid under this skill.
````

- [ ] **Step 2: Run the skill-lint checklist against the new file**

Apply all 7 checks from `v2/skills/skill-lint/SKILL.md`.
Expected: `Overall: PASS — all 7 structural checks green.` (Check 7: `brainstorming`, `writing-plans` in `v1/`; `red-team-spec` in `v2/skills/`.)

- [ ] **Step 3: Dispatch the skill-auditor agent**

Same dispatch as Task 1 Step 3, targeting this file. Expected: PASS; fix findings and re-lint if not.

---

### Task 5: reviewer-lenses skill

**Files:**
- Create: `v2/skills/reviewer-lenses/SKILL.md`

- [ ] **Step 1: Write the skill file**

Write `v2/skills/reviewer-lenses/SKILL.md` with exactly this content:

````markdown
---
name: reviewer-lenses
description: Use when requesting code review of significant or high-risk work and a single general-purpose reviewer would blur distinct concerns — dispatches parallel reviewers each locked to ONE lens (correctness, architecture, security, test quality, product/UX) and merges their findings.
author: Donal Moloney
tier: v2
supports: [requesting-code-review, dispatching-parallel-agents]
type: technique
chains-to: merge-parallel-results
---

## Not this skill if

- The change is small or routine — a single reviewer via v1 **requesting-code-review** is cheaper and sufficient.
- The artifact under attack is a spec or design doc — that is v2 **red-team-spec** (pre-implementation); lenses review code (post-implementation).

# Reviewer Lenses

## Purpose

A single reviewer asked to check "everything" anchors on whatever they notice first, and the other concerns get a skim. Lenses fix this by dispatching one reviewer per concern, each with a deliberately narrow prompt, in parallel per v1 **dispatching-parallel-agents** — then merging via v2 **merge-parallel-results**.

**Core rule:** each lens reviews ONLY its concern. A security reviewer who reports style nits has been prompted wrong.

## The five lenses

| Lens | Sole question | Reports |
|---|---|---|
| Correctness | Does the code do what the requirements say, including edge cases? | Logic errors, unhandled cases, off-by-ones, wrong behavior |
| Architecture | Do boundaries, dependencies, and ownership make sense? | Coupling, leaky abstractions, wrong-layer logic, god objects |
| Security | What can an adversary do with this change? | Injection, authz/authn gaps, secrets handling, unsafe input paths |
| Test quality | Would these tests catch the bugs that matter? | Untested branches, assertion-free tests, mock-heavy tests, missing failure cases |
| Product/UX | Does this serve the user's actual goal? | Confusing flows, surprising defaults, error messages a user can't act on |

## Procedure

1. Decide significance: multi-file change, new subsystem, security-adjacent surface, or anything heading to production review. If not significant, use v1 **requesting-code-review** alone.
2. Pick lenses. Default: correctness + architecture + test quality. Add security when input handling, authn/authz, or secrets are touched; add product/UX when user-facing behavior changed. Drop a lens only with a stated reason.
3. Dispatch one reviewer subagent per lens, in parallel, per v1 **dispatching-parallel-agents**. Each prompt contains: the diff or file list, the requirements, the lens's sole question from the table, and the instruction "report ONLY findings under this lens; if none, say none."
4. Collect all returns and merge via v2 **merge-parallel-results** — dedupe overlap, keep per-lens provenance on every finding.
5. Process the merged report via v1 **receiving-code-review** (unclear items go through clarification before implementation).

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| One agent given all five lenses "to save dispatches" | That's the anchoring problem again with extra steps — one lens per agent |
| All five lenses on every change | Lens count scales with risk; three is the default, five is for genuinely risky work |
| Discarding the lens label when merging | Provenance tells you who to re-ask and how to weigh conflicts |
| Treating "none" from a lens as a wasted dispatch | A clean security pass on an auth change is the most valuable line in the report |

## After

Verify lens discipline held: every merged finding carries its lens label, and any lens that found nothing said "none" explicitly. Then chain to v2 **merge-parallel-results** output handling and v1 **receiving-code-review**.

PROVEN BY: the merged report with per-lens provenance and an explicit entry (findings or "none") for every dispatched lens. A missing lens entry means a dispatch silently failed — re-dispatch it.
````

- [ ] **Step 2: Run the skill-lint checklist against the new file**

Apply all 7 checks from `v2/skills/skill-lint/SKILL.md`.
Expected: `Overall: PASS — all 7 structural checks green.` (Check 7: `requesting-code-review`, `dispatching-parallel-agents`, `receiving-code-review` in `v1/`; `merge-parallel-results`, `red-team-spec` in `v2/skills/`.)

- [ ] **Step 3: Dispatch the skill-auditor agent**

Same dispatch as Task 1 Step 3, targeting this file. Expected: PASS; fix findings and re-lint if not.

---

### Task 6: decision-ledger skill

**Files:**
- Create: `v2/skills/decision-ledger/SKILL.md`

- [ ] **Step 1: Write the skill file**

Write `v2/skills/decision-ledger/SKILL.md` with exactly this content:

````markdown
---
name: decision-ledger
description: Use when a design decision is approved or reversed during brainstorming, planning, or execution, and when resuming multi-session work — maintains an append-only DECISIONS.md so settled decisions survive across sessions instead of being re-derived or silently re-litigated.
author: Donal Moloney
tier: v2
supports: [brainstorming, writing-plans, executing-plans]
type: process
pairs-with: session-handoff
---

## Not this skill if

- You are transferring live working state to the very next session — that is v2 **session-handoff** (one-shot transfer); the ledger is durable memory across many sessions.
- The "decision" is an implementation detail nobody approved — code and specs record those; the ledger holds decisions a human ratified.

# Decision Ledger

## Purpose

Specs say what was decided; nothing records what was decided *against*, or why. Across sessions this rots: a fresh session re-proposes the rejected alternative, or quietly drifts from a settled choice. The ledger is an append-only log of ratified decisions — each with its rejected alternatives — read at resume time so settled questions stay settled.

**Core rule:** append-only. A reversed decision gets a new entry pointing at the old one; the old entry is never edited or deleted.

## Ledger location and entry format

The ledger lives at `docs/superpowers/DECISIONS.md` in the project (create on first entry). Each entry:

```markdown
## D-<NNN>: <decision in one line> — <YYYY-MM-DD>
- **Why:** <the reason in 1–2 sentences>
- **Rejected:** <alternative A> (<one-line reason>); <alternative B> (<one-line reason>)
- **Supersedes:** D-<MMM> (only when reversing a prior entry)
```

## Procedure

**Writing (during v1 brainstorming / writing-plans / executing-plans):**
1. When the user approves a design, a plan, or a mid-execution pivot, append one entry per ratified decision — including at least one rejected alternative each (a decision with no rejected alternative is usually a description, not a decision).
2. When a decision is reversed, append a new entry with `Supersedes:` — never edit the old one.

**Reading (at resume):**
3. On resuming work in a project that has a ledger, read it BEFORE proposing approaches.
4. If a new proposal contradicts a ledger entry, surface it explicitly: "This conflicts with D-<NNN> (<decision>). Reverse it?" — never silently re-litigate.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Logging every choice you make while coding | Only human-ratified decisions; the ledger is for what would otherwise be re-argued |
| Editing an entry that turned out wrong | Append a superseding entry; history is the point |
| Writing "Rejected: none" | Then it isn't a decision — drop the entry or find the alternative that was actually on the table |
| Reading the ledger only when confused | Read at every resume; confusion means it's already been re-litigated |

## After

Verify the ledger reflects this session: every user-ratified decision from the session has an entry, and no entry was edited in place.

PROVEN BY: the appended entries (with IDs) quoted at session end, and — on resume — the line "ledger read: D-001..D-<NNN>" before the first proposal. Proposing a rejected alternative without citing its entry is invalid under this skill.
````

- [ ] **Step 2: Run the skill-lint checklist against the new file**

Apply all 7 checks from `v2/skills/skill-lint/SKILL.md`.
Expected: `Overall: PASS — all 7 structural checks green.` (Check 7: `brainstorming`, `writing-plans`, `executing-plans` in `v1/`; `session-handoff` in `v2/skills/`.)

- [ ] **Step 3: Dispatch the skill-auditor agent**

Same dispatch as Task 1 Step 3, targeting this file. Expected: PASS; fix findings and re-lint if not.

---

### Task 7: deferred-work-tracker plugin

**Files:**
- Create: `v2/plugins/deferred-work-tracker/.claude-plugin/plugin.json`
- Create: `v2/plugins/deferred-work-tracker/hooks/hooks.json`
- Create: `v2/plugins/deferred-work-tracker/scripts/defer-item.sh`
- Create: `v2/plugins/deferred-work-tracker/scripts/check-deferred.sh`
- Create: `v2/plugins/deferred-work-tracker/README.md`

- [ ] **Step 1: Write the plugin manifest**

`v2/plugins/deferred-work-tracker/.claude-plugin/plugin.json`:

```json
{
  "name": "deferred-work-tracker",
  "version": "0.1.0",
  "description": "Logs review items deferred 'for later' to docs/superpowers/deferred.md and reminds about open items at session end, so deferred work cannot silently evaporate.",
  "author": {
    "name": "Donal Moloney"
  }
}
```

- [ ] **Step 2: Write the defer script**

`v2/plugins/deferred-work-tracker/scripts/defer-item.sh`:

```bash
#!/usr/bin/env bash
# Append a deferred work item to the project's deferred ledger.
# Usage: defer-item.sh "<source>" "<item text>"
#   source: where the item came from, e.g. "review of feature-x branch"
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: defer-item.sh \"<source>\" \"<item text>\"" >&2
  exit 1
fi

file="docs/superpowers/deferred.md"
mkdir -p "$(dirname "$file")"
[ -f "$file" ] || printf '# Deferred work\n\n' > "$file"
printf -- '- [ ] %s — %s (source: %s)\n' "$(date +%Y-%m-%d)" "$2" "$1" >> "$file"
echo "deferred: $2"
```

- [ ] **Step 3: Write the session-end check script**

`v2/plugins/deferred-work-tracker/scripts/check-deferred.sh`:

```bash
#!/usr/bin/env bash
# Stop-hook: report a count of open deferred items, if any. Fail-soft:
# silent when the ledger does not exist or has no open items.
file="docs/superpowers/deferred.md"
[ -f "$file" ] || exit 0
count=$(grep -c '^- \[ \]' "$file" 2>/dev/null || true)
if [ "${count:-0}" -gt 0 ] 2>/dev/null; then
  echo "deferred-work-tracker: $count open deferred item(s) in $file — review before closing out."
fi
exit 0
```

- [ ] **Step 4: Write the hook config**

`v2/plugins/deferred-work-tracker/hooks/hooks.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/check-deferred.sh"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 5: Write the README with v2 frontmatter discipline**

`v2/plugins/deferred-work-tracker/README.md`:

```markdown
---
name: deferred-work-tracker
tier: v2
supports: [receiving-code-review, finishing-a-development-branch]
type: plugin
---

# deferred-work-tracker

v1 **receiving-code-review** says "Note minor issues for later" — with no mechanism,
"later" means never. This plugin is the mechanism.

- `scripts/defer-item.sh "<source>" "<item>"` appends the item to
  `docs/superpowers/deferred.md` with date and source.
- A `Stop` hook (`scripts/check-deferred.sh`) reports a count of open
  (`- [ ]`) items at session end. Fail-soft: silent if the ledger is absent.

Items are plain markdown checkboxes — close one by ticking it (`- [x]`) in
`docs/superpowers/deferred.md`.

To verify the install: run both scripts directly (see smoke test in the
implementation plan); the hook requires no state beyond the ledger file.
```

- [ ] **Step 6: Make scripts executable and smoke-test in a temp dir**

```bash
chmod +x v2/plugins/deferred-work-tracker/scripts/*.sh
tmp=$(mktemp -d) && cd "$tmp"
bash "$OLDPWD/v2/plugins/deferred-work-tracker/scripts/defer-item.sh" "review of feature-x" "rename helper for clarity"
cat docs/superpowers/deferred.md
bash "$OLDPWD/v2/plugins/deferred-work-tracker/scripts/check-deferred.sh"
cd "$OLDPWD" && rm -rf "$tmp"
```

Expected output (date will be the run date):
```
deferred: rename helper for clarity
# Deferred work

- [ ] 2026-06-10 — rename helper for clarity (source: review of feature-x)
deferred-work-tracker: 1 open deferred item(s) in docs/superpowers/deferred.md — review before closing out.
```

Also verify fail-soft: run `check-deferred.sh` from a directory with no `docs/superpowers/deferred.md`. Expected: no output, exit 0.

- [ ] **Step 7: Validate plugin structure**

Dispatch the `plugin-dev:plugin-validator` agent on `v2/plugins/deferred-work-tracker/`.
Expected: structure valid (manifest parses, hook config well-formed, scripts present). Fix any findings.

---

### Task 8: verify-command-suggester plugin

**Files:**
- Create: `v2/plugins/verify-command-suggester/.claude-plugin/plugin.json`
- Create: `v2/plugins/verify-command-suggester/scripts/suggest.sh`
- Create: `v2/plugins/verify-command-suggester/commands/verify-commands.md`
- Create: `v2/plugins/verify-command-suggester/README.md`

- [ ] **Step 1: Write the plugin manifest**

`v2/plugins/verify-command-suggester/.claude-plugin/plugin.json`:

```json
{
  "name": "verify-command-suggester",
  "version": "0.1.0",
  "description": "Detects the project type from marker files and suggests canonical verification commands (never runs them), so the verification gate never stalls on 'I don't know what command to run'.",
  "author": {
    "name": "Donal Moloney"
  }
}
```

- [ ] **Step 2: Write the detection script**

`v2/plugins/verify-command-suggester/scripts/suggest.sh`:

```bash
#!/usr/bin/env bash
# Suggest verification commands for the current directory's project.
# SUGGESTS ONLY — never executes any of the commands it prints.
set -u
found=0

if [ -f package.json ]; then
  found=1
  echo "Node project (package.json):"
  for s in test lint build typecheck; do
    if grep -q "\"$s\"[[:space:]]*:" package.json; then
      echo "  npm run $s"
    fi
  done
fi

if [ -f pyproject.toml ]; then
  found=1
  echo "Python project (pyproject.toml):"
  echo "  pytest"
  echo "  ruff check ."
fi

if [ -f Cargo.toml ]; then
  found=1
  echo "Rust project (Cargo.toml):"
  echo "  cargo test"
  echo "  cargo clippy"
fi

if [ -f go.mod ]; then
  found=1
  echo "Go project (go.mod):"
  echo "  go test ./..."
  echo "  go vet ./..."
fi

if [ -f Makefile ]; then
  found=1
  echo "Makefile targets:"
  grep -E '^(test|check|lint)[A-Za-z_-]*:' Makefile | cut -d: -f1 | sort -u | sed 's/^/  make /'
fi

if [ "$found" -eq 0 ]; then
  echo "No known project marker found (package.json, pyproject.toml, Cargo.toml, go.mod, Makefile)."
  echo "Ask the user for the project's verification command."
fi
exit 0
```

- [ ] **Step 3: Write the slash command**

`v2/plugins/verify-command-suggester/commands/verify-commands.md`:

```markdown
---
description: Suggest verification commands for the current project (detection only — never runs them)
---

Run `${CLAUDE_PLUGIN_ROOT}/scripts/suggest.sh` from the project root with the
Bash tool and present its output to the user verbatim.

Then, if a verification gate (v1 verification-before-completion or v2
loop-until-green) is active, use the suggested commands as the gate's
verification commands — running them is the gate's job, not this command's.
If the script reports no known marker, ask the user for the project's
verification command and do not guess.
```

- [ ] **Step 4: Write the README with v2 frontmatter discipline**

`v2/plugins/verify-command-suggester/README.md`:

```markdown
---
name: verify-command-suggester
tier: v2
supports: [verification-before-completion]
type: plugin
---

# verify-command-suggester

v1 **verification-before-completion** assumes the verification command is
obvious. It often isn't. This plugin detects the project type from marker
files and suggests the canonical commands — `/verify-commands` exposes it.

| Marker | Suggestions |
|---|---|
| package.json | `npm run <script>` for each of test/lint/build/typecheck that exists |
| pyproject.toml | pytest, ruff check . |
| Cargo.toml | cargo test, cargo clippy |
| go.mod | go test ./..., go vet ./... |
| Makefile | `make <target>` for each test*/check*/lint* target |

It suggests only — it never executes the commands; the verification gate
(v1 verification-before-completion, or v2 loop-until-green) runs them.
Fail-soft: with no marker found it says so and defers to the user rather
than guessing. Also referenced by v2 **loop-until-green** as a source for
its exit-condition commands.
```

- [ ] **Step 5: Make the script executable and smoke-test both paths**

```bash
chmod +x v2/plugins/verify-command-suggester/scripts/suggest.sh
# Negative path: this repo has no marker files at its root
bash v2/plugins/verify-command-suggester/scripts/suggest.sh
```

Expected:
```
No known project marker found (package.json, pyproject.toml, Cargo.toml, go.mod, Makefile).
Ask the user for the project's verification command.
```

```bash
# Positive path: synthetic Node project
tmp=$(mktemp -d) && cd "$tmp"
printf '{ "scripts": { "test": "jest", "lint": "eslint ." } }\n' > package.json
bash "$OLDPWD/v2/plugins/verify-command-suggester/scripts/suggest.sh"
cd "$OLDPWD" && rm -rf "$tmp"
```

Expected:
```
Node project (package.json):
  npm run test
  npm run lint
```

- [ ] **Step 6: Validate plugin structure**

Dispatch the `plugin-dev:plugin-validator` agent on `v2/plugins/verify-command-suggester/`.
Expected: structure valid. Fix any findings.

---

### Task 9: Tier-wide verification

**Files:**
- Verify (no modifications): all of `v2/skills/*/SKILL.md`, `v2/plugins/*/`

- [ ] **Step 1: Verify the coverage matrix**

List every `supports:` value across all 12 v2 skills and both plugin READMEs; confirm each resolves to a real `v1/<name>/` directory, and confirm the three previously-unsupported v1 skills now covered are: `receiving-code-review` (Task 1, Task 7), `requesting-code-review` (Tasks 1, 5), `subagent-driven-development` (Task 2). `using-superpowers` remains intentionally unsupported per the spec's out-of-scope section.

- [ ] **Step 2: Bulk audit the v2 tier**

Dispatch the `skill-auditor` agent with prompt: "Audit the entire v2 tier (all skills in v2/skills/ and plugins in v2/plugins/) against the v2 tier rules in CLAUDE.md: new identities only, supports: naming real v1 skills, no duplication of v1 content. Report per-skill pass/fail with evidence."
Expected: PASS for all 12 skills + 2 plugins. Fix any findings in the flagged file and re-run that file's skill-lint checklist.

- [ ] **Step 3: Confirm done against the spec**

Re-read `docs/superpowers/specs/2026-06-10-v2-additions-design.md` section by section and confirm each of the 8 items exists, passes its validation, and respects its stated boundaries. Per v1 **verification-before-completion**: paste the evidence (lint reports, audit results, smoke-test output) before claiming the plan complete.
