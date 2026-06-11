# Dragon Ball v2 Roster — Batch 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the four deferred Dragon Ball-named v2 skills (dragon-radar, kaioken, gravity-chamber, fusion-dance), register them in `v2/README.md`, and pass a skill-auditor review.

**Architecture:** Same as batch 1 — one directory `v2/skills/<name>/SKILL.md` per skill, v2 house style (frontmatter with `tier`/`supports`/`type`/`chains-to`/`pairs-with`, then `## Not this skill if`, `# Title`, `## Purpose`, `## Triggers`, mechanism sections with tables, `## Pitfalls`, `## After`). Content references v1 skills, never duplicates them.

**Tech Stack:** Markdown only. Verification is frontmatter/structure checks via `grep`, plus the project's `skill-auditor` agent.

**Spec:** `docs/superpowers/specs/2026-06-10-dbz-v2-roster-design.md` (Batch 2 addendum)

**Note on commits:** This project is not a git repository (per CLAUDE.md). All "commit" steps are omitted. Do not run `git init`.

---

### Task 1: `dragon-radar` skill

**Files:**
- Create: `v2/skills/dragon-radar/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/dragon-radar/SKILL.md` with exactly this content:

````markdown
---
name: dragon-radar
description: Use before claiming a multi-site change complete — when a fix, rename, or refactor must touch every instance of a pattern, the radar enumerates all occurrences first, tracks each to resolution, and re-sweeps to zero before done is allowed.
author: Donal Moloney
tier: v2
supports: [verification-before-completion, systematic-debugging]
type: technique
chains-to: verification-before-completion
pairs-with: zenkai-boost
---

## Not this skill if

- The change is single-site by construction (one function, one call site) — just verify it.
- You can't name the pattern you're hunting — define it first; a radar needs a signature to track.

# Dragon Radar

## Purpose

There are always seven dragon balls — the radar's job is to show the count so you know when you have them all. Multi-site changes fail by under-enumeration: the fix lands on the four obvious instances and the fifth ships broken. Enumerate first, fix second, re-sweep to zero.

Supports v1 **verification-before-completion** (the zero-result re-sweep is the completion evidence) and v1 **systematic-debugging** (root-cause classes often have multiple instances; the radar finds them all).

## Triggers

**Use when:**
- Renames, signature changes, API migrations — anything "change every place that does X"
- A bug's root cause is a *pattern* (misused API, copied snippet), not a single line
- Reviewing whether a "fixed everywhere" claim is actually everywhere

**Don't use when:**
- The change is provably single-site
- The pattern can't yet be expressed as something searchable

## The sweep

### 1. Define the signature

What exactly identifies an occurrence? Write it down before searching — literal string, regex, AST shape, or "calls to f with 2 args".

### 2. Multi-band scan

One grep is one band; dragon balls hide in others. Sweep every band that applies:

| Band | Finds |
|---|---|
| Literal grep | Direct uses |
| Synonyms & aliases | Re-exports, wrapper names, deprecated spellings |
| Dynamic construction | String-built names, reflection, config keys |
| Non-code | Docs, configs, CI scripts, templates, tests |

### 3. The ledger

List every hit with file:line. For each: **fixed**, or **excluded** with a one-line reason. Silent omission is the failure mode the radar exists to prevent.

### 4. Re-sweep to zero

After the changes, run the same scans again. Expected result: zero unhandled occurrences. A re-sweep that finds a new hit goes back to step 3.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Fix-as-you-find without enumerating | Build the full ledger first, then fix |
| One literal grep declared exhaustive | Sweep synonyms, dynamic construction, and non-code bands |
| Hits skipped without a note | Every ledger row is fixed or excluded-with-reason |
| Claiming done from memory of the ledger | Re-sweep; the radar, not recollection, says all seven are found |

## After

Attach the ledger and the zero-result re-sweep output as evidence to v1 **verification-before-completion**. If the occurrences came from a bug class, v2 **zenkai-boost**'s sibling sweep is this skill in miniature — add the regression test while you're there.
````

- [x] **Step 2: Verify frontmatter and structure**

Run:
```bash
head -10 v2/skills/dragon-radar/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/dragon-radar/SKILL.md
```
Expected: `6` then `1`.

---

### Task 2: `kaioken` skill

**Files:**
- Create: `v2/skills/kaioken/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/kaioken/SKILL.md` with exactly this content:

````markdown
---
name: kaioken
description: Use when normal effort has stalled after real attempts — applies a declared, budgeted burst of escalation (more parallel agents, deeper search, wider review) with a mandatory cooldown verification, because an unbounded power-up burns the session.
author: Donal Moloney
tier: v2
supports: [dispatching-parallel-agents, systematic-debugging]
type: process
chains-to: verification-before-completion
pairs-with: loop-until-green
---

## Not this skill if

- Normal effort hasn't actually been tried yet — escalation before a baseline attempt is just waste.
- The blocker is missing information only the user has — ask; no multiplier fixes an unknown requirement.

# Kaioken

