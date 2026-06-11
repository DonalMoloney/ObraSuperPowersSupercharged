---
name: layout-break-hunt
description: Use when a layout has just been built or restyled, before calling it solid — proactively hunts visual regressions by resizing through breakpoints and forcing content extremes (long text, empty states, overflow, RTL where relevant), comparing screenshots against the intended design.
cluster: debug
---

# layout-break-hunt — break it on purpose before users do

**Core rule: a layout is only solid once it has survived every breakpoint ×
every content extreme — with screenshots to show it.**

## Not this skill if

- The layout is already visibly broken and you need the cause —
  `frontend-bug-forensics`.
- You are verifying a specific change works at all — `visual-verification-loop`
  first; this hunt is the deeper pass for layout work.

## The hunt

1. **List the breakpoints.** Read them from the project's CSS/config (media
   queries, Tailwind screens). No declared breakpoints → use 375×812,
   768×1024, 1024×768, 1440×900.
2. **Sweep viewports.** For each breakpoint — and one viewport 1px below each
   threshold, where breaks hide — `resize_page` + `take_screenshot` (Chrome
   DevTools MCP) or `browser_resize` + `browser_take_screenshot` (Playwright
   MCP). Inspect each image for: clipped text, overlap, orphaned wraps,
   horizontal scrollbars, squashed images.
3. **Force content extremes** via `evaluate_script` / `browser_evaluate`
   mutating the live DOM (or fixture data if available), re-screenshotting
   each:
   - Long content: triple a heading, inject a 40-character unbroken string
     (`"Donaudampfschifffahrtsgesellschaftskapitän"`) into names/labels.
   - Empty states: clear list containers, blank optional fields.
   - Overflow: 3× the expected item count in lists/grids/tabs.
   - RTL (where the product supports it): `document.dir = "rtl"`, re-sweep
     the worst two viewports.
4. **Catch silent overflow programmatically.** `evaluate_script` /
   `browser_evaluate`:
   `document.documentElement.scrollWidth > document.documentElement.clientWidth`
   at each viewport — horizontal overflow that screenshots can miss.
5. **Compare against the intended design.** Hold each screenshot against the
   mock/design direction. Log every break found: viewport, content state,
   what broke. Fix, then re-run the failing cell of the matrix.

## Red flags

- Testing only with the demo's tidy placeholder content.
- Resizing exactly to the breakpoint values and never between them.
- Fixing a break and re-checking only that one viewport — fixes shift
  layouts elsewhere; re-run the row.

## Verification

Before claiming the layout solid:

1. The screenshot matrix: every breakpoint (plus the below-threshold
   viewports) × baseline content, each image inspected.
2. Extreme-content screenshots: long-text, empty, and overflow states at the
   two most vulnerable viewports (and RTL if applicable).
3. The `scrollWidth` overflow check returning `false` at every viewport.
4. For each break found: a before-screenshot, the fix, and an
   after-screenshot of the same viewport × content cell.

No matrix, no "responsive."
