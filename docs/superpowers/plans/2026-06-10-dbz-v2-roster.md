# Dragon Ball v2 Roster Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add five Dragon Ball-named, gap-first v2 supporting skills (scouter, shenron-wish, zenkai-boost, instant-transmission, senzu-bean), register them in `v2/README.md`, and pass a skill-auditor review.

**Architecture:** Each skill is one new directory `v2/skills/<name>/SKILL.md` following the existing v2 house style (frontmatter with `tier`/`supports`/`type`/`chains-to`/`pairs-with`, then `## Not this skill if`, `# Title`, `## Purpose`, `## Triggers`, mechanism sections with tables, `## Pitfalls`, `## After`). Content references v1 skills, never duplicates them.

**Tech Stack:** Markdown only. No code, no tests-as-code — verification is frontmatter/structure checks via `grep`, plus the project's `skill-auditor` agent.

**Spec:** `docs/superpowers/specs/2026-06-10-dbz-v2-roster-design.md`

**Note on commits:** This project is not a git repository (per CLAUDE.md). All "commit" steps are omitted. Do not run `git init` — if the user asks to push later, the global GitHub push convention applies.

---

### Task 1: `scouter` skill

**Files:**
- Create: `v2/skills/scouter/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/scouter/SKILL.md` with exactly this content:

````markdown
---
name: scouter
description: Use before engaging any non-trivial task — takes a power-level reading (scope, risk, unknowns), maps it to a response band, and names which v1 skills to invoke; signals decomposition when the reading is over 9000.
author: Donal Moloney
tier: v2
supports: [using-superpowers, writing-plans, brainstorming]
type: process
chains-to: brainstorming
pairs-with: writing-plans
---

## Not this skill if

- The task is a single trivially-reversible edit — just do it and verify.
- The user already supplied an explicit plan — go to v1 **executing-plans**.

# Scouter

## Purpose

Gauge a task before engaging it. Wrong-sized responses waste work in both directions: planning ceremony for a one-line fix, or diving head-first into a five-subsystem feature. The scouter reading picks the response band *before* any work starts.

Supports v1 **using-superpowers** (the reading names which skills to invoke), v1 **writing-plans** (medium band routes there), and v1 **brainstorming** (over-9000 band routes to its decomposition guidance).

## Triggers

**Use when:**
- Starting any task that is not obviously trivial
- "Just add X" requests where X's true size is unclear
- Deciding whether to plan, brainstorm, or act directly

**Don't use when:**
- Mid-task — the engagement decision is already made
- An explicit plan exists

## The reading

Score three dials, each 1–3:

| Dial | 1 | 2 | 3 |
|---|---|---|---|
| **Scope** | one file | one module | cross-cutting |
| **Risk** | trivially reversible | revert needs care | hard to undo (data, public API, release) |
| **Unknowns** | none | one open question | several questions you can't answer |

Sum the dials: power level 3–9.

## Response bands

| Reading | Band | Action |
|---|---|---|
| 3–4 | **Low** | Act directly. Finish with v1 **verification-before-completion**. |
| 5–7 | **Medium** | Plan first: v1 **writing-plans**, then v1 **executing-plans**. |
| 8–9, or multiple independent subsystems in the request | **Over 9000** | Stop. The task is several projects in a trench coat — decompose via v1 **brainstorming**'s decomposition guidance; each sub-project gets its own reading. |

Any single dial at 3 forces at least **Medium** regardless of sum.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Eyeballing "looks easy" without a reading | Score all three dials explicitly |
| Letting scope creep without re-reading | Re-run the scouter when the task mutates |
| Over-9000 task pushed through one plan | Decompose first; one spec → plan → implement cycle per sub-project |
| Treating the reading as final | Scouters break — if mid-task evidence contradicts the band, re-read and escalate |

## After

State the reading in one line before starting work, e.g.:

`SCOUTER: scope 2 / risk 1 / unknowns 2 = 5 → Medium → writing-plans`

Then invoke the band's skill.
````

- [x] **Step 2: Verify frontmatter and structure**

Run:
```bash
head -10 v2/skills/scouter/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/scouter/SKILL.md
```
Expected: `6` then `1`.

---

### Task 2: `shenron-wish` skill

**Files:**
- Create: `v2/skills/shenron-wish/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/shenron-wish/SKILL.md` with exactly this content:

````markdown
---
name: shenron-wish
description: Use when writing the task prompt for any subagent dispatch — the dragon grants exactly what you ask and nothing more, so the wish must state context, one task, forbidden actions, done criteria, and report format before summoning.
author: Donal Moloney
tier: v2
supports: [subagent-driven-development, dispatching-parallel-agents]
type: technique
chains-to: merge-parallel-results
pairs-with: dispatching-parallel-agents
---

## Not this skill if

