---
name: shenron-wish
description: Use when writing the task prompt for any subagent dispatch — the dragon grants exactly what you ask and nothing more, so the wish must state context, one task, forbidden actions, done criteria, and report format before summoning.
author: Donal Moloney
tier: v2
supports: [subagent-driven-development, dispatching-parallel-agents]
type: technique
chains-to: merge-parallel-results
pairs-with: dispatching-parallel-agents
---

## Not this skill if

- You are doing the work yourself in-session — no summoning, no wish.
- The agent is interactive and can ask you questions mid-task — wishes are for fire-and-forget dispatch.

# Shenron Wish

## Purpose

Subagents, like Shenron, grant exactly what you ask — no more. A vague wish wastes the summoning: the agent guesses missing context, does adjacent work you didn't want, and reports in a shape you can't use. The wish template forces precision before dispatch.

Supports v1 **subagent-driven-development** (every per-task dispatch is a wish) and v1 **dispatching-parallel-agents** (each parallel agent gets its own complete wish).

## Triggers

**Use when:**
- About to dispatch any subagent with a task prompt
- A previous agent came back with the wrong thing, did too much, or reported uselessly

**Don't use when:**
- Working inline in the current session

## The five clauses

Every wish contains all five. Missing any clause = not ready to summon.

| Clause | Contains | Failure it prevents |
|---|---|---|
| 1. **Context** | Everything the agent cannot infer: file paths, conventions, prior decisions | Agent re-derives (wrongly) what you already know |
| 2. **Task** | Exactly one task — one wish per dragon | Agent juggles goals and finishes none |
| 3. **Forbidden actions** | Side effects the wish must not cause: files not to touch, no new deps, no API changes | "Helpful" collateral edits |
| 4. **Done criteria** | Objectively checkable conditions: command + expected output | Agent (and you) can't tell when it's done |
| 5. **Report format** | What comes back, in what shape | Unusable wall-of-text reports |

**Hard rule:** if you cannot write clause 4, you don't understand the task well enough to delegate it. Figure out the done criterion first.

## Wish template

```
CONTEXT: <paths, conventions, decisions the agent can't infer>
TASK: <the one thing>
FORBIDDEN: <files/actions off-limits>
DONE WHEN: <command to run + expected output>
REPORT: <exact shape of what to send back>
```

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| "Fix the tests" | Name the failing tests, the suspected area, and the green command |
| Two tasks in one wish | Summon twice — one wish per dragon |
| Assuming the agent sees your conversation | It sees only the wish; put everything needed in CONTEXT |
| No FORBIDDEN clause | Always state side-effect limits; agents default to "helpful" |
| Accepting a report that skips DONE WHEN evidence | Re-summon or verify yourself before integrating |

## After

When agents return, integrate via v2 **merge-parallel-results** (parallel dispatch) or v1 **subagent-driven-development**'s review stage (sequential). Verify the DONE WHEN evidence before accepting any result.
