---
name: proof-chain-validator
description: Use when finishing a multi-skill session — traverses the full PROVEN BY chain from the evidence-trail log, verifies each node has a timestamp, artifact, and link to the next node, and flags any gap before finish-branch runs.
author: Donal Moloney
track: proof
type: decision
chains-to: finish-branch
---

## Not this skill if
- You are writing a single `PROVEN BY:` block for one task — use `proof-gate` (one node, not a chain)
- You are running a single-skill session with one completion claim — inline `PROVEN BY:` is sufficient
- The session has no evidence-trail log — start one with `evidence-trail` before any claim is made

# proof-chain-validator — full-chain proof audit

## Purpose

`proof-gate` writes one node. This skill validates the whole chain.

Traverses every node in the session's evidence-trail log, verifies structural integrity (timestamp,
artifact, forward link), and emits a chain diagram plus a pass/fail per node. Any gap or broken
link is surfaced before `finish-branch` runs — so a missing proof cannot slip into the merge.

**Core rule:** Every node must have three things: a timestamp from the current session, at least one
artifact (file path, test name, or command output), and a link to the next node (or a terminal marker
on the last node). A node missing any of these fails.

## When to use

- Before `finish-branch` on any session that invoked two or more skills
- After `execute-plan` or `spawn-subagent` completes, to confirm every task has evidence
- When a reviewer asks "show me the proof chain" for a PR
- When `detect-agent-cheats` flags a possible evidence gap — use this to locate it precisely

## Steps

### 1. Locate the evidence-trail log

Read the session's evidence-trail log. Default path: `docs/evidence/YYYY-MM-DD-<feature>.md`.
If no log file exists, stop and emit:

```
ERROR: No evidence-trail log found. Cannot validate chain.
Action: Create the log with evidence-trail before making any completion claim, then re-run.
```

### 2. Parse the node list

Extract every node entry from the log. Each node should contain:

- `claim` — the human-readable assertion
- `timestamp` — when the evidence was recorded (ISO-8601 or session-relative marker)
- `artifact` — at least one of: file path, test name, command output excerpt, or CI run URL
- `prev_hash` (or `prev_ref`) — pointer to the preceding node; `ROOT` on the first node
- `next_ref` — pointer to the following node; `TERMINAL` on the last node (may be inferred)

Record the node count.

### 3. Validate each node

For every node, run four checks:

| Check | Pass condition | Fail label |
|---|---|---|
| **Timestamp present** | A timestamp field is non-empty | `MISSING-TIMESTAMP` |
| **Artifact present** | At least one file path, test identifier, or command output is recorded | `MISSING-ARTIFACT` |
| **Forward link valid** | `next_ref` points to a node that exists in the log, OR the node is marked `TERMINAL` | `BROKEN-LINK` |
| **No duplicate claim** | The `claim` text is unique in the log (verbatim duplicates indicate copy-paste rather than fresh evidence) | `DUPLICATE-CLAIM` |

Record `PASS` or `FAIL:<label>` per check, per node.

### 4. Detect missing nodes

Scan the task list from the most recent `outline-plan` or `execute-plan` output (if available).
For every task marked `done`, confirm a corresponding node exists in the evidence-trail log.

Tasks with no node: emit `MISSING-NODE: <task name or identifier>`.

### 5. Emit the chain diagram

Produce a text-art or Mermaid chain showing each node's claim (truncated to 60 chars), status, and
link direction:

```
[ROOT]
  └─ ✅ Node 1: "login redirects to dashboard" (2026-05-30T14:22Z) artifact: test-output.log
       └─ ✅ Node 2: "signup form validates email" (2026-05-30T14:45Z) artifact: playwright.png
            └─ ❌ Node 3: "password reset sends email" — MISSING-ARTIFACT
                 └─ ✅ Node 4: "CI green on main" (2026-05-30T15:02Z) artifact: run#4821
                      └─ [TERMINAL]
```

### 6. Emit the summary report

```
## Proof chain validation — <feature> — <YYYY-MM-DD>

Nodes found:      <N>
Nodes passing:    <P>
Nodes failing:    <F>
Missing nodes:    <M> (tasks with no evidence entry)

Failures:
  Node 3: MISSING-ARTIFACT — "password reset sends email"
  [task: send-reset-email]: MISSING-NODE

Overall: FAIL — fix <F+M> issue(s) before running finish-branch.
```

If all nodes pass and no tasks are missing:

```
Overall: PASS — full proof chain intact, N nodes verified.
PROVEN BY (proof-chain-validator): evidence-trail log → N/N nodes pass, 0 gaps, chain intact.
```

### 7. Block or pass finish-branch

- **PASS:** Emit the `PROVEN BY (proof-chain-validator):` line. Hand off to `finish-branch`.
- **FAIL:** Do not hand off. State each failing node and the fix required. Re-run after fixes.

## Pitfalls

| Mistake | Fix |
|---|---|
| Running without an evidence-trail log | `evidence-trail` must be active from the start of the session — not retrofitted at the end |
| Confusing this skill with `proof-gate` | `proof-gate` writes and enforces one node; this skill validates the entire chain across all nodes |
| Treating a CI green as sufficient without a trail | A CI pass is one artifact; every other claim in the session still needs nodes |
| Skipping validation because "the work is obviously done" | A chain with missing nodes is not a complete proof regardless of perceived quality |

## Pairs with

- `evidence-trail` — produces the log this skill reads; must be running before this skill can validate
- `proof-gate` — writes individual nodes; this skill validates that all nodes form a connected chain
- `detect-agent-cheats` — flags fabricated or reused evidence; run alongside if autonomous agents wrote the trail
- `finish-branch` — this skill is the gate before finish-branch on any multi-skill session