- You are doing the work yourself in-session — no summoning, no wish.
- The agent is interactive and can ask you questions mid-task — wishes are for fire-and-forget dispatch.

# Shenron Wish

## Purpose

Subagents, like Shenron, grant exactly what you ask — no more. A vague wish wastes the summoning: the agent guesses missing context, does adjacent work you didn't want, and reports in a shape you can't use. The wish template forces precision before dispatch.

Supports v1 **subagent-driven-development** (every per-task dispatch is a wish) and v1 **dispatching-parallel-agents** (each parallel agent gets its own complete wish).

## Triggers

**Use when:**
- About to dispatch any subagent with a task prompt
- A previous agent came back with the wrong thing, did too much, or reported uselessly

**Don't use when:**
- Working inline in the current session

## The five clauses

Every wish contains all five. Missing any clause = not ready to summon.

| Clause | Contains | Failure it prevents |
|---|---|---|
| 1. **Context** | Everything the agent cannot infer: file paths, conventions, prior decisions | Agent re-derives (wrongly) what you already know |
| 2. **Task** | Exactly one task — one wish per dragon | Agent juggles goals and finishes none |
| 3. **Forbidden actions** | Side effects the wish must not cause: files not to touch, no new deps, no API changes | "Helpful" collateral edits |
| 4. **Done criteria** | Objectively checkable conditions: command + expected output | Agent (and you) can't tell when it's done |
| 5. **Report format** | What comes back, in what shape | Unusable wall-of-text reports |

**Hard rule:** if you cannot write clause 4, you don't understand the task well enough to delegate it. Figure out the done criterion first.

## Wish template

```
CONTEXT: <paths, conventions, decisions the agent can't infer>
TASK: <the one thing>
FORBIDDEN: <files/actions off-limits>
DONE WHEN: <command to run + expected output>
REPORT: <exact shape of what to send back>
```

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| "Fix the tests" | Name the failing tests, the suspected area, and the green command |
| Two tasks in one wish | Summon twice — one wish per dragon |
| Assuming the agent sees your conversation | It sees only the wish; put everything needed in CONTEXT |
| No FORBIDDEN clause | Always state side-effect limits; agents default to "helpful" |
| Accepting a report that skips DONE WHEN evidence | Re-summon or verify yourself before integrating |

## After

When agents return, integrate via v2 **merge-parallel-results** (parallel dispatch) or v1 **subagent-driven-development**'s review stage (sequential). Verify the DONE WHEN evidence before accepting any result.
````

- [x] **Step 2: Verify frontmatter and structure**

Run:
```bash
head -10 v2/skills/shenron-wish/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/shenron-wish/SKILL.md
```
Expected: `6` then `1`.

---

### Task 3: `zenkai-boost` skill

**Files:**
- Create: `v2/skills/zenkai-boost/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/zenkai-boost/SKILL.md` with exactly this content:

````markdown
---
name: zenkai-boost
description: Use immediately after any bug fix is verified — converts the failure into permanent strength by capturing a regression test, recording a one-line lesson, and sweeping for sibling instances before the fix is considered closed.
author: Donal Moloney
tier: v2
supports: [systematic-debugging, test-driven-development]
type: process
chains-to: verification-before-completion
pairs-with: loop-until-green
---

## Not this skill if

- The failure was environmental or flaky with no code-level cause — fix the environment, note it, move on.
- The bug is still unfixed — finish v1 **systematic-debugging** first; zenkai happens after recovery, not during the fight.

# Zenkai Boost

## Purpose

Saiyans come back stronger from every near-death. A bug fix that leaves no regression test, no recorded lesson, and unswept siblings is a recovery without the boost — the same failure can hurt you again. This skill makes the boost mandatory before the fix is closed.

Supports v1 **systematic-debugging** (its root-cause output feeds all three steps) and v1 **test-driven-development** (the regression test follows the red–green discipline).

## Triggers

**Use when:**
- A bug fix has just been verified
- A production incident or review finding has been resolved
- You catch yourself about to move on right after "it works now"

**Don't use when:**
- The fix isn't verified yet
- The failure had no code-level cause

## The three-step boost

### 1. Regression test

Write the test that would have caught this bug.
- Run it against the pre-fix code (stash the fix, or check out the prior revision): must **FAIL**.
- Run it against the fixed code: must **PASS**.

A regression test that never failed proves nothing.

### 2. One-line lesson

Record the *class* of mistake — not the instance — in the project's gotchas (CLAUDE.md or equivalent):

`<date>: <bug class> — <how to avoid>`

Skip recording only if an equivalent lesson already exists.

### 3. Sibling sweep

