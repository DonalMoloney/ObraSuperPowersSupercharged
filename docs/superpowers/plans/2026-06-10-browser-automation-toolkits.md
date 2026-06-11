# Browser Automation Toolkits Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two v2 plugins — `chrome-devtools-toolkit` (3 diagnosis skills) and `playwright-toolkit` (3 interaction skills) — that supercharge v1 disciplines with real-browser evidence via the chrome-devtools and playwright MCP servers.

**Architecture:** Each plugin is a skills-only bundle (`.claude-plugin/plugin.json` + `README.md` + `skills/<name>/SKILL.md`), following the `v2/plugins/verification-gate` manifest precedent. Every skill enforces exactly one gate rule and names the v1 skill it supports via `supports:` frontmatter. Spec: `docs/superpowers/specs/2026-06-10-browser-automation-toolkits-design.md`.

**Tech Stack:** Markdown skills, Claude Code plugin manifest, chrome-devtools MCP server tools, playwright MCP server tools.

**Project constraints:**
- Per CLAUDE.md, skills must pass the `skill-auditor` gate BEFORE being committed — so Tasks 1–11 deliberately have no commit steps; Task 13 commits everything once the audit in Task 12 passes. Commit only the files this plan creates/modifies (the repo may carry unrelated in-flight changes — leave them out of the commit).
- TDD analog for a skills repo: each task ends with a structural verification command with expected output; final tasks run the skill-auditor agent and a live MCP smoke test.
- Task 11 (live smoke test) requires the MCP servers and MUST run in the main session, not a subagent.

---

### Task 1: chrome-devtools-toolkit scaffolding

**Files:**
- Create: `v2/plugins/chrome-devtools-toolkit/.claude-plugin/plugin.json`
- Create: `v2/plugins/chrome-devtools-toolkit/README.md`

- [ ] **Step 1: Create the plugin manifest**

Write `v2/plugins/chrome-devtools-toolkit/.claude-plugin/plugin.json`:

```json
{
  "name": "chrome-devtools-toolkit",
  "version": "0.1.0",
  "description": "Diagnosis skills that supercharge v1 systematic-debugging and verification-before-completion with real-Chrome evidence: console/network capture, performance traces, heap-snapshot leak hunting. Requires the chrome-devtools MCP server. tier: v2.",
  "author": {
    "name": "Donal Moloney"
  }
}
```

- [ ] **Step 2: Create the plugin README**

Write `v2/plugins/chrome-devtools-toolkit/README.md`:

```markdown
# chrome-devtools-toolkit (v2 plugin)

Diagnosis skills built on the **chrome-devtools MCP server** — the toolset that
sees *inside* the browser: console, per-request network detail, performance
traces, Lighthouse audits, heap snapshots.

## Precondition

The chrome-devtools MCP server must be installed and its tools available
(`navigate_page`, `list_console_messages`, `performance_start_trace`,
`take_heapsnapshot`, …). Every skill checks tool availability first; if the
tools are missing it reports **blocked** with an install hint
(`claude mcp add chrome-devtools` or the chrome-devtools-mcp plugin) — it never
degrades silently or fabricates evidence.

## Skills

| Skill | Supports (v1) | Gate rule |
|---|---|---|
| `browser-evidence-debugging` | systematic-debugging | No hypothesis before the evidence table exists |
| `performance-trace-audit` | verification-before-completion | No performance claim without before/after traces under identical conditions |
| `memory-leak-hunt` | systematic-debugging | Name the leaking constructor before proposing any fix |

## Routing seam

Diagnosis (traces, heap, network detail, Lighthouse) belongs here.
Interaction work — exercising UI, reproducing flows, verification clicks,
e2e test generation — belongs to the sibling **playwright-toolkit** plugin
(`v2/plugins/playwright-toolkit`).

## Shared conventions

- Every skill ends by producing an artifact (table, numbers, named leak) —
  never a bare "looks fine."
- App not running → ask for or start the dev server; never fabricate evidence.
- Flaky/async pages → `wait_for` before asserting.
```

