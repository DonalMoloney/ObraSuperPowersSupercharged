---
name: design-direction-first
description: Use when starting any new UI work — building a page, component, or app — before writing the first line of UI code. Forces an explicit design direction (typography, color, spatial system, one memorable detail) so the output is not generic AI aesthetic.
cluster: design
---

# design-direction-first — commit to a direction before code

Upstream inspiration: the Anthropic `frontend-design` plugin skill — its core
insight is that distinctive interfaces come from committing to a bold,
coherent aesthetic direction up front. This skill operationalizes that for
this repo; nothing is copied verbatim.

**Core rule: no UI code until a written design direction exists and a
screenshot later proves the code matches it.**

## Not this skill if

- You are adding UI to a codebase with an established design system — use
  `design-system-first`; the direction is already chosen.
- You are fixing a bug or tweaking an existing screen — the direction exists;
  use `visual-verification-loop` to prove the tweak.

## Process

1. **Write the direction** (4 lines, before any code):
   - **Typography:** the typeface(s) and scale, and what they signal
     (e.g. "editorial serif display + neutral grotesque body").
   - **Color system:** background, foreground, one accent — as actual values,
     not adjectives. State light/dark stance.
   - **Spatial system:** the spacing unit and density (e.g. "8px grid, generous
     — min 24px between groups").
   - **One memorable detail:** a single element someone would screenshot
     (an oversized number, a signature hover, an unusual layout split). One.
2. **Reject the default.** If the direction reads like "Inter, blue-600,
   rounded-xl, card grid" — that is the generic AI aesthetic. Rewrite it with
   a point of view before proceeding.
3. **Build to the direction.** Every styling decision traces to one of the
   four lines. A decision that traces to none of them is drift — stop and
   either revise the direction or the code.
4. **Prove it in the browser.** Render the result and compare against the
   written direction (see Verification).

## Red flags

- Code first, "style it later" — later never has a direction.
- Three accent colors, two memorable details — that's no direction at all.
- Direction written but never compared against the rendered result.

## Verification

Before claiming the UI done:

1. `take_screenshot` (Chrome DevTools MCP) or `browser_take_screenshot`
   (Playwright MCP) of the rendered result at desktop (1440×900 via
   `resize_page` / `browser_resize`) and mobile (375×812).
2. Hold the screenshots against the 4-line direction and state, line by line,
   where each is visible in the image (typography ✓/✗, color ✓/✗, spacing
   ✓/✗, memorable detail ✓/✗).
3. `list_console_messages` / `browser_console_messages` — zero errors.

Evidence required: the two screenshots, the line-by-line match statement, and
the clean console sweep. No screenshots, no "done."