## Purpose

Kaioken multiplies power at a cost to the body — used briefly and deliberately it wins fights; sustained, it breaks you. Effort escalation works the same way: more agents, broader sweeps, and deeper reviews are powerful and expensive (tokens, time, context). This skill makes escalation explicit — declared multiplier, fixed budget, forced cooldown — instead of an unbounded flail.

Supports v1 **dispatching-parallel-agents** (the multiplier is often "fan out the search") and v1 **systematic-debugging** (escalation path when the loop stalls).

## Triggers

**Use when:**
- Two solid normal-effort attempts at the same obstacle have failed
- A deadline-critical investigation needs breadth now, at known cost
- v2 **loop-until-green** is not converging and needs a stronger round

**Don't use when:**
- No baseline attempt exists
- The blocker is a decision or fact only the user can supply

## The burst protocol

Declare all four fields before powering up:

| Field | Example |
|---|---|
| **Trigger** | "Two attempts at localizing the flake failed" |
| **Multiplier** | x3 — three parallel agents on disjoint hypotheses |
| **Budget** | One round; results reviewed before any second burst |
| **Exit** | Converged (cause found) or budget spent — whichever first |

Escalation menu — pick the cheapest rung that can plausibly work:

1. Widen the search fan-out
2. Add parallel agents on *disjoint* slices
3. Deepen per-slice scrutiny
4. Bring a stronger reviewer to the judgment step

## Cooldown — mandatory

After the burst, before anything else:

1. Verify what the burst produced — run the checks; bursts produce claims, not facts.
2. Record what the multiplier actually bought. If nothing, the next burst needs a different *kind* of escalation, not a bigger number.
3. Return to normal effort. Back-to-back bursts without cooldown are the flail this skill exists to prevent.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Escalating on the first failure | Two genuine baseline attempts first |
| "x20!" — max everything at once | Cheapest plausible rung of the menu |
| Burst with no declared exit | Budget and exit condition written before powering up |
| Skipping cooldown verification | Burst output is unverified claims until checked |

## After

Cooldown's verification step hands its evidence to v1 **verification-before-completion**. If bursts keep failing on the same obstacle, stop multiplying — the task is mis-framed; return to v1 **systematic-debugging**'s root-cause discipline or escalate to the user.
````

- [x] **Step 2: Verify frontmatter and structure**

Run:
```bash
head -10 v2/skills/kaioken/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/kaioken/SKILL.md
```
Expected: `6` then `1`.

---

### Task 3: `gravity-chamber` skill

**Files:**
- Create: `v2/skills/gravity-chamber/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/gravity-chamber/SKILL.md` with exactly this content:

````markdown
---
name: gravity-chamber
description: Use when the happy-path suite passes but confidence is low — trains the code under increased gravity by escalating test rigor in graded levels (edge matrix, repetition for flakes, property-based and adversarial inputs).
author: Donal Moloney
tier: v2
supports: [test-driven-development, verification-before-completion]
type: technique
chains-to: verification-before-completion
pairs-with: loop-until-green
---

## Not this skill if

- The basic suite isn't green yet — get to 1g first via v1 **test-driven-development** and v2 **loop-until-green**.
- The code is a throwaway spike — match rigor to lifespan.

# Gravity Chamber

## Purpose

Training at 1g proves you can stand. Code that has only seen its happy-path suite has only stood at 1g. The chamber raises gravity in graded levels until the code has survived the conditions production will actually apply — and each level is a deliberate, recorded choice, not vague "more testing".

