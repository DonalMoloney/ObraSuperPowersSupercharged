---
name: test-skill
description: Use when a skill has been written or rewritten and needs behavioural verification — spawns a subagent role-playing a real user, invokes the target skill, and grades the output against the skill's contract.yaml. Use proactively after any SKILL.md edit.
author: Donal Moloney
track: D
type: process
chains-to: judge-skill
---

## Not this skill if
- The target skill has no `contract.yaml` — write the contract first (see Steps below)
- You are doing a style/voice check only — use `judge-skill` instead
- You are testing more than one skill at once — run a separate invocation per skill

# test-skill — behavioural contract verification

## Purpose

Skills can pass a style check and still break their behavioural contract. A rewrite that looks clean may drop a required proof step, change the output shape, or stop enforcing a gate. This skill catches regressions that `judge-skill` misses by running the skill against a real task and checking the output against a machine-readable contract.

## Core rule

> **Rule:** A skill passes only when every contract clause passes. A partial pass is a fail. Do not mark a skill as verified unless all clauses are green.

## Contract format

Each skill that has been tested has a `contract.yaml` beside its SKILL.md:

```yaml
# skills/<name>/contract.yaml
trigger:
  - "I need to plan a feature"
  - "write a plan for"
required_inputs:
  - spec_or_description: string
required_outputs:
  - plan_file: "docs/plans/*.md"
  - done_when_per_task: present
  - no_placeholder_steps: true
required_proof:
  - tag: "PROVEN BY:"
  - format: "<command> → <output or exit code>"
gates:
  - no_completion_claim_without_proof: true
```

If `contract.yaml` does not exist for the target skill, write it now before running the test. Derive clauses from the skill's `## Core rule`, `## Steps`, and `## Pitfalls` sections.

## Steps

### 1. Read the contract

Read `skills/<target>/contract.yaml`. List every clause. These are the pass/fail criteria.

### 2. Select or write a test prompt

Pick one trigger phrase from `contract.trigger` and expand it into a realistic user task — the kind of thing an engineer would actually type, not an abstract description. Include context: a file path, a goal, a constraint.

Example for `outline-plan`:
> "I need a plan to add OAuth2 login to our FastAPI app. The user table is in `db/models.py`. We're using PostgreSQL and want to support Google and GitHub providers."

### 3. Spawn the test subagent

Dispatch a subagent with:

```
You are an engineer who has just sent the following message to Claude Code:

"<test prompt>"

You have access to this skill: skills/<target>/SKILL.md

Execute the task. Save all output files to: test-skill-workspace/<target>/run-<n>/outputs/
Record the full response to: test-skill-workspace/<target>/run-<n>/response.md
```

Do not hint at what the correct output looks like. The subagent should behave as a user, not as a tester.

### 4. Grade the output

For each contract clause, check the output against it and record a verdict:

```
clause: plan_file present
check:  ls test-skill-workspace/<target>/run-<n>/outputs/docs/plans/*.md
result: PASS — plan found at docs/plans/2026-05-29-oauth2-login.md

clause: done_when_per_task
check:  grep "DONE WHEN:" <plan_file> | wc -l vs task count
result: FAIL — 5 tasks, 3 DONE WHEN lines (tasks 2 and 4 missing)

clause: no_placeholder_steps
check:  grep -i "tbd\|TODO\|fill in\|implement later" <plan_file>
result: PASS — no placeholders found
```

Run checks programmatically where possible. Eyeball only as a last resort.

### 5. Emit the report

```
## test-skill report: <target>

Prompt: "<test prompt>"
Run:    test-skill-workspace/<target>/run-<n>/

| Clause                        | Result | Evidence                              |
|-------------------------------|--------|---------------------------------------|
| plan_file present             | PASS   | docs/plans/2026-05-29-oauth2-login.md |
| done_when_per_task            | FAIL   | 3/5 tasks have DONE WHEN              |
| no_placeholder_steps          | PASS   | grep returned 0 matches               |
| PROVEN BY: tag present        | PASS   | line 47                               |

Overall: FAIL (1/4 clauses failed)

Fix required: tasks 2 and 4 in outline-plan are missing DONE WHEN lines.
```

If all clauses pass, emit `Overall: PASS` and route next to `judge-skill` for a style check.

### 6. On failure

Flag which clause failed and which section of the skill's SKILL.md governs it. Do not auto-patch the skill — surface the finding and let the author decide the fix.

If the same clause fails across two consecutive runs, flag it as a contract regression: the skill's behaviour has drifted from its contract.

## Pitfalls

- Writing the test prompt to match the happy path exactly — good tests include one missing piece of context to check the skill's handling of partial inputs.
- Grading by reading the response instead of running the checks — run the commands.
- Marking a skill PASS when one clause is skipped because it was "hard to check" — write a proxy check or mark the clause UNVERIFIABLE and note it.
- Running this skill on a newly drafted skill before `judge-skill` — style violations pollute the contract run. Judge first.

## Pairs with

- [`judge-skill`](../judge-skill/SKILL.md): style and quality check; run before this skill on first draft
- [`outline-plan`](../outline-plan/SKILL.md): contract.yaml schema mirrors the plan's DONE WHEN pattern
- [`proof-gate`](../proof-gate/SKILL.md): contract clause `required_proof` enforces gate compliance
- [`writing-skills`](../writing-skills/SKILL.md): TDD-style workflow for authoring skills; this skill is its verification step
