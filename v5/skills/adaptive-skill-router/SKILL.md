---
name: adaptive-skill-router
description: Use periodically — learns from telemetry which skills get skipped or whose gates fire, models skill transitions as a Markov chain, and uses a contextual bandit to propose routing-rule changes that reduce friction.
author: Donal Moloney
track: entry
type: process
chains-to: semantic-router
---

## Not this skill if
- `usage-telemetry` hasn't accumulated data yet — there's nothing to learn from
- You want a single routing decision now — use `semantic-router`
- You want to change routing rules manually without data backing — edit `skill-router` directly
- Telemetry covers fewer than 10 sessions — sample is too small; wait for more data

# adaptive-skill-router — routing that learns

## Purpose

Close the loop on routing: use real session history to find where the router misfires and propose
concrete rule changes, rather than tuning by hand.

Skills get skipped. Gates fire and block. The same wrong chain repeats across sessions.
Without a feedback loop, `skill-router` keeps making the same mistakes because no one
updates its rules to reflect what actually works.

Run this skill periodically — once every sprint, after a major skill addition, or whenever
someone asks "why does the router keep picking X instead of Y?" — to surface misfires and
generate diff-ready routing rule proposals backed by statistics.

## Core rule

> **Rule:** Propose, don't auto-apply. Output routing-rule diffs for human review with the stats that
> justify them.

Never write routing-rule changes directly. Every proposed change must be paired with the
transition frequency and gate-block rate that motivated it. A human confirms or rejects each
proposal before any rule file is touched.

## Triggers

**Use when:**
- Telemetry has accumulated across at least 10 sessions and you want a routing tune-up
- A skill keeps appearing in skip logs ("user skipped X three sessions running")
- A gate fires repeatedly on the same chain, suggesting the chain is wrong for that task class
- Someone asks "why does the router keep picking X?" and you need data to answer
- You are onboarding new skills and want to check whether the router is surfacing them at all
- A quarterly routing audit is due

**Don't use when:**
- `.forge/telemetry.jsonl` does not exist or is empty — nothing to compute
- You need a live routing decision right now — use `semantic-router`
- You want to add a brand-new skill to the routing table — do that in `skill-router` directly, then let telemetry accumulate before running this skill
- The session count is below 10 — the Markov chain and bandit estimates are unreliable at small N

## Algorithm

**Markov chain** over skill transitions (which chains succeed vs. loop) + **contextual bandit
(Thompson sampling)** with gate-block frequency as the reward signal, per task class.

The bandit treats each candidate routing rule as an arm. Reward = chain completion without
gate block or manual override. Per-task-class context (e.g., "debugging", "feature-dev",
"skill-craft") keeps arms separate so a rule that works well for debugging does not pollute
feature-dev estimates.

## Steps

### 1. Load and validate telemetry

Read `.forge/telemetry.jsonl` line by line. Each line must have at minimum:
`session_id`, `task_class`, `skill_sequence` (ordered list), `outcome`
(`completed` | `gate_blocked` | `skipped` | `looped`).

Reject lines missing any required field; log the drop count before continuing.
If total valid lines < 10, stop and report: "Insufficient data — N valid sessions found, minimum 10 required."

### 2. Build the transition matrix

For each consecutive skill pair `(A → B)` in every `skill_sequence`, increment
`transitions[A][B]`. Separately track `gate_blocks[A]` and `skip_counts[A]`.

Flag a skill as high-friction if either:
- `gate_block_rate[A] > 0.3` (fires more than 30 % of the time it appears), or
- `skip_rate[A] > 0.4` (skipped more than 40 % of the time it appears).

Compute per-task-class matrices separately — a skill that is high-friction in "debugging"
may be correct in "feature-dev".

### 3. Identify anomalous chains

A chain is anomalous if:
- It loops (A → B → A or longer cycle) in more than 20 % of sessions for a task class.
- The modal next skill after A differs from what `skill-router` currently routes to by more than 30 percentage points.
- A high-friction skill appears at position 1 (first routed) in a task class — the router is leading with the wrong skill.

List each anomalous chain with its frequency, task class, and current routing rule that produced it.

### 4. Run the contextual bandit

For each anomalous chain, enumerate candidate replacements: the top-3 most frequent
actual next skills observed in telemetry (excluding the current routed skill).

Apply Thompson sampling per candidate arm per task class:
- Prior: Beta(1, 1) (uninformative).
- Update: for each session where this candidate was the actual next skill, increment
  alpha (success) if outcome = `completed`, beta (failure) if outcome = `gate_blocked` or `looped`.
- Sample the posterior; rank candidates by sampled value.

The top-ranked candidate per anomalous chain becomes the proposed replacement.

### 5. Emit proposed routing-rule diffs

For each proposed change, emit a structured block:

```
PROPOSED CHANGE #N
Task class:      <class>
Current rule:    route(<trigger>) → <current-skill>
Proposed rule:   route(<trigger>) → <proposed-skill>
Justification:
  - Observed transition rate current→next: <X>%
  - Observed transition rate proposed→next: <Y>%
  - Gate-block rate current: <Z>%  |  proposed: <W>%
  - Sessions analyzed: <count>
Confidence:      Thompson posterior mean = <value> (N_alpha=<a>, N_beta=<b>)
```

Do not write changes to any file. Present all proposed diffs together, then ask: "Apply any of these? List the numbers to confirm."

### 6. Update telemetry baseline (after human approval)

Once the human approves one or more changes and edits the routing rules, record the approval
in `.forge/telemetry.jsonl` as a meta-event:

```json
{"event": "routing_rule_updated", "change_id": "N", "approved_by": "human", "date": "<ISO date>"}
```

This marks the baseline so future runs measure improvement from the updated rules, not the old ones.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Auto-applying proposed changes without human review | Always present diffs and wait for explicit approval; never write routing files directly |
| Mixing task classes in the transition matrix | Keep per-class matrices separate; a high skip rate in "debugging" must not penalize the skill in "feature-dev" |
| Computing the bandit on fewer than 10 sessions | Check sample size before sampling; report "insufficient data" and stop rather than emit low-confidence proposals |
| Proposing a replacement skill that doesn't exist in `skills/` | Validate each proposed skill name against the actual `skills/` directory before including it in a proposal |
| Ignoring skip events as non-informative | Skips are the strongest signal of misfire; weight them as negatives in the bandit reward |
| Running after every session | Batch telemetry; run at sprint cadence or when N new sessions have accumulated since the last run |

## Proof

Hand off to `semantic-router` after routing rules are approved and applied; verify the
updated router selects the corrected skill for a representative sample of triggers.

The output must contain:
- Transition matrix summary per task class (top-5 pairs by frequency)
- High-friction skill list with gate-block rates and skip rates
- Anomalous chains list with frequency and task class
- Per-proposed-change block (current rule, proposed rule, justification stats, Thompson confidence)
- Count of sessions analyzed vs. sessions dropped (missing fields)

```
PROVEN BY:
- telemetry.jsonl read: <N> valid sessions, <M> dropped
- transition matrix built for task classes: <list>
- high-friction skills flagged: <list>
- anomalous chains detected: <count>
- proposals generated: <count>
- human approval recorded: change IDs <list> (or "none approved this run")
```

## Adapt from
- **`PlaytikaOSS/pybandits`** (contextual MAB / Thompson sampling) · **`erdogant/thompson`**
  (Thompson + UCB). <https://github.com/PlaytikaOSS/pybandits>
