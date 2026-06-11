---
name: context-variable-relay
description: Use when one skill or agent needs to pass a named value to another skill or agent later in the same session — provides a typed key/value store that survives skill boundaries without polluting conversation prose. Use instead of embedding values in prose that a downstream skill must parse back out.
author: Donal Moloney
track: parallelization
type: support
chains-to: ~
---

## Not this skill if
- You are passing a full work bundle between agents — use `agent-handoff` instead
- The value is only needed in the current turn — just use it inline
- You need values to survive across sessions — use persistent memory files

# context-variable-relay — typed key/value store for skill-to-skill communication

## Purpose

Skills communicate through conversation prose. When `compile-goal-to-contract` produces acceptance criteria, `proof-gate` needs to know what to check against — but it has to parse prose to find them. When `agent-watchdog` records a threshold breach, `autonomous-issue-runner` needs that state — but it lives buried in conversation history.

The relay gives skills a structured side channel: write a named value once, read it anywhere in the session. No prose parsing. No searching conversation history. No embedding JSON in markdown blocks that a downstream model must extract.

## Core rule

> **Rule:** Variables in the relay are write-once per key per session. Overwriting a key requires an explicit `overwrite: true` flag. This prevents accidental clobbering between parallel agents writing to the same session store.

## Variable format

Variables are stored as entries in a session store file: `~/.claude/relay/<session-id>.json`

```json
{
  "contract.acceptance-criteria": {
    "type": "string[]",
    "value": ["Returns 200 on valid input", "Handles empty body with 400"],
    "set-by": "compile-goal-to-contract",
    "turn": 4
  },
  "watchdog.kill-reason": {
    "type": "string",
    "value": "max-tool-calls exceeded: 247/200",
    "set-by": "agent-watchdog",
    "turn": 22
  }
}
```

**Key naming convention:** `<skill-slug>.<variable-name>` — namespaced to avoid collisions between skills.

**Types:** `string`, `number`, `boolean`, `string[]`, `object`. Type is checked on read — type mismatch is an error, not a silent coercion.

## Operations

### SET

Emit a relay write block in your skill's output:

````
```relay-set
key: compile-goal-to-contract.acceptance-criteria
type: string[]
value:
  - "Returns 200 on valid input"
  - "Handles empty body with 400"
```
````

The harness hook reads this block and writes to the session store. If the key already exists and `overwrite: true` is not set, the write is rejected and a warning is emitted.

### GET

Emit a relay read block where you need the value:

````
```relay-get
key: compile-goal-to-contract.acceptance-criteria
into: $CRITERIA
```
````

The harness resolves `$CRITERIA` to the stored value before the skill continues. If the key does not exist, the block resolves to `null` and the skill must handle the missing case explicitly — never assume a variable was set.

### LIST

To inspect what is in the store:

````
```relay-list
prefix: compile-goal-to-contract
```
````

Returns all keys matching the prefix with their types and values. Useful for debugging.

## Standard relay variables

These keys are written and read by built-in skills — do not reuse the names:

| Key | Type | Written by | Read by |
|-----|------|-----------|---------|
| `compile-goal-to-contract.acceptance-criteria` | `string[]` | `compile-goal-to-contract` | `proof-gate`, `done-gate`, `detect-agent-cheats` |
| `compile-goal-to-contract.done-when` | `string[]` | `compile-goal-to-contract` | `verify-before-done`, `autonomous-issue-runner` |
| `agent-watchdog.kill-reason` | `string` | `agent-watchdog` | `autonomous-issue-runner`, `run-agents-in-parallel` |
| `agent-watchdog.last-checkpoint-turn` | `number` | `agent-watchdog` | `agent-watchdog` (next checkpoint) |
| `worktree-pool.leased-path` | `string` | `worktree-pool` | `agent-handoff`, `autonomous-issue-runner` |
| `outline-plan.plan-path` | `string` | `outline-plan` | `execute-plan`, `wave-runner` |

## Parallel agent safety

Each agent in a parallel run shares the same session store but writes to namespaced keys. Collision rules:

- Same key, different agents → the second write is rejected (write-once enforced)
- If both agents legitimately need to write the same logical variable, namespace by agent ID: `agent-1.my-var` / `agent-2.my-var`
- The orchestrator (e.g. `run-agents-in-parallel`) reads both and merges

## Harness wiring

The relay requires the harness to process `relay-set` / `relay-get` / `relay-list` blocks. Wire in `agent-harness` setup:

```json
{
  "hooks": {
    "PreToolCall": [
      {
        "matcher": ".*",
        "hooks": [{ "type": "command", "command": "node ~/.claude/hooks/relay-resolver.mjs" }]
      }
    ]
  }
}
```

`relay-resolver.mjs` reads pending `relay-set` blocks from the last turn and writes them to the store before the next tool call executes. Template provided in `hooks/relay-resolver.mjs.template`.

## Related skills

- `agent-harness` — relay hook must be wired as part of harness setup
- `compile-goal-to-contract` — primary writer of contract variables
- `agent-handoff` — passes full work bundles; relay passes individual named values
- `proof-gate` — reads `done-when` from relay to check evidence targets
- `agent-watchdog` — writes kill state to relay; `autonomous-issue-runner` reads it
- `run-agents-in-parallel` — orchestrator reads per-agent relay keys to merge results