- [ ] **Step 3: Verify scaffolding**

Run: `python3 -c "import json; print(json.load(open('v2/plugins/chrome-devtools-toolkit/.claude-plugin/plugin.json'))['name'])" && grep -c "Gate rule" v2/plugins/chrome-devtools-toolkit/README.md`
Expected: `chrome-devtools-toolkit` then `1`

---

### Task 2: browser-evidence-debugging skill

**Files:**
- Create: `v2/plugins/chrome-devtools-toolkit/skills/browser-evidence-debugging/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
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
```

- [ ] **Step 2: Verify frontmatter and gate rule**

Run: `grep -E "^(name|tier|supports):" v2/plugins/chrome-devtools-toolkit/skills/browser-evidence-debugging/SKILL.md && grep -c "Gate rule" v2/plugins/chrome-devtools-toolkit/skills/browser-evidence-debugging/SKILL.md`
Expected: `name: browser-evidence-debugging`, `tier: v2`, `supports: [systematic-debugging]`, then `1`

---

### Task 3: performance-trace-audit skill

**Files:**
- Create: `v2/plugins/chrome-devtools-toolkit/skills/performance-trace-audit/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: performance-trace-audit
description: Use when making any web performance claim or working on "make it faster" tasks — record before/after performance traces and Lighthouse audits under identical throttled conditions instead of asserting improvement.
author: Donal Moloney
tier: v2
supports: [verification-before-completion]
type: technique
chains-to: verification-before-completion
pairs-with: browser-evidence-debugging
---

# Performance Trace Audit

Supercharges v1 **verification-before-completion** for performance work:
"evidence before assertions" means numbers from traces, not impressions from
re-reading the diff.

**Gate rule: no performance claim without before-and-after traces recorded
under identical conditions.**

## Precondition

Requires the chrome-devtools MCP server (`performance_start_trace`,
`performance_stop_trace`, `performance_analyze_insight`, `emulate`,
`lighthouse_audit`). If unavailable, report **blocked** with an install hint.

## Not this skill if

- The claim is about correctness, not speed — use **ui-verification-loop**
  (playwright-toolkit) or v1 verification-before-completion.
- You suspect a memory leak — use **memory-leak-hunt**.

## Workflow

1. **Pin the conditions.** Set throttling once and reuse it for every run:
   `emulate` with CPU throttling (e.g. 4x) and a network preset (e.g.
   "Slow 4G"). Unthrottled dev-machine traces hide real regressions.
2. **Record the baseline.** `performance_start_trace` (with page reload) →
   `performance_stop_trace`. Note LCP, CLS, and the top insights.
3. **Analyze.** `performance_analyze_insight` on each flagged insight
   (LCP breakdown, render-blocking requests, layout shifts). Optionally run
   `lighthouse_audit` for category scores.
4. **Write the baseline numbers down** before touching code — afterwards is
   too late to be honest.
5. **Make the change.**
6. **Re-trace under identical conditions.** Same `emulate` settings, same
   page, same reload procedure.
7. **Produce the before/after table** (the gate artifact):

   | Metric | Before | After | Delta |
   |---|---|---|---|
   | LCP | … | … | … |
   | CLS | … | … | … |
   | Lighthouse perf score (if run) | … | … | … |
   | Top insight | … | … | resolved? |

8. **Verdict.** Improved / unchanged / regressed — stated from the table.
   A regression is a finding to report, not something to retry until it
   disappears.

## Red flags

- "Should be faster now" — gate violation; where is the table?
- Comparing a throttled run against an unthrottled one.
- Tracing once and eyeballing — single runs are noisy; if deltas are small,
  trace twice per side and report both.
```

- [ ] **Step 2: Verify frontmatter and gate rule**

Run: `grep -E "^(name|tier|supports):" v2/plugins/chrome-devtools-toolkit/skills/performance-trace-audit/SKILL.md && grep -c "Gate rule" v2/plugins/chrome-devtools-toolkit/skills/performance-trace-audit/SKILL.md`
Expected: `name: performance-trace-audit`, `tier: v2`, `supports: [verification-before-completion]`, then `1`

