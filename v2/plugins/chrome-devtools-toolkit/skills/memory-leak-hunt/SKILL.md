---
name: memory-leak-hunt
description: Use when a web app shows growing memory, detached DOM nodes, or suspected listener leaks — diff heap snapshots around a repeated action to name the leaking constructor before proposing any fix.
author: Donal Moloney
tier: v2
supports: [systematic-debugging]
type: technique
chains-to: systematic-debugging
pairs-with: performance-trace-audit
---

# Memory Leak Hunt

Supercharges v1 **systematic-debugging** for memory bugs: the heap snapshot
diff is the evidence; a leak hypothesis without a named constructor is a guess.

**Gate rule: name the leaking constructor (or listener/node type) before
proposing any fix.**

## Precondition

Requires the chrome-devtools MCP server (`take_heapsnapshot`,
`navigate_page`, page-interaction tools). If unavailable, report **blocked**
with an install hint.

## Not this skill if

- Memory is high but flat — that is a footprint question, not a leak; use
  **performance-trace-audit** thinking instead.
- The symptom is a crash with no growth pattern — use
  **browser-evidence-debugging** first to characterize it.

## Workflow

1. **Identify the suspect action** — the user interaction supposed to leak
   (open/close dialog, route change, list re-render).
2. **Navigate and warm up.** `navigate_page` to the page, then perform the
   suspect action ONCE and discard the effect. First runs allocate caches and
   lazy singletons that would pollute the diff.
3. **Baseline snapshot.** `take_heapsnapshot`.
4. **Repeat the suspect action N times, N ≥ 3.** More repetitions make the
   leak's growth linear and unmistakable in the diff.
5. **Second snapshot.** `take_heapsnapshot`.
6. **Diff by constructor.** Compare retained object counts between snapshots
   via `get_heapsnapshot_summary`, drilling into growing classes with
   `get_heapsnapshot_class_nodes` and `get_heapsnapshot_retainers`.
   A real leak shows count growth proportional to N (e.g. +3 `Subscription`
   after 3 repetitions). Ignore noise that does not scale with N.
7. **Produce the leak report** (the gate artifact):

   | Field | Value |
   |---|---|
   | Suspect action | … |
   | Repetitions (N) | … |
   | Leaking constructor(s) | name + count before → after |
   | Likely retainer | listener / closure / cache / detached node |

8. **Fix, then re-run the SAME protocol** (same N, same action). The leak is
   fixed only when the constructor count stays flat. Report the second table.

## Red flags

- Proposing "add cleanup in useEffect" before a constructor is named.
- Diffing snapshots taken around different actions or different N.
- Skipping warm-up and blaming one-time caches as a leak.
