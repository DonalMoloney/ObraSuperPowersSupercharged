---
name: bug-reproduction-script
description: Use when a web bug report is vague or intermittent ("the form sometimes breaks") — walk the reported steps live in the browser and reduce them to a minimal, deterministic reproduction recipe before debugging.
author: Donal Moloney
tier: v2
supports: [systematic-debugging]
type: technique
chains-to: systematic-debugging
pairs-with: browser-evidence-debugging
---

# Bug Reproduction Script

Supercharges v1 **systematic-debugging**: its first demand is a reliable
reproduction, and for web bugs the way to get one is to drive the reported
steps in a real browser and shrink them until only the essential sequence
remains.

**Gate rule: the repro must succeed twice in a row before it counts as a
reproduction.**

## Precondition

Requires the playwright MCP server (`browser_navigate`, `browser_snapshot`,
`browser_click`, `browser_fill_form`, `browser_console_messages`). If
unavailable, report **blocked** with an install hint.

## Not this skill if

- The bug already reproduces deterministically from a known sequence — go
  straight to **browser-evidence-debugging** for evidence capture.
- The "bug" is a performance complaint — use **performance-trace-audit**.

## Workflow

1. **Extract candidate steps.** From the report, list every action mentioned
   or implied, in order, including preconditions (logged in? data present?).
2. **Walk the steps live.** `browser_navigate`, then per step:
   `browser_snapshot` first, act via the snapshot's roles/labels
   (`browser_click`, `browser_fill_form`), record the EXACT role/name/value
   used. `browser_wait_for` between steps — racing the page creates fake
   intermittency.
3. **Observe the failure.** Console (`browser_console_messages`), failed
   requests (`browser_network_requests`), or wrong on-page state. If the bug
   does not appear, vary the plausible free variables (timing, input values,
   order) one at a time and note what you tried.
4. **Minimize.** Binary-search the step list: drop the first half, retry;
   re-add halves until every remaining step is necessary. The recipe is
   minimal when removing any single step makes the bug vanish.
5. **Verify twice.** Run the minimal recipe twice from a fresh page. Two
   consecutive successes = reproduction. One success is an anecdote.
6. **Produce the repro recipe** (the gate artifact):

   ```text
   Preconditions: <state required>
   1. Navigate to <url>
   2. Click <role/name>
   3. Fill <field> with <value>
   ...
   Expected: <correct behavior>   Actual: <bug>
   Verified: 2/2 runs
   ```

   Optionally also emit the same sequence as a runnable Playwright snippet
   using only the observed roles/labels.
7. **Hand off** to v1 systematic-debugging (or browser-evidence-debugging for
   deep evidence capture) with the recipe.

## Red flags

- Declaring "cannot reproduce" without listing which variables you varied.
- A recipe step that names a selector never seen in a snapshot.
- Counting one lucky failure as a reproduction — run it twice.
