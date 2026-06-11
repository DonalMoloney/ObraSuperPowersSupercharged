---
name: e2e-test-generation
description: Use when asked to write e2e/browser tests or after a web feature lands — explore the flow live via accessibility snapshots first, then generate Playwright test code using only selectors actually observed on the page.
author: Donal Moloney
tier: v2
supports: [test-driven-development]
type: technique
chains-to: test-driven-development
pairs-with: ui-verification-loop
---

# E2E Test Generation

Supercharges v1 **test-driven-development** for browser flows. The #1 failure
mode of generated Playwright tests is hallucinated selectors — locators that
read plausibly but never matched the real DOM. This skill makes the live page
the source of truth.

**Gate rule: never write a selector that was not observed in a snapshot.**

## Precondition

Requires the playwright MCP server (`browser_navigate`, `browser_snapshot`,
interaction tools). If unavailable, report **blocked** with an install hint.

## Not this skill if

- You just need to verify one change once — use **ui-verification-loop**.
- The logic is testable without a browser — write unit tests via v1
  **test-driven-development**; e2e is the expensive layer, keep it thin.

## Workflow

1. **Define the flow under test.** One user journey per spec (e.g. "sign up
   with valid email"), including its observable end state.
2. **Explore live.** `browser_navigate` through the journey. At each step,
   `browser_snapshot` and record the role/name/label of every element you
   act on, exactly as the accessibility tree reports it. Interact via
   `browser_click` / `browser_fill_form` to confirm the path works.
3. **Harvest assertions from observed end states.** What actually appeared
   (snapshot text, URL, role) after the journey — assert THAT, not what the
   source code suggests should appear.
4. **Generate the spec.** Locators must be `getByRole` / `getByLabel` /
   `getByText` built verbatim from harvested snapshot data — no CSS
   selectors, no XPath, no guessed test-ids. Shape:

   ```ts
   import { test, expect } from '@playwright/test';

   test('sign up with valid email', async ({ page }) => {
     await page.goto('/signup');
     await page.getByLabel('Email').fill('user@example.com');
     await page.getByRole('button', { name: 'Create account' }).click();
     await expect(page.getByRole('heading', { name: 'Welcome' })).toBeVisible();
   });
   ```

   (Every role/name string above must come from step 2's harvest — the
   example shape, not its literals.)
5. **Run it if runnable.** If the project has Playwright installed
   (`@playwright/test` in package.json), run the new spec
   (`npx playwright test <file>`) and require green. Fix locator/timing
   issues by re-snapshotting, not by guessing.
6. **If not runnable**, deliver the spec file plus exact setup instructions
   (`npm i -D @playwright/test && npx playwright install`) and say plainly
   that it has not been executed.

## Red flags

- A locator string that does not appear in any snapshot you took.
- Asserting copy/headings from the source code instead of the rendered page.
- Ten journeys in one spec file — one journey per test, keep e2e thin.
- Adding `waitForTimeout` to fix flake — wait for content, not clocks.