The same root cause usually has siblings. Search for the pattern the root cause implies (same misused API, same off-by-one shape, same unchecked input) and list every hit. Fix or ticket each one — silently ignoring a found sibling voids the boost.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Regression test written but never run against broken code | Verify FAIL-then-PASS; red first |
| Lesson describes the instance ("fixed null in parser.py") | Record the class ("parser entry points must null-check input") |
| Sweep skipped because "this was a one-off" | Run the search anyway; the grep is cheap, the second incident isn't |
| Boost steps done but fix not re-verified | Chain to v1 **verification-before-completion** |

## After

Invoke v1 **verification-before-completion** with the boost evidence attached: regression test name + FAIL/PASS runs, lesson location, sibling-sweep search used and hits found.
````

- [x] **Step 2: Verify frontmatter and structure**

Run:
```bash
head -10 v2/skills/zenkai-boost/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/zenkai-boost/SKILL.md
```
Expected: `6` then `1`.

---

### Task 4: `instant-transmission` skill

**Files:**
- Create: `v2/skills/instant-transmission/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/instant-transmission/SKILL.md` with exactly this content:

````markdown
---
name: instant-transmission
description: Use when a failure's location in the code is unknown — locks onto a reproducible failure signal and teleports to the faulty commit or line via signature grep, git bisect, blame, and binary-search instrumentation before the full debugging loop begins.
author: Donal Moloney
tier: v2
supports: [systematic-debugging]
type: technique
chains-to: systematic-debugging
pairs-with: loop-until-green
---

## Not this skill if

- The fault location is already known — go straight to v1 **systematic-debugging**.
- There is no reproducible failure signal — build a repro first; no ki signature, no teleport.

# Instant Transmission

## Purpose

Goku can't teleport without a ki signature to lock onto. Likewise: localization needs a reproducible failure signal, and with one you can jump straight to the fault instead of wandering the codebase. This is the cheap localization pass that runs *before* v1 systematic-debugging's hypothesis loop, so hypotheses start from a located fault, not a whole repo.

Supports v1 **systematic-debugging** — enters its workflow at the hypothesis phase with the fault already localized.

## Triggers

**Use when:**
- "It's broken somewhere" — failing behavior, unknown location
- A regression appeared and you don't know which change caused it
- Stack traces point into framework code, not yours

**Don't use when:**
- The faulty line/commit is already identified
- The failure can't be reproduced on demand

## Prerequisite: the ki signature

A command (or script) that deterministically shows the failure, plus the exact failure text. If the failure is intermittent, tighten the repro first (fixed seed, pinned data, repeated runs) until it fires reliably. **No repro = no teleport.**

## The localization ladder

Run the cheapest rung first; stop at the first rung that lands.

| Rung | When | How |
|---|---|---|
| 1. **Signature grep** | An error message exists | Grep the exact message/error code in the codebase; the throw site bounds the search |
| 2. **Bisect** | It worked before | `git bisect run <repro-script>` — script exits 0 on pass, non-zero on fail; lands on the exact commit |
| 3. **Blame the window** | Breakage is recent, bisect impractical | `git diff <last-good>..HEAD -- <suspect-paths>`, then `git blame` the implicated lines |
| 4. **Binary-search instrumentation** | Nothing above lands | Log at the midpoint of the suspect path; halve toward the fault each run |

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Teleporting without a repro | Build the ki signature first |
| Bisecting with a flaky repro | Make the repro script deterministic, or bisect lands on noise |
| Reading the whole module "to understand it" | Run the ladder; read only what the landed rung implicates |
| Treating the landed location as the root cause | It's the *location* — hand it to v1 **systematic-debugging** for cause analysis |

## After

Hand off to v1 **systematic-debugging** at its hypothesis phase with: the ki signature (repro command + failure text), the rung that landed, and the localized commit/file/line.
````

- [x] **Step 2: Verify frontmatter and structure**

Run:
```bash
head -10 v2/skills/instant-transmission/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/instant-transmission/SKILL.md
```
Expected: `6` then `1`.

---

### Task 5: `senzu-bean` skill

**Files:**
- Create: `v2/skills/senzu-bean/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/senzu-bean/SKILL.md` with exactly this content:

````markdown
---
name: senzu-bean
description: Use when resuming work mid-task after context compaction, a crash, or a long interruption — rebuilds true working state from durable artifacts (plan doc, git state, test runs) instead of trusting recollection.
author: Donal Moloney
tier: v2
supports: [executing-plans]
type: process
chains-to: executing-plans
pairs-with: session-handoff
---

## Not this skill if

- A current v2 **session-handoff** document exists — read it first; senzu-bean fills gaps, it doesn't replace a handoff.
- You're starting fresh work, not resuming — there is no state to recover.

# Senzu Bean

## Purpose

A senzu bean restores full strength mid-fight. After context compaction, a crash, or days away, your memory of the task is the least reliable source available — the artifacts are the truth. This skill rehydrates working state from artifacts and pinpoints exactly where to resume.

