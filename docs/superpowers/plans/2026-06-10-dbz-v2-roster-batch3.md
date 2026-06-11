# Dragon Ball v2 Roster — Batch 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the two roster-completing Dragon Ball-named v2 skills (hyperbolic-time-chamber, hoi-poi-capsule), register them in `v2/README.md`, and pass a skill-auditor review.

**Architecture:** Same as batches 1–2 — one directory `v2/skills/<name>/SKILL.md` per skill, v2 house style. Content references v1 skills, never duplicates them. Frontmatter descriptions must be valid unquoted YAML scalars (no `: ` inside — lesson from batch 2).

**Tech Stack:** Markdown only. Verification: `grep` structure checks, Python YAML parse of frontmatter, plus the project's `skill-auditor` agent.

**Spec:** `docs/superpowers/specs/2026-06-10-dbz-v2-roster-design.md` (Batch 3 addendum)

**Note on commits:** This project is not a git repository (per CLAUDE.md). All "commit" steps are omitted. Do not run `git init`.

---

### Task 1: `hyperbolic-time-chamber` skill

**Files:**
- Create: `v2/skills/hyperbolic-time-chamber/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/hyperbolic-time-chamber/SKILL.md` with exactly this content:

````markdown
---
name: hyperbolic-time-chamber
description: Use before releasing a new or rewritten skill — a year of training in a day; stress-tests the draft against should-trigger scenarios and near-misses in isolation, tightening the description and triggers until they fire correctly.
author: Donal Moloney
tier: v2
supports: [writing-skills]
type: technique
chains-to: skill-lint
pairs-with: skill-lint
---

## Not this skill if

- Only formatting or structure changed, not behavior — run v2 **skill-lint** and move on.
- You can't name concrete scenarios where the skill should fire — that's a design gap; return to v1 **writing-skills** first.

# Hyperbolic Time Chamber

## Purpose

