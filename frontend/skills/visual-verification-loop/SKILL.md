---
name: visual-verification-loop
description: Use when about to claim any UI change is done, fixed, or working — before saying so. Requires screenshots at mobile/tablet/desktop, a clean console sweep, and a live click-through of the changed flow. The frontend analog of v1 verification-before-completion.
cluster: verify
---

# visual-verification-loop — no "done" without browser evidence

Frontend form of v1 **verification-before-completion**: evidence before
assertions, always. That skill defines the discipline (run the verification,
read the output, only then claim success); this skill defines what the
verification IS for UI work. Read it for the rule; read this for the steps.

**Core rule: a UI change you have not seen rendered, at three viewports, with
a clean console, is not done — it is untested code that compiles.**

## Not this skill if

- The change has no visible surface (build config, pure logic with passing
  unit tests) — v1 **verification-before-completion** alone covers it.
- You are hunting for layout breaks across content extremes — that is
  `layout-break-hunt`; this skill verifies one specific change.
- You are working from the v2 plugin layer — `ui-verification-loop`
  (v2 playwright-toolkit) covers the same gate; use one, not both.

## The loop

1. **Navigate to the changed surface.** `navigate_page` (Chrome DevTools MCP)
   or `browser_navigate` (Playwright MCP) to the affected URL. Use `wait_for`
   / `browser_wait_for` on expected text — never judge a half-loaded page.
2. **Screenshot at three viewports.** Resize and capture at each:
   - mobile 375×812 — `resize_page` then `take_screenshot`
     (Playwright: `browser_resize` then `browser_take_screenshot`)
   - tablet 768×1024 — same pair
   - desktop 1440×900 — same pair
   Look at each image. "I took it" is not "I looked at it."
3. **Sweep the console.** `list_console_messages` / `browser_console_messages`.
   Zero errors required; every warning either pre-exists (prove it by checking
   before/after) or gets fixed.
4. **Click through the changed flow live.** Drive the actual interaction the
   change affects — `click`, `fill`, `press_key` (Playwright: `browser_click`,
   `browser_type`, `browser_press_key`) — and confirm the end state with
   `wait_for` or a final screenshot.
5. **Only now claim done**, citing the evidence by name.

## Red flags

- "The code looks right" — rendering disagrees with reading often enough.
- Screenshotting only desktop — mobile is where it broke.
- Console swept before the click-through — interactions throw too; sweep after.

## Verification

This skill IS a verification gate. The required evidence before any "done"
claim:

1. Three screenshots (375×812, 768×1024, 1440×900) of the changed surface,
   each actually inspected.
2. Console sweep output after the click-through: zero errors, warnings
   accounted for.
3. The click-through result: final-state screenshot or `wait_for` match of
   the expected outcome.

Missing any of the three → the claim is "in progress," not "done."
