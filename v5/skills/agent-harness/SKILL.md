---
name: agent-harness
description: Use when setting up or auditing the scaffolding that makes Claude Code behave as a reliable autonomous agent — covers hook architecture, permission layering, structured logging, memory isolation, and eval wiring. Invoke before a long autonomous run or when diagnosing why an agent behaved unpredictably.
author: Donal Moloney
track: parallelization
type: setup
chains-to: orchestrate-feature
---

## Not this skill if
- You want to run agents in parallel right now — use `run-agents-in-parallel`
- You are debugging a specific failed tool call — use `diagnose-bug`
- The harness is already verified and you just want to start the task

# agent-harness — deterministic scaffolding for reliable autonomous agents

## Purpose

The harness is the layer below the model. It handles hooks, permissions, memory routing, observability, and eval — so the model only has to reason, not manage its own environment. A well-built harness makes agent behaviour predictable, auditable, and safe to run unattended.

Build the harness once. Run agents many times.

## Core rule

> **Rule:** Build all harness components before the first model call (eager construction). Never let the model encounter an uninitialized component mid-run — it creates race conditions and unpredictable recovery behaviour.

## Harness components

### 1. Hook architecture

Hooks fire **synchronously** on tool calls — before (pre) and after (post). Async hooks cannot enforce invariants because the model may act before the hook resolves.

```
pre-tool hook  →  tool executes  →  post-tool hook
     ↓                                    ↓
  block / allow                    log / assert / mutate
```

Minimum hooks to wire:
- **Pre-tool:** permission check (allow/deny by tool name + arg pattern)
- **Post-tool:** structured log emit (tool name, args hash, result summary, duration, turn ID)
- **Stop hook:** proof-gate enforcement — block completion claims without `PROVEN BY:`

Hook config lives in `.claude/settings.json`. Never hardcode in SKILL.md.

### 2. Permission layering

Permissions apply in this order (last wins):

```
global defaults (.claude/settings.json)
  └── project overrides (project .claude/settings.json)
        └── session overrides (runtime allow/deny during conversation)
```

Allowlist by default — deny everything, then explicitly permit. Never start with deny-nothing.

Minimum allowlist for a coding agent:
- Read: all files in the repo
- Edit/Write: files matching task scope only
- Bash: `git`, `npm`, `pytest`, `cargo` — whatever the project needs
- Deny: `rm -rf`, network calls outside known hosts, writes to `.git/config`

### 3. Structured logging

Every tool call emits one log line as JSON:

```json
{
  "turn": "<model turn ID>",
  "tool": "<tool name>",
  "args_hash": "<sha256 of serialised args>",
  "result_summary": "<first 120 chars of result>",
  "duration_ms": 142,
  "agent_id": "<worktree or session label>"
}
```

Log to `~/.claude/agent-runs/<session-id>.jsonl`. One file per session. Append-only.

### 4. Memory isolation

The harness owns persistent memory. The model reads from it; it never writes to it directly.

```
model reads → harness memory (read-only to model)
harness writes → memory file (based on structured events, not model output)
```

Session memory (conversation context) is separate from persistent memory. Never conflate.

### 5. Eval wiring

A harness should expose a test interface so agent behaviour can be benchmarked reproducibly:

- **Deterministic task input** — same prompt + same harness config → same tool call sequence
- **Sandboxed execution** — Docker or git worktree isolation so evals do not touch production state
- **Structured assertion** — eval checks tool call sequence and final state, not freeform text output

## Setup checklist

```
[ ] settings.json exists with allowlist (not empty defaults)
[ ] pre-tool hook: permission check registered
[ ] post-tool hook: structured log emit registered
[ ] stop hook: proof-gate enforcement registered
[ ] log directory exists and is writable
[ ] memory file path set; model has read-only access
[ ] worktree pool initialised if parallel run planned (worktree-pool skill)
[ ] eval sandbox ready if benchmarking this run
```

Run the checklist before invoking `orchestrate-feature` or any parallel dispatch skill.

## Diagnosing a broken harness

If an agent behaved unpredictably, check in order:
1. Was the pre-tool hook firing? (check log — missing entries mean hook did not fire)
2. Did a permission deny get silently swallowed? (check hook return code in settings)
3. Was a tool called before the harness initialised? (timestamp of first log entry vs session start)
4. Did memory get written by the model directly? (grep memory file for model-authored prose)

## Related skills

- `proof-gate` — the stop hook this skill wires
- `worktree-pool` — initialise the worktree layer of the harness
- `orchestrate-feature` — the autonomous run this harness enables
- `evidence-trail` — append-only ledger that complements structured logging
