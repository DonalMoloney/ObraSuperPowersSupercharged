---
name: analyse-routing
description: Use when the skill-router's routing rules feel stale or inaccurate — reads the telemetry log, detects which skills are consistently skipped or overridden for specific task types, and proposes concrete routing-rule changes as a diff to skill-router/SKILL.md. Run after 50+ telemetry entries accumulate.
author: Donal Moloney
track: D
type: support
chains-to: ~
---

## Not this skill if
- Telemetry log has fewer than 10 entries — not enough signal
- You want to reroute a single task right now — use `route-to-skill` instead
- You want to test whether a skill works — use `test-skill`

# analyse-routing — telemetry-driven routing analysis

## Purpose

`skill-router`'s rules are written once and drift. Real invocation patterns diverge from intended routing within weeks: some skills get skipped constantly, others fire on the wrong task types, some chains never complete because a gate always blocks them. This skill reads the telemetry and surfaces that drift as actionable routing-rule changes — not just observations.

## Core rule

> **Rule:** Emit a diff, not a report. Routing debt has no value unless it becomes a proposed change to `skill-router/SKILL.md`.

## Steps

### 1. Read telemetry

```bash
cat .forge/telemetry.jsonl | head -200
```

Each line is a JSON object:
```json
{"skill": "scope-feature", "chain": "orchestrate-feature", "task_hash": "abc123",
 "gate_blocked": false, "task_type": "feature", "ts": "2026-05-29T10:00:00Z"}
```

If `task_type` is absent, infer it from `chain` or the `skill` sequence.

Minimum entries to proceed: **10**. If fewer, emit:
```
analyse-routing: insufficient data (N entries). Minimum 10 required.
```

### 2. Compute per-skill signal

For each skill that appears in the log, compute:

| Metric | Formula |
|---|---|
| `invoke_rate` | sessions where skill fired / total sessions with its task type |
| `skip_rate` | sessions where skill was in context but not fired / total |
| `gate_block_rate` | sessions where skill fired but gate blocked / sessions where skill fired |
| `chain_completion_rate` | chains containing skill that reached finish-branch / total chains with skill |

Flag any skill where:
- `skip_rate > 0.40` — consistently skipped
- `gate_block_rate > 0.30` — gate fires too often (skill or gate needs work)
- `chain_completion_rate < 0.50` — chains with this skill rarely complete

### 3. Identify routing patterns

Group by task type. For each task type with >= 5 sessions, map the actual skill sequences observed (most common first). Compare against the intended chain in `skill-router/SKILL.md`.

Discrepancies:
- **Skill in intended chain never appears in actual chains** → remove from route or move to optional
- **Skill appears in actual chains but not intended** → add to route
- **Skill order differs** → adjust sequence in route
- **Gate blocks > 30% of invocations** → flag the gate clause and the skill for review

### 4. Draft proposed changes

Write a proposed diff to `skill-router/SKILL.md`. Format:

```markdown
## Proposed routing changes — <date>

### Evidence summary
- 68 telemetry entries across 3 task types
- Analysis window: 2026-04-01 to 2026-05-29

### Proposed changes

**1. Remove `challenge-spec` from the quick-fix route**
Evidence: challenge-spec skipped in 8/9 quick-fix sessions (skip_rate 0.89)
Change: remove from Track B routing
Risk: low — it only fires on feature tasks in practice

**2. Add `detect-context-rot` to long-session route (> 50 tasks)**
Evidence: appears in 6/6 sessions exceeding 50 tasks (not in intended chain)
Change: add after task 50 checkpoint in execute-plan
Risk: low — already invoked manually; formalising the pattern

**3. Flag `write-tests-first` gate — blocks 34% of invocations**
Evidence: gate_blocked = true in 23/67 write-tests-first invocations
Interpretation: tests are being written after implementation in 34% of cases
Recommendation: investigate whether the skill's trigger fires too late, or the gate clause is too strict
Action needed: human review before routing change
```

Save to `research/routing-analysis-<date>.md`.

### 5. No auto-apply

> **Rule:** No change is applied to `skill-router/SKILL.md` automatically. Surface the diff for human approval. Routing changes affect every session; they require deliberate review.

Emit:
```
analyse-routing: analysis complete.
<N> routing changes proposed in research/routing-analysis-<date>.md.
Review and apply manually. PROVEN BY: cat .forge/telemetry.jsonl | wc -l → <N> entries processed
```

## Pitfalls

- Proposing changes from fewer than 10 entries — noise, not signal.
- Auto-applying changes — routing affects all sessions; a bad auto-change breaks everything silently.
- Treating skip_rate alone as grounds for removal — a skill with high skip_rate on one task type may be essential for another. Check per task type.
- Conflating gate_block_rate with skill failure — a gate blocking is the skill working correctly. High block rate means the preceding work is consistently incomplete, not that the skill is wrong.

## Pairs with

- [`route-to-skill`](../route-to-skill/SKILL.md): consumes telemetry signal for per-query routing
- [`skill-router`](../skill-router/SKILL.md): the file this skill proposes changes to
- [`index-skills`](../index-skills/SKILL.md): complements routing with semantic matching
- [`judge-skill`](../judge-skill/SKILL.md): quality-check a skill before routing changes that promote it
