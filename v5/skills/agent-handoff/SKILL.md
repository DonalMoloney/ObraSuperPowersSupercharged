---
name: agent-handoff
description: Use when one agent's output needs to become another agent's input — packages context, state, and partial work into a structured handoff bundle so the receiving agent can start without re-reading the conversation. Use between pipeline stages, on worktree handoffs, and when a specialist agent takes over from a generalist.
author: Donal Moloney
track: parallelization
type: coordination
chains-to: ~
---

## Not this skill if
- Both agents share the same conversation context — no handoff needed, just continue
- You are dispatching independent parallel tasks — use `run-agents-in-parallel`
- You want to merge results from multiple agents — use `merge-parallel-results`

# agent-handoff — clean context transfer between agents

## Purpose

When one agent finishes a stage and another must continue, the handoff is where most information is lost. This skill makes handoffs explicit: the sending agent packages everything the receiver needs; the receiver verifies the package before starting work.

A handoff is not a summary. It is a structured contract.

## Core rule

> **Rule:** The receiving agent must be able to start cold from the handoff bundle alone — no conversation history, no implicit context. If the receiver needs to ask a clarifying question, the bundle is incomplete.

## Handoff bundle format

Emit as a fenced code block with lang `handoff` at the end of the sending agent's final turn:

````
```handoff
task: <one-line description of what the receiver must do>
goal-contract: <reference to compile-goal-to-contract output, or inline acceptance criteria>

state:
  branch: <current git branch>
  worktree: <path, if applicable>
  last-commit: <sha>
  files-changed: <list of files touched this stage>
  tests-passing: <yes / no / partial — list failing tests if partial>

context:
  decisions: |
    <key decisions made this stage that constrain the receiver>
  blockers: |
    <anything the receiver must not do or touch>
  open-questions: |
    <questions the receiver must resolve before proceeding>

evidence:
  <PROVEN BY line(s) from this stage>

next-agent: <skill or role the receiver should invoke first>
```
````

All fields are required. Omit none. If a field has nothing to say, write `none`.

## Sending agent checklist

```
[ ] Task is complete enough to hand off (tests passing or partial state documented)
[ ] PROVEN BY evidence attached for work done this stage
[ ] files-changed list is accurate (git diff --name-only since stage start)
[ ] Decisions that constrain the receiver are written down, not just in conversation
[ ] open-questions are real questions, not hedges — remove if there is no question
[ ] next-agent field names the specific skill the receiver should invoke first
[ ] Bundle is self-contained — tested by reading it in isolation before emitting
```

## Receiving agent checklist

On receiving a handoff bundle, before doing any work:

```
[ ] Read the bundle completely before reading any conversation history
[ ] Verify branch and last-commit match what git reports in the worktree
[ ] Confirm tests-passing status matches actual test run
[ ] If tests-passing: partial — decide whether to fix before proceeding or document and continue
[ ] Resolve all open-questions before starting (ask, do not assume)
[ ] Acknowledge the handoff: emit one line confirming receipt and stating what you will do first
```

Acknowledgement format:
```
Handoff received. Branch: <branch>. Tests: <status>. Starting: <next-agent> on <task>.
```

## Common failure modes

| Failure | Fix |
|---------|-----|
| Receiver re-reads full conversation | Bundle was incomplete — add missing fields |
| Receiver asks what was already decided | decisions field was empty or vague |
| Receiver re-does work already done | files-changed + evidence fields not read |
| Receiver skips open-questions | open-questions were buried in prose, not listed |
| Handoff sent before tests pass | sending checklist not followed — stabilise first |

## When to chain handoffs

For multi-stage pipelines, handoffs chain: each agent receives a bundle, adds its own work, and emits a new bundle for the next stage. The evidence block accumulates — each stage appends its `PROVEN BY` lines.

This creates a complete audit trail across the full pipeline from a single document.

## Related skills

- `compile-goal-to-contract` — the goal-contract field in the bundle comes from here
- `run-agents-in-parallel` — parallel dispatch; no handoff needed within a wave
- `merge-parallel-results` — reassemble after parallel stages, not sequential ones
- `evidence-trail` — append-only ledger; handoff evidence blocks feed into it
- `wave-runner` — orchestrates multi-stage pipelines where handoffs occur between waves
