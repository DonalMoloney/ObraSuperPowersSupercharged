---
name: frontend-bug-forensics
description: Use when a UI misbehaves — wrong render, dead interaction, missing data, unexpected state — before proposing any fix or touching any CSS/JS. Gathers browser evidence in fixed order (console, network, DOM/state) so hypotheses are grounded, not guessed.
cluster: debug
---

# frontend-bug-forensics — evidence in fixed order, then hypotheses

Extends v1 **systematic-debugging** for browser bugs. That skill owns the
overall discipline — reproduce, investigate, hypothesize one cause at a time,
verify the fix; read it first. This skill supplies the browser-specific
investigation phase it demands: for UI bugs the evidence lives in a running
browser, not in the source.

**Core rule: no hypothesis and no blind CSS/JS tweaking until all three
evidence layers are read — console, then network, then DOM/state — in that
order.**

## Not this skill if

- The bug never touches a browser (backend, CLI) — v1
  **systematic-debugging** directly.
- The page is correct but ugly/broken at some sizes — `layout-break-hunt`.
- The symptom is slowness — `web-vitals-triage`.
- You are working from the v2 plugin layer — `browser-evidence-debugging`
  (v2 chrome-devtools-toolkit) covers the same evidence sweep; use one, not both.

## The forensic order

0. **Reproduce live.** `navigate_page` / `browser_navigate` to the affected
   page and drive it to the failing state (`click`, `fill`, `browser_click`,
   `browser_type`). `take_screenshot` the failure. Can't reproduce it? Say so
   — that is a finding.
1. **Console first.** `list_console_messages` (Chrome DevTools MCP) or
   `browser_console_messages` (Playwright MCP); pull full detail of each
   error with `get_console_message`. Record every error and relevant warning
   with its source location.
2. **Network second.** `list_network_requests` / `browser_network_requests`;
   flag 4xx/5xx, aborted, and suspiciously empty responses; inspect bodies
   with `get_network_request` / `browser_network_request`. A UI showing
   nothing often received nothing.
3. **DOM and state third.** `evaluate_script` / `browser_evaluate` to probe
   what the page actually holds: does the element exist, what are its
   computed styles, what does the relevant store/global contain, what do the
   component props resolve to.
4. **Then hypothesize — back in v1 systematic-debugging.** Every hypothesis
   must cite at least one piece of evidence from layers 1–3. Fix one cause,
   then re-run step 0 to confirm the symptom is gone.

## Red flags

- Editing CSS to "see if it helps" — that is the anti-pattern this skill
  exists to block.
- Skipping the network layer because "it's clearly a frontend bug."
- A hypothesis that cites no console line, no request, and no DOM probe.

## Verification

Before claiming the bug fixed:

1. The evidence record: console output (layer 1), flagged requests (layer 2),
   and DOM/state probe results (layer 3), each tied to the hypothesis that
   the fix addressed.
2. Re-reproduction run after the fix: the same steps as step 0, ending in a
   `take_screenshot` / `browser_take_screenshot` of the now-correct state.
3. Post-fix `list_console_messages` / `browser_console_messages` — the
   original error is gone and no new one appeared.

Evidence required: before-screenshot, after-screenshot, and the clean
post-fix console. "Should be fixed" without the re-run is a guess.
