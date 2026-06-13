---
name: skill-test-harness
description: Use when you need behavioral evidence that a skill actually fires and produces its intended behavior before merging — spawns subagents that role-play realistic users, invokes the skill under test, and grades each transcript against the skill's contract; run when authoring or reworking a skill, when one is suspected of regressing after a wording change, or when someone reports a skill "doesn't do what it says".
author: Donal Moloney
tier: v2
supports: [writing-skills]
type: process
pairs-with: skill-lint
---

## Not this skill if

- You only need static/format checks (frontmatter, "Use when" description, required sections, no placeholders) — that is v2 **skill-lint**, which reads the file but never runs it. This skill is **behavioral**: it spawns subagents, invokes the skill, and inspects what actually happened.
- You are rewriting weak prose rather than verifying behavior — author the change with v1 **writing-skills** first, then run this harness on the result.
- The skill is a pure reference document with no behavioral contract to test — there is nothing for a persona to trigger.

# skill-test-harness — runnable pressure test for skills

## Purpose

v1 **writing-skills** establishes the Iron Law — no skill without a failing pressure test first — and describes running pressure scenarios with subagents. This skill is the operational form of that pressure test: it turns "run scenarios with subagents and watch what happens" into a repeatable procedure that produces a pass/fail verdict per scenario. It does not restate the doctrine; see v1 **writing-skills** for why pressure testing is mandatory.

The gap it closes: a skill can lint clean and still produce the wrong behavior when invoked. v2 **skill-lint** cannot catch that — only running the skill against simulated users can.

**Core rule:** Define the pass/fail contract before running, and grade against that contract — never subjective quality. A skill passes only on a majority of independent positive personas; one lucky transcript is not a pass.

## The pattern

```
extract_contract(skill) → persona_set(positives + decoy) → fan_out(runs) → grade_each → verdict
```

## Procedure

### 1. Extract the contract

Read the target SKILL.md and pull these into a checklist before writing any persona:

- **Trigger condition** — what user phrasing or context must fire the skill?
- **Required behavior** — what must the skill make the agent DO (a step taken, a section produced, a gate enforced, a stop condition honored)?
- **Output shape** — what format must the result take (table, numbered list, prose block, a `PROVEN BY:` line)?
- **Hand-off** — does the skill chain to another skill, and is the hand-off present when it should be?

Every grading step scores against this checklist, not against taste.

### 2. Build the persona set

Each persona is a short role plus one concrete task and an expected outcome:

- **3+ positive personas** — distinct user types whose tasks clearly match the trigger. Vary vocabulary; do NOT echo the skill's trigger wording verbatim, or you are only testing copy-paste, not generalization.
- **1 decoy persona** — an adjacent task that should NOT trigger the skill, to catch over-firing.
- **1 edge persona (optional)** — a boundary case; record its outcome as informational only.

Record role, task, and expected outcome (TRIGGER / NO-TRIGGER / AMBIGUOUS) before any run.

### 3. Fan out the runs

Dispatch one subagent per persona. Each subagent:

1. Receives only its persona and task — no meta-context that this is a test.
2. Invokes the skill under test through its normal trigger.
3. Completes the task to a natural stopping point.
4. Returns the full transcript.

Cap concurrency at 5; batch into waves of 5 if there are more personas. Do not start grading a wave until every transcript in it has returned — partial grading produces misleading pass rates.

### 4. Grade each transcript

For each transcript, score every checklist item PASS / FAIL / N/A and quote the exact excerpt that supports the verdict. For a decoy, a TRIGGER outcome is a FAIL (false positive). For an edge persona, record without penalty.

Compute `pass_rate = passing_positives / total_positives`. Flag high variance (positives passing on different items) separately from a clean majority fail.

### 5. Emit the verdict

Produce: overall result (**PASS** = majority of positives met the full contract / **FAIL** = majority missed one or more items / **PARTIAL** = majority passed but with variance), a per-persona summary table, the decoy result, and each failing transcript with the specific contract item it missed and a suggested fix. Hand failing transcripts and fixes back to v1 **writing-skills** for targeted repair, then re-run.

## Pitfalls

| Mistake | Fix |
|---|---|
| Running one positive persona and calling it a pass | Run 3+ with distinct vocabularies; majority rule applies |
| Personas that echo the trigger wording verbatim | Vary phrasing — the skill must generalize beyond its own description |
| Grading before the whole wave returns | Wait for full wave completion; partial grading misleads |
| Skipping the decoy | Always include one; over-firing is a behavioral regression too |
| Grading on subjective quality | Score only against the Step 1 checklist, mechanically |
| Treating an edge FAIL as a verdict-level failure | Edge outcomes are informational; they refine the contract, not the current verdict |
| Running this instead of skill-lint | Lint first (cheap, static); this harness is the heavier behavioral gate after lint is green |

## After

Verify the run produced: the contract checklist, the persona set with expected outcomes recorded before runs, a per-persona grade table (item | PASS/FAIL/N/A | excerpt), the `passing_positives / total_positives` calculation, the decoy result (CORRECT-NO-TRIGGER or FALSE-POSITIVE), and an overall verdict with a variance flag where applicable.

PROVEN BY: a `PROVEN BY:` block listing each persona label, its verdict, and the checklist item(s) that determined it. A verdict of PASS without at least 3 independent positive transcripts, or without a decoy result, is invalid under this skill.

## Pairs with

- v2 **skill-lint** — static/format gate; run it first, then run this behavioral harness on a skill that lints clean.
- v1 **writing-skills** — defines the pressure-test doctrine this skill operationalizes; receives failing transcripts for repair.