---

### Task 4: memory-leak-hunt skill

**Files:**
- Create: `v2/plugins/chrome-devtools-toolkit/skills/memory-leak-hunt/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
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
6. **Diff by constructor.** Compare retained object counts between snapshots.
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
```

- [ ] **Step 2: Verify frontmatter and gate rule**

Run: `grep -E "^(name|tier|supports):" v2/plugins/chrome-devtools-toolkit/skills/memory-leak-hunt/SKILL.md && grep -c "Gate rule" v2/plugins/chrome-devtools-toolkit/skills/memory-leak-hunt/SKILL.md`
Expected: `name: memory-leak-hunt`, `tier: v2`, `supports: [systematic-debugging]`, then `1`

---

### Task 5: playwright-toolkit scaffolding

**Files:**
- Create: `v2/plugins/playwright-toolkit/.claude-plugin/plugin.json`
- Create: `v2/plugins/playwright-toolkit/README.md`

- [ ] **Step 1: Create the plugin manifest**

Write `v2/plugins/playwright-toolkit/.claude-plugin/plugin.json`:

```json
{
  "name": "playwright-toolkit",
  "version": "0.1.0",
  "description": "Interaction skills that supercharge v1 verification-before-completion, systematic-debugging, and test-driven-development by driving the browser deterministically: UI verification loops, minimal bug reproductions, e2e test generation from observed selectors. Requires the playwright MCP server. tier: v2.",
  "author": {
    "name": "Donal Moloney"
  }
}
```

- [ ] **Step 2: Create the plugin README**

Write `v2/plugins/playwright-toolkit/README.md`:

```markdown
# playwright-toolkit (v2 plugin)

Interaction skills built on the **playwright MCP server** — the toolset that
drives the browser deterministically: navigation, accessibility-tree
snapshots, form filling, dialogs, multi-tab flows.

## Precondition

The playwright MCP server must be installed and its tools available
(`browser_navigate`, `browser_snapshot`, `browser_click`,
`browser_console_messages`, …). Every skill checks tool availability first;
if the tools are missing it reports **blocked** with an install hint
(`claude mcp add playwright` or the playwright plugin) — it never degrades
silently or fabricates evidence.

## Skills

| Skill | Supports (v1) | Gate rule |
|---|---|---|
| `ui-verification-loop` | verification-before-completion | A passing build is not evidence the UI works; only the exercised page is |
| `bug-reproduction-script` | systematic-debugging | The repro must succeed twice in a row before it counts |
| `e2e-test-generation` | test-driven-development | Never write a selector that was not observed in a snapshot |

## Routing seam

Interaction work — exercising UI, reproducing flows, verification clicks, e2e
test generation — belongs here. Diagnosis (performance traces, heap
snapshots, per-request network detail, Lighthouse) belongs to the sibling
**chrome-devtools-toolkit** plugin (`v2/plugins/chrome-devtools-toolkit`).

## Shared conventions

- Every skill ends by producing an artifact (checklist, recipe, spec file) —
  never a bare "looks fine."
- App not running → ask for or start the dev server; never fabricate evidence.
- Flaky/async pages → `browser_wait_for` before asserting.
```

- [ ] **Step 3: Verify scaffolding**

Run: `python3 -c "import json; print(json.load(open('v2/plugins/playwright-toolkit/.claude-plugin/plugin.json'))['name'])" && grep -c "Gate rule" v2/plugins/playwright-toolkit/README.md`
Expected: `playwright-toolkit` then `1`

---

### Task 6: ui-verification-loop skill

**Files:**
- Create: `v2/plugins/playwright-toolkit/skills/ui-verification-loop/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
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
```

- [ ] **Step 2: Verify frontmatter and gate rule**

