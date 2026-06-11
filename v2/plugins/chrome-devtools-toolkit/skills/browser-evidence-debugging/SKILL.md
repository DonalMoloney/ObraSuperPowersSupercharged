---
name: browser-evidence-debugging
description: Use when debugging any bug, test failure, or unexpected behavior that manifests in a browser — before forming any hypothesis, reproduce it in real Chrome and capture console, network, and screenshot evidence.
author: Donal Moloney
tier: v2
supports: [systematic-debugging]
type: technique
chains-to: systematic-debugging
pairs-with: bug-reproduction-script
---

# Browser Evidence Debugging

Supercharges v1 **systematic-debugging** for web bugs: its investigation phase
demands evidence before hypotheses, and for browser bugs the evidence lives in
a real browser, not in the source code.

**Gate rule: no hypothesis before the evidence table exists.**

## Precondition

Requires the chrome-devtools MCP server. If its tools (`navigate_page`,
`list_console_messages`, …) are not available, report **blocked** and suggest
installing the chrome-devtools-mcp plugin. Do not continue from memory.

## Not this skill if

- The bug never touches a browser (pure backend/CLI) — use v1
  **systematic-debugging** directly.
- You need a deterministic multi-step reproduction recipe — use
  **bug-reproduction-script** (playwright-toolkit) and bring its recipe here.
- The symptom is slowness, not breakage — use **performance-trace-audit**.

## Workflow

1. **Confirm the app is reachable.** If no dev server is running, ask for or
   start one. Never fabricate evidence from source reading alone.
2. **Open a real page.** `new_page` / `navigate_page` to the affected URL.
   Use `wait_for` on expected text before judging anything — async pages lie.
3. **Reproduce the symptom.** Drive the page (`click`, `fill`, `press_key`,
   `evaluate_script`) until you see the reported failure with your own tools.
   If you cannot reproduce it, say so — that is a finding, not a failure.
4. **Harvest evidence in fixed order:**
   - Console: `list_console_messages`; pull details of each error with
     `get_console_message`.
   - Network: `list_network_requests`; flag 4xx/5xx/aborted requests and
     inspect failure bodies with `get_network_request`.
   - Visual: `take_screenshot` of the failing state.
   - State (optional): `evaluate_script` to probe suspicious globals/DOM.
5. **Produce the evidence table** (the gate artifact):

   | Field | Value |
   |---|---|
   | Symptom observed | what actually happened, verbatim |
   | Reproduced? | yes/no + exact steps |
   | Console errors | each message + source location |
   | Failed requests | method, URL, status, response body excerpt |
   | Screenshot | reference to captured image |

6. **Hand off.** Enter v1 systematic-debugging's hypothesis phase with the
   table. Every hypothesis must cite at least one row of it.

## Red flags

- "It's probably X" before step 5 — gate violation, go back.
- Reading only source code for a rendering/runtime bug — open the browser.
- Empty console + no failed requests does not mean no evidence: screenshot
  and DOM state are evidence too.