Supports v1 **test-driven-development** (each level's failures become new red tests) and v1 **verification-before-completion** (the gravity level reached is part of the completion evidence).

## Triggers

**Use when:**
- The suite is green but the change touches parsing, money, time, concurrency, or user input
- "It works on my input" needs to become "it works"
- Deciding how much testing is enough for a risky change

**Don't use when:**
- Still red at 1g
- Rigor would exceed the code's lifespan or blast radius

## Gravity levels

Climb in order; stop at the level the change's risk justifies. Record the level reached.

| Level | Training | Catches |
|---|---|---|
| **1g** | Happy-path suite green | Basic correctness |
| **10g** | Edge matrix: empty, one, many, max, malformed, unicode, negative, zero, boundary ±1 | Off-by-ones, unhandled shapes |
| **50g** | Repetition: run N times, shuffled order, parallel | Flakes, ordering deps, shared state |
| **100g** | Property-based / fuzz: invariants over generated inputs | The cases you couldn't think of |
| **150g** | Adversarial: inputs crafted to break assumptions (injection shapes, huge payloads, concurrent mutation) | Security-adjacent and hostile conditions |

Every failure at any level: write it as a permanent red test (v1 **test-driven-development**), fix, re-run the level.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| "Added more tests" with no level stated | Name the level: "trained to 50g" |
| Jumping to fuzzing while edge cases are unwritten | Climb in order — cheap levels catch most failures |
| Chamber failures fixed without a captured test | Every failure becomes a permanent suite member |
| 150g on a log-message change | Match the level to risk and lifespan |

## After

Report the gravity level reached and the failures captured as tests to v1 **verification-before-completion**. New tests stay in the suite permanently — the chamber's point is that the next fighter trains at your level by default.
````

- [x] **Step 2: Verify frontmatter and structure**

Run:
```bash
head -10 v2/skills/gravity-chamber/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/gravity-chamber/SKILL.md
```
Expected: `6` then `1`.

---

### Task 4: `fusion-dance` skill

**Files:**
- Create: `v2/skills/fusion-dance/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/fusion-dance/SKILL.md` with exactly this content:

````markdown
---
name: fusion-dance
description: Use when two competing approaches to the same problem both have real merits and neither cleanly wins — synthesizes one design from both, with an explicit equal-power-level precondition and a final check that the fusion beats both donors.
author: Donal Moloney
tier: v2
supports: [brainstorming, writing-plans]
type: technique
chains-to: writing-plans
pairs-with: red-team-spec
---

## Not this skill if

- One approach dominates on every axis that matters — just pick it; fusion is for genuine trade-offs.
- The approaches solve different problems — that's decomposition (v1 **brainstorming**), not fusion.

# Fusion Dance

## Purpose

The fusion dance requires two fighters at equal power level and perfect synchronization — mismatched or sloppy, you get Veku, weaker than either dancer. Design synthesis has the same physics: merging a mature approach with a half-baked one, or gluing parts together without checking the seams, yields a design worse than either original. This skill makes the preconditions and the post-check explicit.

Supports v1 **brainstorming** (when "propose 2–3 approaches" ends with two real contenders) and v1 **writing-plans** (the fused design is what the plan gets written from).

## Triggers

**Use when:**
- Two proposed approaches each win on different axes you actually care about
- Two implementations of the same thing exist (spike vs incumbent) and both have keepers
- A reviewer's counter-proposal has real merit against yours

**Don't use when:**
- One option dominates outright
- The "two approaches" aren't solving the same problem

## The dance

### 1. Equal power level check

Both approaches must be developed enough to compare honestly: each can answer how it handles the same hard cases. If one is vague, develop it first or discard it — never fuse with a sketch.

### 2. Axis table

List the decision axes that matter; mark which approach wins each:

| Axis | Approach A | Approach B |
|---|---|---|
| e.g. read performance | wins | — |
| e.g. simplicity of writes | — | wins |

Drop axes where both tie — fusion only concerns the axes with a split decision.

### 3. Compose along winning axes

Take each axis from its winner, whole — no splitting the difference. Then inspect every seam: where A's part meets B's part, what assumption crosses the boundary? Each seam gets a sentence in the design.

### 4. The Veku check

Compare the fusion against BOTH donors on the full axis table. The fusion must beat or tie each donor overall, and the seams must not have created new worst-cases. If it doesn't clearly win — fusion failed; pick the stronger donor and move on. A failed fusion is a fine outcome; shipping Veku is not.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Fusing a design with a hand-wave | Equal power level first — develop or discard the sketch |
| Compromise on every axis ("split the difference") | Take each axis from its winner, whole |
| Seams unexamined | Every A-meets-B boundary documented |
| Sunk-cost fusion ("we discussed both so we must use both") | Veku check — failed fusion means pick one donor |

## After

Run the fused design through v2 **red-team-spec** if the stakes warrant it, then hand it to v1 **writing-plans**. Record the axis table in the design doc — it's the rationale future readers will ask for.
````

- [x] **Step 2: Verify frontmatter and structure**

Run:
```bash
head -10 v2/skills/fusion-dance/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/fusion-dance/SKILL.md
```
Expected: `6` then `1`.

---

### Task 5: Register the four skills in `v2/README.md`

**Files:**
- Modify: `v2/README.md` (the "Current skills" table)

- [x] **Step 1: Append the four rows to the table**

In `v2/README.md`, replace:

```markdown
| `senzu-bean` | executing-plans |
```

with:

```markdown
| `senzu-bean` | executing-plans |
| `dragon-radar` | verification-before-completion, systematic-debugging |
| `kaioken` | dispatching-parallel-agents, systematic-debugging |
| `gravity-chamber` | test-driven-development, verification-before-completion |
| `fusion-dance` | brainstorming, writing-plans |
```

- [x] **Step 2: Verify the table is complete**

Run:
```bash
grep -c '^| `' v2/README.md
```
Expected: `16`.

---

### Task 6: Audit the four new skills

- [x] **Step 1: Run the skill-auditor agent**

Dispatch the project's `skill-auditor` agent on the four new SKILL.md files, checking the same criteria as batch 1 (frontmatter completeness, WHEN-style description, `## Not this skill if` opening, v1 references not duplication, no upstream-obra identity collision, README registration with matching supports).

Expected: report with no BLOCKING findings.

- [x] **Step 2: Fix any BLOCKING findings and re-audit**

If the auditor reports BLOCKING findings, fix each one, then re-audit the affected files until zero BLOCKING findings remain.
