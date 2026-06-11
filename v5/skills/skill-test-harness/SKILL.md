---
name: skill-test-harness
description: Use to prove a skill actually works — spawns subagents that role-play users with realistic tasks, invokes the skill under test, and checks each transcript against the skill's contract. Generalizes test-skill from "does it load" to "does it work".
author: Donal Moloney
track: D
type: process
chains-to: self-review-skill
---

## Not this skill if
- You only need to confirm the skill loads and triggers — use `test-skill`
- You want to improve the prose, not test behavior — use `self-review-skill`
- You are grading a general agent output, not a specific SKILL.md's contract — use `proof-gate`

# skill-test-harness — behavioral evals for skills

## Purpose

Catch skills that load fine but produce the wrong behavior. Drive them with simulated users and grade the output against an explicit contract, so regressions surface before deployment.

## Triggers

**Use when:**
- You wrote or rewrote a skill and want evidence it fires correctly before merging
- A skill is suspected of regressing after a house-style or wording change
- You are building a regression suite across multiple skills before a v-release
- Someone reports that a skill "doesn't do what it says" and you need a reproducible verdict
- Pre-deployment verification: "does this skill actually work end-to-end?"

**Don't use when:**
- You only need the skill to parse and trigger — a single invocation test is enough
- The skill is a reference document (no behavioral contract to test)
- N=1 persona is the entire test plan — one transcript is not a pass; run at least 3 positives
- You want to rewrite weak sections rather than verify behavior — use `self-review-skill`

## Core rule

> **Rule:** Define the pass/fail contract before running. A skill "passes" only on a majority of
> independent personas — one lucky transcript is not a pass.

## The pattern

```
extract_contract(skill) → persona_set(positives + decoys) → fan_out(runs) → grade_each → verdict
```

1. Extract the contract from the skill's frontmatter and required sections.
2. Generate a persona set: N positive personas whose tasks should trigger the skill, plus 1–2 decoy personas whose tasks should NOT trigger it.
3. Fan out runs in parallel; each persona invokes the skill independently.
4. Grade each transcript against the contract; compute pass rate and variance.
5. Emit verdict: pass rate, per-persona verdicts, failing transcripts, suggested fixes.

## Steps

### Step 1 — Extract the contract

Read the target SKILL.md. Pull the following into a contract document before writing any persona:
- **Trigger condition** — what user phrasing or context must fire this skill?
- **Required sections** — which output sections must appear (e.g., a `PROVEN BY:` block, a summary table, a verdict line)?
- **Output shape** — what format must the result take (structured table, prose block, numbered list)?
- **Gate conditions** — does the skill enforce a `proof-gate`, a majority vote, or a stop condition?
- **Chains-to target** — does the skill hand off? If so, is the hand-off prompt present?

Write the contract as a checklist. Every grading step will score against this checklist, not against subjective quality.

### Step 2 — Generate the persona set

Construct personas as short role descriptions with a concrete task. Minimum viable set:
- **3 positive personas** — distinct user types with tasks that clearly match the skill's trigger condition. Vary vocabulary; do not reuse the trigger wording verbatim.
- **1 decoy persona** — a user whose task is adjacent but should NOT trigger the skill. This validates that the skill does not over-fire.
- **1 edge persona (optional but recommended)** — a user at the boundary of the trigger condition. Pass/fail here is expected to be ambiguous; flag it as informational, not deterministic.

Record each persona with: role description, task statement, and expected outcome (TRIGGER / NO-TRIGGER / AMBIGUOUS).

### Step 3 — Fan out runs

Dispatch one subagent per persona in parallel. Each subagent:
1. Receives only the persona description and task — no meta-context about the test.
2. Invokes the skill under test via its normal trigger (slash command or natural-language phrasing that matches the trigger).
3. Completes the task to its natural stopping point.
4. Returns the full transcript.

Cap concurrency at 5 subagents for raw parallel dispatch. If running more than 5 personas, batch into waves of 5 and collect transcripts between waves. Do not start grading until all transcripts in a wave are returned.

### Step 4 — Grade each transcript

Run a judge pass on each transcript. Score each item in the contract checklist as PASS, FAIL, or N/A. Record:
- Which checklist items passed and which failed
- The exact transcript excerpt that supports each verdict
- Whether the persona was a positive, decoy, or edge case

For decoy personas, a TRIGGER outcome counts as a FAIL (false positive). For edge personas, record the outcome without penalizing either way.

Compute the pass rate across positive personas only: `pass_rate = passing_positives / total_positives`. Flag high variance (e.g., 2 of 3 positives pass on different checklist items) separately from a clean majority fail.

### Step 5 — Emit verdict and hand off

Produce a verdict block:
- Overall result: PASS (majority of positives met full contract), FAIL (majority failed one or more checklist items), or PARTIAL (majority passed but with variance).
- Per-persona summary table.
- Failing transcripts with the specific contract item that failed and a suggested fix.
- Decoy result (did the skill correctly not trigger?).

Hand failing transcripts and suggested fixes to `self-review-skill` for targeted prose or logic repair.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Running only one positive persona and calling it a pass | Run at least 3 positive personas with distinct vocabularies; majority rule applies |
| Writing personas that echo the trigger wording verbatim | Vary phrasing; the skill must generalize beyond its own description |
| Starting the grade pass before all transcripts return | Wait for full wave completion; partial grading produces misleading pass rates |
| Skipping the decoy persona | Always include at least one decoy; over-firing is a behavioral regression too |
| Grading on subjective quality rather than the contract checklist | Grade only against the checklist extracted in Step 1; add items if needed, but grade mechanically |
| Treating an edge-persona FAIL as a verdict-level failure | Record edge outcomes as informational; they inform contract refinement, not the current pass/fail |

## Proof

Hand off to `self-review-skill` once the verdict block is complete.

The output must contain:

- Contract checklist (trigger condition, required sections, output shape, gate conditions, chains-to)
- Persona set with expected outcomes recorded before runs
- Per-persona transcript reference (agent ID or run label)
- Per-persona grade table (checklist item | PASS/FAIL/N/A | supporting excerpt)
- Pass rate calculation: `passing_positives / total_positives`
- Decoy result: CORRECT-NO-TRIGGER or FALSE-POSITIVE
- Overall verdict: PASS / FAIL / PARTIAL with variance flag if applicable
- `PROVEN BY:` block listing each persona label, its verdict, and the checklist item(s) that determined it

## Adapt from
- **`promptfoo/promptfoo`** — declarative LLM eval/assertion harness (contract + grading model).
  <https://github.com/promptfoo/promptfoo>
- **`mattpocock/skills`** — engineering eval patterns. <https://github.com/mattpocock/skills>
