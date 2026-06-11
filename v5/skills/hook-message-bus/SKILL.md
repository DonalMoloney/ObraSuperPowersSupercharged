---
name: hook-message-bus
description: Use when wiring hooks so that one hook's output automatically triggers another skill or hook — implements a structured event bus over Claude Code's hook system so proof-gate, ci-fan-out-gate, and agent-watchdog can react to each other without manual orchestration. Configure once per project in .claude/settings.json.
author: Donal Moloney
track: parallelization
type: setup
chains-to: ~
---

## Not this skill if
- You want to configure a single hook in isolation — edit settings.json directly
- You are debugging a specific hook that already fires — use `diagnose-bug`
- You want to monitor an agent run — use `agent-watchdog`

# hook-message-bus — structured event routing between hooks and skills

## Purpose

Hooks in Claude Code fire independently. `proof-gate` fires on stop. `ci-fan-out-gate` fires on PR events. `agent-watchdog` checkpoints on tool calls. Right now, these hooks are islands — one firing does not cause another to react.

The message bus wires them together. A hook emits a structured event to a shared log. Subscribers read the log and react. The result: `proof-gate` firing automatically queues `ci-fan-out-gate`; `agent-watchdog` killing an agent automatically notifies `autonomous-issue-runner` to release the worktree.

No new infrastructure — the bus is a JSONL file and a polling pattern. Zero external dependencies.

## Core rule

> **Rule:** The bus is append-only. Hooks emit events; they never delete or modify the log. Subscribers read and act; they never write back to the same log they read.

## Event format

Every hook emits one JSON line to `~/.claude/hook-bus.jsonl`:

```json
{
  "ts": "<ISO-8601 timestamp>",
  "session": "<session-id from CLAUDE_SESSION_ID env>",
  "emitter": "<hook name>",
  "event": "<event-type>",
  "payload": { "<key>": "<value>" }
}
```

**Event types (canonical):**

| Event | Emitted by | Meaning |
|-------|-----------|---------|
| `proof.passed` | `proof-gate` (stop hook) | Turn has valid `PROVEN BY:` block |
| `proof.blocked` | `proof-gate` (stop hook) | Turn attempted done claim without evidence |
| `ci.queued` | `ci-fan-out-gate` | PR CI run queued |
| `ci.passed` | `ci-fan-out-gate` | PR CI passed |
| `ci.failed` | `ci-fan-out-gate` | PR CI failed with details |
| `watchdog.alert` | `agent-watchdog` | Threshold breached — alert severity |
| `watchdog.kill` | `agent-watchdog` | Threshold breached — kill severity |
| `worktree.released` | `worktree-pool` | Worktree returned to pool |
| `issue.done` | `autonomous-issue-runner` | Issue run completed (PR opened) |

Add custom event types by prefixing with your skill name: `my-skill.my-event`.

## Wiring: settings.json

Hooks emit to the bus by appending to the log file. Example stop hook:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "node ~/.claude/hooks/proof-gate-emitter.mjs"
          }
        ]
      }
    ]
  }
}
```

`proof-gate-emitter.mjs` reads `$CLAUDE_TURN_OUTPUT`, checks for `PROVEN BY:`, and appends the appropriate event to the bus. Template in `hooks/proof-gate-emitter.mjs.template`.

## Subscribers

A subscriber is any script that tails the bus log and reacts to matching events. The canonical subscriber pattern:

```js
// subscriber.mjs — tail bus, react to matching events
import { createReadStream } from 'fs'
import { createInterface } from 'readline'

const SESSION = process.env.CLAUDE_SESSION_ID
const TARGET_EVENT = process.argv[2] // e.g. 'proof.passed'

const rl = createInterface({ input: createReadStream(process.env.HOME + '/.claude/hook-bus.jsonl') })
rl.on('line', line => {
  const ev = JSON.parse(line)
  if (ev.session === SESSION && ev.event === TARGET_EVENT) {
    // react
  }
})
```

Subscribers run as background processes started by the skill that needs them. They are not persistent daemons — they exit when the session ends.

## Standard subscriptions

Wire these for every project that uses `autonomous-issue-runner` or parallel agents:

| Event | Subscriber action |
|-------|------------------|
| `proof.blocked` | Log to evidence-trail as UNVERIFIED entry |
| `proof.passed` | Queue `ci-fan-out-gate` if on a PR branch |
| `ci.failed` | Emit alert to user; wake `loop-until-green` |
| `watchdog.kill` | Call `wtpool release` for the killed agent's worktree |
| `watchdog.alert` | Post to `parallel-run-dashboard` state |

## Setup checklist

```
[ ] Bus log file initialised: touch ~/.claude/hook-bus.jsonl
[ ] CLAUDE_SESSION_ID is set in hook environment (check settings.json env block)
[ ] Emitter scripts installed to ~/.claude/hooks/
[ ] Stop hook wired to proof-gate-emitter.mjs
[ ] Subscriber processes started for active subscriptions
[ ] Bus log rotation configured (cron: keep last 7 days, archive older)
```

## Debugging the bus

If a subscription is not firing:
1. `tail -f ~/.claude/hook-bus.jsonl` — confirm events are being emitted
2. Check session ID matches — subscriber must filter by `CLAUDE_SESSION_ID`
3. Check subscriber process is running — `ps aux | grep subscriber`
4. Check emitter exit code — non-zero means the hook script failed silently

## Related skills

- `agent-harness` — bus setup is part of the harness; configure together
- `proof-gate` — primary emitter; `proof.passed` / `proof.blocked` events
- `ci-fan-out-gate` — subscribes to `proof.passed`; emits `ci.*` events
- `agent-watchdog` — emits `watchdog.*` events; subscriber releases worktrees
- `autonomous-issue-runner` — subscribes to `ci.passed` to confirm done
- `parallel-run-dashboard` — consumes `watchdog.alert` and `ci.*` for display