A year of training in a day, before the real fight. A skill that has never been exercised meets its first real scenario in production — and fails on its description (doesn't trigger), its boundaries (triggers when it shouldn't), or its body (doesn't actually help). The chamber runs those encounters cheaply, in isolation, before release.

Supports v1 **writing-skills** as the cheap pre-pass before its subagent pressure-testing protocol (`testing-skills-with-subagents.md`): drill the description and body on paper first, then spend subagent runs only on a draft that survived the chamber. Pairs with v2 **skill-lint**: lint checks structure statically; the chamber checks behavior.

## Triggers

**Use when:**
- A new skill draft is about to be released
- An existing skill's description, triggers, or core flow was rewritten
- A skill exists but keeps misfiring — triggering on the wrong tasks or missing the right ones

**Don't use when:**
- The change is cosmetic (typos, formatting)
- The skill's purpose itself is still undecided

## The training regimen

### 1. Build the scenario set

Before reading the draft again, write down:

| Set | Count | Contents |
|---|---|---|
| **Should-trigger** | 3+ | Realistic user phrasings and situations where this skill MUST be invoked — vary the wording, don't reuse the skill's own vocabulary |
| **Near-miss** | 2+ | Adjacent situations that look similar but belong to a different skill or no skill — the boundary cases |

If you can't produce three honest should-trigger scenarios, the skill's reason to exist is unclear — leave the chamber and go back to design.

### 2. Run the trigger drills

For each scenario, read ONLY the frontmatter `description` and ask: would a model scanning available skills invoke this one here?

- Should-trigger scenario fails to fire → the description is missing the situation's vocabulary; add WHEN language, not WHAT language.
- Near-miss fires → the description over-claims; sharpen the boundary and add it to the body's "Not this skill if".

### 3. Run the body drills

For each should-trigger scenario, walk the body as if executing it in that situation. Every step must be actionable in-scenario; any step that needs information the scenario doesn't have means a missing precondition or instruction.

### 4. The cold read

One final pass reading the whole skill with no scenario in mind: does it make sense to someone with zero context from this conversation? Names, examples, and references must stand alone.

**Exit criteria:** all should-trigger scenarios fire, all near-misses don't, the body walks cleanly in every scenario, and the cold read raises nothing. Until then, you stay in the chamber.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Scenarios written in the skill's own vocabulary | Use phrasings a real user would type, then check the description catches them |
| Only happy-path scenarios | Near-misses are mandatory — boundaries are where skills fail |
| Editing the body while drilling triggers | Trigger drills test the description alone; fix one layer at a time |
| Leaving the chamber on a feeling | Exit criteria are explicit; a failed drill means another round |

## After

Run v2 **skill-lint** for the static checks, then release. Record the scenario set in the skill's directory or PR description — the next rewrite reuses it as a regression suite.
````

- [x] **Step 2: Verify structure and YAML**

Run:
```bash
head -10 v2/skills/hyperbolic-time-chamber/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/hyperbolic-time-chamber/SKILL.md
python3 -c "import yaml; d=yaml.safe_load(open('v2/skills/hyperbolic-time-chamber/SKILL.md').read().split('---')[1]); print('YAML OK', d['tier'])"
```
Expected: `6`, `1`, `YAML OK v2`.

---

### Task 2: `hoi-poi-capsule` skill

**Files:**
- Create: `v2/skills/hoi-poi-capsule/SKILL.md`

- [x] **Step 1: Write the skill file**

Create `v2/skills/hoi-poi-capsule/SKILL.md` with exactly this content:

````markdown
---
name: hoi-poi-capsule
description: Use when more than one workspace, worktree, or development branch exists at once, or when returning to a machine with old ones — inventories every capsule, classifies it (active, finished, stale, unknown), and routes each to the finishing flow or an explicit discard so no work rots in a forgotten capsule.
author: Donal Moloney
tier: v2
supports: [using-git-worktrees, finishing-a-development-branch]
type: process
chains-to: finishing-a-development-branch
pairs-with: spike-in-worktree
---

## Not this skill if

- There's a single workspace and nothing parallel — nothing to inventory.
- You're about to CREATE an isolated workspace — that's v1 **using-git-worktrees** (or v2 **spike-in-worktree** for throwaway experiments).

# Hoi-Poi Capsule

## Purpose

Capsule Corp's rule: every capsule has an owner and a label, and you always know what's deployed. Parallel development breaks the other way — worktrees and branches accumulate, each holding work someone meant to come back to, until nobody remembers what's in them and finished work quietly rots unmerged. This skill manages the *fleet*: what capsules exist, what's in each, and what happens to it.

Supports v1 **using-git-worktrees** (the inventory is the other half of creation) and v1 **finishing-a-development-branch** (finished capsules route into its merge/PR/discard decision).

## Triggers

**Use when:**
- More than one worktree or feature branch exists right now
- Returning to a repo or machine after time away — what did past-you leave deployed?
- Before creating yet another workspace — check the fleet first
- Disk, confusion, or "which branch had that fix?" moments

**Don't use when:**
- Single workspace, no parallel work
- Creating a new workspace (that's v1 **using-git-worktrees**)

## The fleet check

### 1. Inventory

List every capsule with its vitals:

```
git worktree list
git branch -vv --sort=-committerdate
```

Every row gets an entry: location, branch, last commit date, ahead/behind its base.

### 2. Classify

| Class | Signal | 
|---|---|
| **Active** | You can say what task it serves today |
| **Finished** | Work complete, not yet merged/PR'd |
| **Stale** | No commits in a long time, purpose foggy |
| **Unknown** | Can't say what it is without looking |

"Unknown" is a temporary class — inspect (`git log`, `git diff <base>...`) until it becomes one of the other three.

### 3. Route

- **Active** → leave it; note its task in one line.
- **Finished** → v1 **finishing-a-development-branch** — merge, PR, or discard via its structured options.
- **Stale** → check for unique work (`git log <base>..<branch>`). Unique commits: recover (rebase, cherry-pick, or finish) or discard with a written one-line reason. No unique work: remove.
- **Unknown** → never delete while unknown; inspect first.

### 4. The repack rule

A capsule is closed only two ways: through the v1 finishing flow, or by an explicit discard with a recorded reason. Silent deletion is how work disappears.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Creating workspace #5 without checking the fleet | Inventory before every new capsule |
| Deleting a stale worktree to "clean up" | Check for unique commits first; discard is a decision, not housekeeping |
| Finished branch parked "until later" | Finished routes to v1 **finishing-a-development-branch** now — parked is how it rots |
| Inventory done, classifications kept in your head | Write the ledger down; the next fleet check starts from it |

## After

Route every **Finished** capsule through v1 **finishing-a-development-branch**. If the fleet check found work worth isolating going forward, create new capsules via v1 **using-git-worktrees** — labeled, with an owner and a task.
````

- [x] **Step 2: Verify structure and YAML**

Run:
```bash
head -10 v2/skills/hoi-poi-capsule/SKILL.md | grep -E '^(name|description|author|tier|supports|type):' | wc -l
grep -c '^## Not this skill if' v2/skills/hoi-poi-capsule/SKILL.md
python3 -c "import yaml; d=yaml.safe_load(open('v2/skills/hoi-poi-capsule/SKILL.md').read().split('---')[1]); print('YAML OK', d['tier'])"
```
Expected: `6`, `1`, `YAML OK v2`.

---

### Task 3: Register the two skills in `v2/README.md`

**Files:**
- Modify: `v2/README.md` (the "Current skills" table)

- [x] **Step 1: Append the two rows**

In `v2/README.md`, replace the line:

```markdown
| `fusion-dance` | brainstorming, writing-plans |
```

with:

```markdown
| `fusion-dance` | brainstorming, writing-plans |
| `hyperbolic-time-chamber` | writing-skills |
| `hoi-poi-capsule` | using-git-worktrees, finishing-a-development-branch |
```

(Note: other sessions may be editing this table concurrently; anchor on the `fusion-dance` line, not on row counts.)

- [x] **Step 2: Verify the rows landed**

Run:
```bash
grep -c '`hyperbolic-time-chamber`\|`hoi-poi-capsule`' v2/README.md
```
Expected: `2`.

---

### Task 4: Audit the two new skills

- [x] **Step 1: Run the skill-auditor agent**

Dispatch the project's `skill-auditor` agent on the two new SKILL.md files, same criteria as batches 1–2 (frontmatter completeness + valid YAML, WHEN-style description, `## Not this skill if` opening, v1 references not duplication, no upstream-obra identity collision, README registration with matching supports). Audit ONLY these two files.

Expected: no BLOCKING findings.

- [x] **Step 2: Fix any BLOCKING findings and re-audit**

Fix each BLOCKING finding and re-audit the affected files until zero remain.