Supports v1 **executing-plans** (resumes plan execution at the verified-correct step). Pairs with v2 **session-handoff** — a handoff doc is the best artifact; this skill is the recovery path when one is missing or stale.

## Triggers

**Use when:**
- Resuming after context compaction or a session crash
- Returning to a task after an interruption long enough to doubt the details
- A plan's checkboxes don't obviously match the workspace

**Don't use when:**
- Fresh task, nothing to recover
- A current handoff doc already answers "where was I?"

## The rehydration checklist

Run all four steps; artifacts over recollection at every one.

1. **Plan doc** — read it fully. Note which steps are checked off. Checked ≠ done; it's a claim to verify.
2. **Workspace state** — `git status`, `git diff`, `git log --oneline -10` (or non-git equivalents). What was *actually* changed?
3. **Ground truth** — run the test suite (or the plan's verification commands). What *actually* passes?
4. **Diff claimed vs actual** — compare the plan's checkmarks against steps 2–3. The first discrepancy is the resume point.

| Discrepancy | Meaning | Action |
|---|---|---|
| Checked, but workspace/tests disagree | Step claimed but not done (or regressed) | Uncheck; resume here |
| Unchecked, but workspace shows it done | Step done but unrecorded | Verify, then check it off |
| All consistent | State is clean | Resume at the first unchecked step |

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| "I remember where I was" | Memory is the degraded component — run the checklist |
| Trusting checkmarks without verifying | Re-run the verification command for the last checked steps |
| Resuming at the last checked step by default | Resume at the first *discrepancy*, which may be earlier |
| Recovering state but not recording it | Update the plan's checkboxes to match verified reality before resuming |

## After

With the resume point verified, continue under v1 **executing-plans**. If you expect to stop again soon, write a v2 **session-handoff** doc now — eating a senzu bean is the fallback, not the plan.
````

- [x] **Step 2: Verify frontmatter and structure**

Run:
```bash
head -10 v2/skills/senzu-bean/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/senzu-bean/SKILL.md
```
Expected: `6` then `1`.

---

### Task 6: Register the five skills in `v2/README.md`

**Files:**
- Modify: `v2/README.md` (the "Current skills" table, lines 19–26)

- [x] **Step 1: Append the five rows to the table**

In `v2/README.md`, replace:

```markdown
| `spike-in-worktree` | using-git-worktrees, finishing-a-development-branch |
```

with:

```markdown
| `spike-in-worktree` | using-git-worktrees, finishing-a-development-branch |
| `scouter` | using-superpowers, writing-plans, brainstorming |
| `shenron-wish` | subagent-driven-development, dispatching-parallel-agents |
| `zenkai-boost` | systematic-debugging, test-driven-development |
| `instant-transmission` | systematic-debugging |
| `senzu-bean` | executing-plans |
```

Also add the missing existing row for `review-clarification-gate` (it is in the folder but absent from the table). Replace:

```markdown
| `red-team-spec` | brainstorming, writing-plans, dispatching-parallel-agents |
```

with:

```markdown
| `red-team-spec` | brainstorming, writing-plans, dispatching-parallel-agents |
| `review-clarification-gate` | receiving-code-review, requesting-code-review |
```

- [x] **Step 2: Verify the table is complete**

Run:
```bash
grep -c '^| `' v2/README.md
```
Expected: `12` (the header and separator rows don't start with ``| ` ``, so only skill rows match). Confirm visually that all 12 skill directories under `v2/skills/` have a row.

---

### Task 7: Audit the five new skills

- [x] **Step 1: Run the skill-auditor agent**

Dispatch the project's `skill-auditor` agent with this prompt:

```
Audit these five new v2 skills against the project's tier rules (CLAUDE.md) and
the v2 conventions (v2/README.md):

- v2/skills/scouter/SKILL.md
- v2/skills/shenron-wish/SKILL.md
- v2/skills/zenkai-boost/SKILL.md
- v2/skills/instant-transmission/SKILL.md
- v2/skills/senzu-bean/SKILL.md

Check: frontmatter has name, description (states WHEN), author, tier: v2,
supports: naming v1 skills, type; body opens with "## Not this skill if";
content references v1 skills rather than duplicating them; no skill duplicates
an upstream obra skill identity. Also verify v2/README.md lists all five.
Report findings per skill: BLOCKING / WARNING / OK.
```

Expected: report with no BLOCKING findings.

- [x] **Step 2: Fix any BLOCKING findings and re-audit**

If the auditor reports BLOCKING findings, fix each one in the affected SKILL.md, then re-dispatch the auditor on the affected files only. Repeat until zero BLOCKING findings. (WARNING-level findings: fix if quick, otherwise note them to the user.)
