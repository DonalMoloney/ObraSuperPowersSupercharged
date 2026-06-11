---
name: self-pacing-poller
description: Use when watching external state the harness cannot notify you about — a CI run, a remote deploy, an external queue or build — and you need to poll at a cadence matched to how fast that state actually changes.
author: Donal Moloney
track: A
type: technique
chains-to: verify-before-done
pairs-with: ralph-loop-adapted
---

## Not this skill if

- The work is a harness-tracked background task — you will be auto-notified on completion; do not poll.
- The state changes on a fixed, known schedule — use scheduled-maintenance or a cron trigger instead.

# Self-Pacing Poller

## Purpose

Poll external state at an interval matched to how fast that state changes, not a round number. Keep the prompt cache warm on active polls; pay one cache miss for long idle waits.

## Triggers

**Use when:**
- "Watch the deploy until it goes live"
- "Tell me when CI finishes"
- "Wait for the remote job / queue item"
- Polling an external build, run, or API you have no push notification for

**Don't use when:**
- A background task is already tracked by the harness (it notifies you)
- State changes on a predictable fixed schedule (use a cron instead)

## The pattern

Prompt-cache TTL is ~5 minutes (300 s). Staying under 270 s keeps the cache warm; 300 s is the worst choice — misses cache without the benefit of a long wait.

| Situation | Chosen delay | Reasoning |
|---|---|---|
| Active poll — CI run, deploy, queue item | < 270 s | Cache stays warm; each wakeup is cheap |
| Idle / slow-changing — waiting minutes+ | 1200 s+ | One cache miss buys a long unattended wait |
| Never pick this | 300 s | Worst of both — misses cache, doesn't amortize |

Example: `ScheduleWakeup(delay=240, reason="watching CI run #4821 — waiting for green or failed")`. The `reason` must name the specific thing being watched.

## Pitfalls

| | Wrong | Right |
|---|---|---|
| ❌ Round-number trap | `delay=300` — straddles the cache boundary | `delay=240` or `delay=1200` |
| ❌ Polling harness work | Polling a background task the harness is tracking | Let the harness notify you; skip this skill |
| ❌ Vague reason | `reason="waiting"` | `reason="watching deploy to prod — checking health endpoint"` |
| ❌ Over-polling a slow build | 60 s interval through an 8-min build (8 wakeups) | Two 240 s wakeups — same coverage, cache stays warm |

## Completion

When the watched state reaches its terminal value (build green, deploy live, job complete):

1. Record the terminal state explicitly.
2. If the result gates a completion claim, hand off to `verify-before-done` before asserting done.
3. Close with:

```
PROVEN BY: CI run #4821 reached "passed" at 14:32 UTC — deploy health endpoint returned 200.
```
