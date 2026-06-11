---
name: ui-verification-loop
description: Use when about to claim any frontend change is done, fixed, or working — navigate to the real page, exercise the specific thing that changed, and check console and rendering before making the claim.
author: Donal Moloney
tier: v2
supports: [verification-before-completion]
type: technique
chains-to: verification-before-completion
pairs-with: e2e-test-generation
---

# UI Verification Loop

Supercharges v1 **verification-before-completion** for frontend work. That
skill demands running verification commands before success claims; for UI
changes the verification command is *exercising the page*, because builds and
unit tests cannot see rendering, layout, or runtime wiring.

**Gate rule: a passing build is not evidence the UI works; only the exercised
page is.**

## Precondition

Requires the playwright MCP server (`browser_navigate`, `browser_snapshot`,
`browser_click`, `browser_console_messages`, `browser_take_screenshot`). If
unavailable, report **blocked** with an install hint.

## Not this skill if

- The change is backend-only with no UI surface — v1
  **verification-before-completion** alone is enough.
- You want durable, repeatable coverage of the flow — also run
  **e2e-test-generation** afterwards.

## Workflow

1. **State what changed.** One sentence: which component/behavior this change
   touches. The loop verifies THAT, not the homepage in general.
2. **Navigate.** `browser_navigate` to the affected page; `browser_wait_for`
   the content that proves the page settled.
3. **Snapshot.** `browser_snapshot` — confirm the changed element exists in
   the accessibility tree with the expected role/name.
4. **Exercise the change.** Drive the specific behavior: `browser_click`,
   `browser_fill_form`, `browser_press_key`, `browser_select_option`. A page
   load alone verifies nothing about an interaction change.
5. **Check the console.** `browser_console_messages` — any NEW error or
   warning attributable to the change fails the loop.
6. **Screenshot.** `browser_take_screenshot` of the end state.
7. **Produce the verdict checklist** (the gate artifact):

   | Check | Result |
   |---|---|
   | Page renders (snapshot shows changed element) | pass/fail |
   | Changed behavior works when exercised | pass/fail + what was done |
   | Console clean of new errors | pass/fail |
   | End state matches intent | pass/fail + screenshot ref |

8. **Claim or fix.** All pass → state done, citing the checklist. Any fail →
   back to the code; re-run the FULL loop after the fix.

## Red flags

- "Build passes, change is done" — gate violation for any UI change.
- Verifying by loading the page without exercising the changed interaction.
- Ignoring console errors as "pre-existing" without checking they predate
  the change.
