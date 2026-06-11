---
name: agent-watchdog
description: Use when an autonomous or parallel agent run has started and needs to be monitored for stalls, infinite loops, runaway tool calls, or budget overruns — fires an alert or issues a kill signal when thresholds are exceeded. The safety layer for autonomous-issue-runner and run-agents-in-parallel.
author: Donal Moloney
track: parallelization
type: setup
chains-to: ~
---

## Not this skill if
- You are doing a short, attended task — no watchdog needed if you are watching
- The agent run already finished — use `detect-agent-cheats` to audit output
- You want to poll external CI state — use `self-pacing-poller` for that

# agent-watchdog — monitor running agents for unsafe behaviour

## Purpose

An unattended autonomous agent can stall silently, loop indefinitely, exhaust context, or hammer a tool thousands of times. Without a watchdog, you discover this only when it is too late — the budget is gone, the branch is corrupted, or the session is dead.

The watchdog sets thresholds before a run starts and monitors against them. When a threshold is breached, it surfaces the breach and decides: alert (human decides), pause (agent waits), or kill (agent stopped).

## Core rule

> **Rule:** Configure the watchdog before starting the agent, not after something goes wrong. A watchdog with no thresholds set is not a watchdog.

## Threshold catalogue

Set these before every unattended run. Defaults shown — override per task.

| Threshold | Default | What it catches |
|-----------|---------|----------------|
| `max-tool-calls` | 200 | Runaway loop calling the same tool repeatedly |
| `max-consecutive-same-tool` | 10 | Tight loop on one tool (e.g. Read → Read → Read) |
| `max-bash-runtime-sec` | 120 | Single Bash call that hangs |
| `max-turns-without-progress` | 5 | Agent producing text output but no tool calls |
| `max-context-pct` | 85 | Context approaching exhaustion — trigger recovery before crash |
| `max-wall-clock-min` | 30 | Overall run time cap |
| `max-files-written` | 50 | Unexpected bulk file mutation |

Record thresholds in a watchdog config block at the start of the run:

````
```watchdog
agent: <agent label or worktree path>
started: <turn number>
thresholds:
  max-tool-calls: 200
  max-consecutive-same-tool: 10
  max-bash-runtime-sec: 120
  max-turns-without-progress: 5
  max-context-pct: 85
  max-wall-clock-min: 30
  max-files-written: 50
alert-on: [stall, loop, context]
kill-on: [runaway, budget-overrun]
```
````

## Monitoring loop

The watchdog does not run continuously — it checkpoints. Checkpoint after every N tool calls (default: 20) or at explicit watch points defined in the run plan.

At each checkpoint, evaluate:

```
[ ] tool-calls since start < max-tool-calls?
[ ] last 10 tool calls — same tool repeated? < max-consecutive-same-tool?
[ ] any Bash call still running past max-bash-runtime-sec?
[ ] turns since last file write or meaningful state change < max-turns-without-progress?
[ ] context usage < max-context-pct? (use check-remaining-context)
[ ] wall clock < max-wall-clock-min?
[ ] files written so far < max-files-written?
```

All pass → log checkpoint, continue.
Any fail → evaluate severity and act.

## Severity and actions

| Severity | Condition | Action |
|----------|-----------|--------|
| **Alert** | Single threshold breached for first time | Emit `WATCHDOG ALERT`, surface to user, continue but watch closely |
| **Pause** | Same threshold breached twice, or two thresholds breached simultaneously | Emit `WATCHDOG PAUSE`, stop agent, wait for human decision |
| **Kill** | Runaway (>2x any threshold), context >95%, or explicit kill-on trigger | Emit `WATCHDOG KILL`, stop agent, preserve state for recovery |

Alert format:
```
WATCHDOG ALERT — <threshold name>: <current value> / <max value>
Agent: <label> | Turn: <N> | Tool calls: <total>
Recommended action: <continue / pause / kill>
```

## On pause or kill

**Pause:** emit the alert, stop issuing tool calls, and wait. Do not attempt to fix the condition autonomously — surface it and let the human decide.

**Kill:**
1. Emit `WATCHDOG KILL` with full threshold breach details
2. Run `git stash` in the agent's worktree to preserve in-progress work
3. Record the last known good state (last commit SHA, last passing test)
4. Release the worktree back to the pool (`wtpool release <label>`)
5. Report to user: what was completed, where the agent stopped, what the stash contains

## Integration points

**With `autonomous-issue-runner`:** start the watchdog at step 4 (implement). Kill threshold: 30 min wall clock or 200 tool calls. Alert threshold: context > 80%.

**With `run-agents-in-parallel`:** one watchdog instance per agent. Each has its own config block and checkpoint cadence. Parent aggregates alerts — if any agent hits kill, pause all siblings and surface.

**With `loop-until-green`:** set `max-turns-without-progress: 3` — if the loop runs three consecutive cycles with no new green test, the watchdog pauses and asks whether to continue.

## Related skills

- `agent-harness` — watchdog thresholds are part of harness setup; configure both together
- `autonomous-issue-runner` — this skill is the safety layer for that flow
- `run-agents-in-parallel` — one watchdog per parallel agent
- `check-remaining-context` — the context-pct check delegates to this skill
- `loop-until-green` — integrate watchdog to prevent infinite loops
- `self-pacing-poller` — polls external state; watchdog monitors the agent itself
