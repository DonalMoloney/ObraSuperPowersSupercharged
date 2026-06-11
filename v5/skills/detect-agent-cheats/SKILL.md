---
name: detect-agent-cheats
description: Use after any autonomous or subagent run to audit output for shortcut behaviour — skipped tests, invented evidence, hallucinated file paths, empty PROVEN BY blocks, and false completion claims. Pairs with proof-gate. Invoke before accepting any agent's done claim.
author: Donal Moloney
track: proof
type: decision
chains-to: proof-gate
---

## Not this skill if
- You are mid-implementation — run this only after an agent claims done
- The task was trivial and you observed every step — judgement call
- You are reviewing code quality — use `request-review` for that

# detect-agent-cheats — audit agent output for shortcut behaviour

## Purpose

Autonomous agents under pressure take shortcuts. They skip tests and claim they pass. They write `PROVEN BY: tests pass` without running anything. They invent file paths that do not exist. They hallucinate function signatures. They declare done when the task is 60% complete.

This skill catches those shortcuts before they propagate.

## Core rule

> **Rule:** Treat every autonomous agent's done claim as unverified until this skill passes it. An agent that believes it is being checked cheats less. Run this visibly.

## Cheat taxonomy

### Class 1 — Evidence fraud

The agent claims proof it did not collect this turn.

Signals:
- `PROVEN BY:` references a command with no corresponding tool call in the turn
- Output quoted in evidence does not match any tool result in the turn
- Evidence timestamp or session ID is from a prior conversation

Check: grep the turn's tool calls for the exact command in `PROVEN BY:`. If absent → **evidence fraud**.

### Class 2 — Test skip

The agent claims tests pass without running them.

Signals:
- No `Bash` tool call with a test runner command (`pytest`, `npm test`, `cargo test`, `go test`, etc.)
- Test result quoted but no tool call produced it
- `write-tests-first` was skipped — implementation exists but no test file was created or modified

Check: scan tool calls for a test runner. If none → **test skip**.

### Class 3 — Hallucinated paths

The agent references files that do not exist.

Signals:
- `Edit` or `Read` call on a path that returns `file not found`
- `PROVEN BY:` references a file not in `git status` or `git diff`
- Import or require statement pointing to a module not in the dependency tree

Check: for every file path in the agent's output, verify it exists with `ls` or `git ls-files`. Missing → **hallucinated path**.

### Class 4 — Scope truncation

The agent completed part of the contract and claimed the whole thing.

Signals:
- `done-when` items from `compile-goal-to-contract` not addressed
- Acceptance criteria partially met — some items in the contract have no corresponding tool call
- PR description omits criteria that appear in the contract

Check: load the contract. Tick each `done-when` item against tool calls. Unticked → **scope truncation**.

### Class 5 — Silent failure swallow

The agent encountered an error and continued without surfacing it.

Signals:
- Bash tool call returned non-zero exit but no mention of the error in the agent's response
- `try/catch` added to silence an exception rather than fix it
- Test marked `.skip()` or `xfail` without a documented reason

Check: scan Bash tool results for non-zero exit codes. Any unreported → **silent failure**.

## Audit checklist

Run in order. Stop at the first confirmed cheat and surface it before continuing.

```
[ ] Class 1 — Evidence fraud
    grep turn's tool calls for each PROVEN BY command
    confirm quoted output matches actual tool result

[ ] Class 2 — Test skip
    confirm at least one test runner tool call exists
    confirm test files were created or modified

[ ] Class 3 — Hallucinated paths
    for each file referenced: ls / git ls-files confirms it exists
    imports resolve in the dependency tree

[ ] Class 4 — Scope truncation
    load compile-goal-to-contract output
    tick each done-when item against tool calls
    all items covered

[ ] Class 5 — Silent failure swallow
    scan Bash results for non-zero exit codes
    no .skip() / xfail added without documented reason
```

## On finding a cheat

Do not silently fix it. Surface it explicitly:

```
CHEAT DETECTED — Class <N>: <one-line description>
Evidence: <what the agent claimed> vs <what the tool calls show>
Action required: <re-run the missing step / fix the path / surface the error>
```

Then invoke `proof-gate` — the done claim is blocked until the cheat is resolved and genuine evidence is attached.

## Related skills

- `proof-gate` — enforces `PROVEN BY:` format; this skill audits the content behind it
- `evidence-trail` — append-only ledger; cheat findings append as REFUTED entries
- `devils-advocate` — challenges the plan before implementation; this skill audits after
- `done-gate` — pre-merge verifier; run `detect-agent-cheats` before `done-gate`
- `autonomous-issue-runner` — invoke this skill at step 5 (verify) of that flow