Run: `grep -E "^(name|tier|supports):" v2/plugins/playwright-toolkit/skills/ui-verification-loop/SKILL.md && grep -c "Gate rule" v2/plugins/playwright-toolkit/skills/ui-verification-loop/SKILL.md`
Expected: `name: ui-verification-loop`, `tier: v2`, `supports: [verification-before-completion]`, then `1`

---

### Task 7: bug-reproduction-script skill

**Files:**
- Create: `v2/plugins/playwright-toolkit/skills/bug-reproduction-script/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
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
```

- [ ] **Step 2: Verify frontmatter and gate rule**

Run: `grep -E "^(name|tier|supports):" v2/plugins/playwright-toolkit/skills/bug-reproduction-script/SKILL.md && grep -c "Gate rule" v2/plugins/playwright-toolkit/skills/bug-reproduction-script/SKILL.md`
Expected: `name: bug-reproduction-script`, `tier: v2`, `supports: [systematic-debugging]`, then `1`

---

### Task 8: e2e-test-generation skill

**Files:**
- Create: `v2/plugins/playwright-toolkit/skills/e2e-test-generation/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
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
```

- [ ] **Step 2: Verify frontmatter and gate rule**

Run: `grep -E "^(name|tier|supports):" v2/plugins/playwright-toolkit/skills/e2e-test-generation/SKILL.md && grep -c "Gate rule" v2/plugins/playwright-toolkit/skills/e2e-test-generation/SKILL.md`
Expected: `name: e2e-test-generation`, `tier: v2`, `supports: [test-driven-development]`, then `1`

---

### Task 9: Register skills in v2/README.md

**Files:**
- Modify: `v2/README.md` (the "Current skills" table)

- [ ] **Step 1: Append six rows to the Current skills table**

Add these rows at the end of the existing `## Current skills` table (keep
existing rows untouched):

```markdown
| `browser-evidence-debugging` (plugin: chrome-devtools-toolkit) | systematic-debugging |
| `performance-trace-audit` (plugin: chrome-devtools-toolkit) | verification-before-completion |
| `memory-leak-hunt` (plugin: chrome-devtools-toolkit) | systematic-debugging |
| `ui-verification-loop` (plugin: playwright-toolkit) | verification-before-completion |
| `bug-reproduction-script` (plugin: playwright-toolkit) | systematic-debugging |
| `e2e-test-generation` (plugin: playwright-toolkit) | test-driven-development |
```

- [ ] **Step 2: Verify registration**

Run: `grep -c "toolkit)" v2/README.md`
Expected: `6`

---

### Task 10: Structural lint across all six skills

**Files:**
- Verify only (no changes unless lint fails)

- [ ] **Step 1: Frontmatter completeness check**

Run:
```bash
for f in v2/plugins/*/skills/*/SKILL.md; do
  for key in "name:" "description:" "tier: v2" "supports:"; do
    grep -q "^$key" "$f" || echo "MISSING $key in $f"
  done
done; echo LINT-DONE
```
Expected: only `LINT-DONE` (no MISSING lines). Fix any reported file.

- [ ] **Step 2: Tool-name sanity check**

Every MCP tool name referenced in the chrome-devtools skills must be one of
the server's real tools, and likewise for playwright. Run:

```bash
grep -rhoE '`[a-z_]+`' v2/plugins/chrome-devtools-toolkit/skills/ | sort -u
grep -rhoE '`browser_[a-z_]+`' v2/plugins/playwright-toolkit/skills/ | sort -u
```

Compare output against the canonical lists:
- chrome-devtools: `click, close_page, drag, emulate, evaluate_script, fill, fill_form, get_console_message, get_network_request, handle_dialog, hover, lighthouse_audit, list_console_messages, list_network_requests, list_pages, navigate_page, new_page, performance_analyze_insight, performance_start_trace, performance_stop_trace, press_key, resize_page, select_page, take_heapsnapshot, take_screenshot, take_snapshot, type_text, upload_file, wait_for`
- playwright: `browser_click, browser_close, browser_console_messages, browser_drag, browser_evaluate, browser_fill_form, browser_file_upload, browser_handle_dialog, browser_hover, browser_navigate, browser_navigate_back, browser_network_request, browser_network_requests, browser_press_key, browser_resize, browser_run_code_unsafe, browser_select_option, browser_snapshot, browser_tabs, browser_take_screenshot, browser_type, browser_wait_for`

