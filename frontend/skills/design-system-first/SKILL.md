---
name: design-system-first
description: Use when adding or changing UI in an existing codebase, before inventing any new color, spacing value, font size, or component. Forces discovery and reuse of the project's existing tokens and components; new tokens are minted only when nothing fits, with a recorded reason.
cluster: design
---

# design-system-first — reuse before invention

**Core rule: every hardcoded style value in new UI code is a bug until proven
to be a deliberate, recorded exception.**

## Not this skill if

- The project is greenfield with no existing styles — use
  `design-direction-first` to establish the direction instead.
- You are debugging a visual break, not adding UI — use `layout-break-hunt`
  or `frontend-bug-forensics`.

## Process

1. **Discover the system before writing code.** In order:
   - Token sources: search for theme/token files (`tailwind.config.*`,
     `theme.*`, `tokens.*`, `*.css` with `:root` custom properties,
     styled-system/vanilla-extract configs).
   - Component inventory: list the existing component directory; note the
     closest existing component to what you need.
   - Live ground truth: on a running page, `evaluate_script` (Chrome DevTools
     MCP) or `browser_evaluate` (Playwright MCP) running
     `getComputedStyle(document.documentElement)` to read the CSS custom
     properties actually in effect.
2. **Map need → existing token/component.** For each style decision the new UI
   requires, write the existing token or component you will use. Extend the
   closest component before forking it; fork before writing from scratch.
3. **Mint only on proven gap.** If nothing fits, mint a new token in the
   system's token file (never inline) and record one line: what was needed,
   what was closest, why it didn't fit.
4. **Sweep your diff for raw values.** Before finishing, grep the changed
   files for hex colors, raw `px` values, and font-family literals. Each hit
   is either replaced with a token or covered by a step-3 record.

## Red flags

- "I'll just use #3B82F6 here" — that's a token (`--color-primary`?) you
  didn't look for.
- A new `Button2`/`CardNew` component beside an existing `Button`/`Card`.
- Minting a token without recording why the existing ones failed.

## Verification

Before claiming the UI done:

1. Diff sweep result: zero unrecorded raw hex/px/font-family literals in the
   changed files (show the grep output).
2. `take_screenshot` / `browser_take_screenshot` of the new UI rendered next
   to (or navigated alongside) an existing screen — visually consistent
   typography, color, and spacing.
3. `evaluate_script` / `browser_evaluate` confirming the new elements resolve
   to system tokens (e.g. computed style of a new element matches the token
   value, not a one-off).

Evidence required: the grep output, the screenshot, and the computed-style
check. Consistency is shown, not claimed.
