---
name: background-runner
description: Use when a long-running job — full test suite, large refactor, code review, build, broad search — would otherwise block the foreground while you wait. Dispatch it as a tracked background Task, keep working, and collect the result when the harness notifies you. Not for quick inline commands or work whose output you need before the next step.
author: Donal Moloney
track: A
type: technique
chains-to: verify-before-done
pairs-with: self-pacing-poller
---

## Not this skill if

- You need the output before the next step can run — run it inline and wait.
- The command is fast (seconds) — backgrounding adds tracking overhead for no gain.
- You are polling *external* state the harness can't see (CI, remote deploy) — use self-pacing-poller; this skill is for work the harness itself runs and tracks.

# Background Runner

## Purpose

Move a long job off the foreground onto a tracked background Task so the session keeps making progress. The harness notifies you on completion — no manual polling, no blocking wait.

## Triggers

**Use when**
- A full test suite, build, or broad search will take minutes and you have unrelated work to do meanwhile.
- You want `request-review` / `requesting-code-review` to run on a finished chunk while you start the next one.
- A large mechanical refactor can run unattended and report back.

**Don't use when**
- The result gates your very next action (run inline).
- The job is trivially fast.
- You'd spawn so many background Tasks you lose track — batch instead.

## The pattern

### Dispatch and keep working

```
TaskCreate(prompt="run full pytest suite and report failures", label="suite")
# keep working in the foreground — do NOT block on the task
```

The harness tracks the Task and re-invokes you when it exits. There is no need to `ScheduleWakeup` to poll it — backgrounded harness work notifies you on its own.

### Collect on completion

```
TaskOutput(id)        # pull the finished output
TaskList()            # see all in-flight / finished tasks
TaskStop(id)          # cancel one that's no longer needed
TaskUpdate(id, ...)   # adjust a running task's instructions
```

### Async-review variant (the common case)

The moment a logical chunk lands, fire the review in the background and start the next chunk:

```
TaskCreate(prompt="/code-review the current diff; report blocking issues only", label="review:chunk-3")
```

Pair with a stop-hook (e.g. `hooks/gate-stop.sh`) that blocks the **commit** until the background review Task has reported — so async review never silently skips the gate.

## Cheat sheet

| Step | Call |
|------|------|
| Launch | `TaskCreate(prompt, label)` |
| List / status | `TaskList()` / `TaskGet(id)` |
| Collect result | `TaskOutput(id)` |
| Retarget | `TaskUpdate(id, ...)` |
| Cancel | `TaskStop(id)` |
| Notify-on-done | automatic — the harness re-invokes you; no polling |

## Pitfalls

| ❌ Mistake | ✅ Fix |
|-----------|--------|
| Polling a background Task with `ScheduleWakeup` | The harness notifies you on exit — don't poll harness-tracked work |
| Backgrounding work whose output the next step needs | Run it inline; backgrounding only pays off for parallel-able work |
| Firing async review but committing before it reports | Gate the commit on the review Task via a stop-hook |
| Losing track of a dozen Tasks | Label every Task; `TaskList()` before launching more; stop the stale ones |
| Treating a finished Task's output as verified | Route the result through `verify-before-done` before claiming done |

## After

When a background Task completes, collect its output, and if it gates a completion claim hand off to `verify-before-done` before asserting anything is done.

```
PROVEN BY: TaskOutput(suite) shows 412 passed / 0 failed; review Task review:chunk-3 reported no blocking issues; stop-hook confirmed the gate ran before commit.
```