Expected: every backticked tool reference appears in its canonical list
(non-tool backticked words like `getByRole`, `npx`, file names are fine —
only flag names that look like MCP tools but are not in the list). Fix any
mismatch in the SKILL.md.

---

### Task 11: Live MCP smoke test (MAIN SESSION ONLY)

**Files:**
- Create (temporary): `/tmp/toolkit-smoke/index.html`

This task requires the chrome-devtools and playwright MCP servers, which
subagents may not have — execute it in the main session.

- [ ] **Step 1: Create and serve a trivial test page**

Write `/tmp/toolkit-smoke/index.html`:

```html
<!doctype html>
<html>
  <body>
    <h1>Smoke</h1>
    <button id="boom" onclick="console.error('smoke-error'); document.getElementById('out').textContent='clicked'">Trigger</button>
    <p id="out"></p>
  </body>
</html>
```

Run: `cd /tmp/toolkit-smoke && python3 -m http.server 8765 &` (background)
Expected: server listening on http://localhost:8765

- [ ] **Step 2: Smoke the playwright toolkit (ui-verification-loop path)**

Using playwright MCP tools: `browser_navigate` to
`http://localhost:8765` → `browser_snapshot` (expect button "Trigger") →
`browser_click` the Trigger button → `browser_console_messages` (expect
`smoke-error`) → `browser_take_screenshot`.
Expected: all five tools respond; console shows `smoke-error`; snapshot shows
the `clicked` text after the click.

- [ ] **Step 3: Smoke the chrome-devtools toolkit (browser-evidence-debugging path)**

Using chrome-devtools MCP tools: `new_page` / `navigate_page` to
`http://localhost:8765` → `click` the Trigger button →
`list_console_messages` (expect `smoke-error`) → `list_network_requests`
(expect the index.html request) → `take_screenshot`.
Expected: all tools respond; evidence matches the playwright run.

- [ ] **Step 4: Clean up**

Kill the background http.server; remove `/tmp/toolkit-smoke`. If any tool
name failed in steps 2–3, correct the corresponding SKILL.md reference and
re-run Task 10 step 2.

---

### Task 12: skill-auditor pass

**Files:**
- Modify: any SKILL.md the auditor flags

- [ ] **Step 1: Run the auditor**

Dispatch the `skill-auditor` agent with: "Audit the six new v2 plugin skills
under v2/plugins/chrome-devtools-toolkit/skills/ and
v2/plugins/playwright-toolkit/skills/ against the v2 tier rules (tier: v2 +
supports: frontmatter, new identities only, reference-not-duplicate v1,
description states WHEN). Report findings only."

- [ ] **Step 2: Fix findings**

Apply each finding the auditor reports to the relevant SKILL.md. If a finding
conflicts with the approved spec
(`docs/superpowers/specs/2026-06-10-browser-automation-toolkits-design.md`),
the spec wins — note the disagreement instead of changing the file.

- [ ] **Step 3: Final verification**

Re-run Task 10 step 1's lint loop.
Expected: only `LINT-DONE`.

---

### Task 13: Commit (after audit passes)

**Files:**
- Commit only the files created/modified by this plan.

- [ ] **Step 1: Stage exactly this plan's files**

```bash
git add v2/plugins/chrome-devtools-toolkit v2/plugins/playwright-toolkit v2/README.md
```

Run: `git status --short -- v2/plugins/chrome-devtools-toolkit v2/plugins/playwright-toolkit v2/README.md`
Expected: all listed paths staged (`A`/`M`), nothing unrelated staged.

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(v2): add chrome-devtools-toolkit and playwright-toolkit plugins (6 browser-automation skills)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

Expected: one commit on `main` containing the two plugin directories and the
v2/README.md table update. Do not push unless the user asks.
