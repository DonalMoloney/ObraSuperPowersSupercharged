# Browser Automation Toolkits — two v2 plugins

**Date:** 2026-06-10
**Status:** Approved design, pending implementation plan
**Tier:** v2 (plugins)

## Goal

Add browser-automation superpowers as two v2 plugins, each built around one
installed MCP server and each skill explicitly supercharging a v1 discipline:

- **`chrome-devtools-toolkit`** — diagnosis. Chrome DevTools MCP sees *inside*
  the browser: performance traces, heap snapshots, Lighthouse, per-request
  network detail, console.
- **`playwright-toolkit`** — interaction. Playwright MCP drives the browser
  deterministically: navigation, accessibility-tree snapshots, form filling,
  dialogs, test execution.

No browser-automation skill exists in any tier today; nothing here shadows a
v1 core skill, so v2 is the correct home. Decided against: loose v2 skills (no
bundling story), one combined plugin (blurs the DevTools/Playwright seam), and
a v2+v4 split (spreads the suite across tiers). Skills only — no commands,
agents, or hooks in this iteration.

## Layout

```
v2/plugins/chrome-devtools-toolkit/
├── .claude-plugin/plugin.json        # name, version 0.1.0, description ends "tier: v2."
├── README.md                         # purpose, supported v1 skills, preconditions, routing seam
└── skills/
    ├── browser-evidence-debugging/SKILL.md
    ├── performance-trace-audit/SKILL.md
    └── memory-leak-hunt/SKILL.md

v2/plugins/playwright-toolkit/
├── .claude-plugin/plugin.json
├── README.md
└── skills/
    ├── ui-verification-loop/SKILL.md
    ├── bug-reproduction-script/SKILL.md
    └── e2e-test-generation/SKILL.md
```

Manifest shape follows the existing `v2/plugins/verification-gate` precedent:
`plugin.json` has `name`, `version`, `description`, `author`; since plugin.json
has no tier field, the description string ends with "tier: v2." Every SKILL.md
carries `name`, `description` (stating WHEN to trigger), `tier: v2`, and
`supports:` frontmatter per v2 rules.

## Skill specifications

Each skill enforces exactly one **gate rule** — the discipline that makes it a
v2 amplifier of a v1 skill rather than a thin wrapper over MCP tools.

### chrome-devtools-toolkit

#### browser-evidence-debugging
- **supports:** systematic-debugging
- **Trigger:** debugging any bug, test failure, or unexpected behavior that
  manifests in a browser.
- **Workflow:** confirm the app is reachable → navigate in a real Chrome page
  → reproduce the symptom → harvest evidence in fixed order: console messages
  (`list_console_messages`), network requests (`list_network_requests`,
  flagging 4xx/5xx/aborted and inspecting failure bodies via
  `get_network_request`), screenshot (`take_screenshot`), optional
  `evaluate_script` to probe page state.
- **Output:** an evidence table (symptom, console errors, failed requests,
  screenshot reference) feeding systematic-debugging's investigation phase.
- **Gate rule:** no hypothesis before the evidence table exists.

#### performance-trace-audit
- **supports:** verification-before-completion
- **Trigger:** any performance claim or "make it faster" task on a web app.
- **Workflow:** record a baseline trace (`performance_start_trace` /
  `performance_stop_trace`) under throttled CPU/network (`emulate`) for
  realism → `performance_analyze_insight` for LCP/CLS/render-blocking
  findings → optional `lighthouse_audit` for scores → make the change →
  re-trace under identical conditions → report before/after numbers side by
  side.
- **Output:** before/after metrics table.
- **Gate rule:** no performance claim without before-and-after traces recorded
  under identical conditions.

#### memory-leak-hunt
- **supports:** systematic-debugging
- **Trigger:** suspicion of growing memory, detached nodes, or listener leaks.
- **Workflow:** navigate → warm up (run the suspect action once so caches and
  lazy initialization don't pollute the diff) → baseline heap snapshot
  (`take_heapsnapshot`) → repeat the suspect action N times (N ≥ 3) → second
  snapshot → compare retained object counts by constructor → name the leaking
  constructor/listener → after the fix, re-run the same protocol and confirm
  flat growth.
- **Output:** named leak source plus before/after retained-count comparison.
- **Gate rule:** name the leaking constructor before proposing any fix.

### playwright-toolkit

#### ui-verification-loop
- **supports:** verification-before-completion
- **Trigger:** about to claim any frontend change is done.
- **Workflow:** navigate (`browser_navigate`) → accessibility snapshot
  (`browser_snapshot`) → exercise the specific thing that changed
  (`browser_click` / `browser_fill_form` / `browser_press_key` — not just a
  page load) → check `browser_console_messages` for new errors → screenshot →
  verdict checklist: renders, interacts, console clean, matches intent.
- **Output:** completed verdict checklist with screenshot reference.
- **Gate rule:** a passing build is not evidence the UI works; only the
  exercised page is. Cross-references v1 verification-before-completion rather
  than duplicating it.

#### bug-reproduction-script
- **supports:** systematic-debugging
- **Trigger:** vague web bug report ("the form sometimes breaks").
- **Workflow:** extract candidate steps from the report → walk them live via
  Playwright, recording the exact role/label/value at each step →
  binary-search the step list down to the minimal sequence that triggers the
  bug → output a numbered deterministic repro recipe (optionally a runnable
  Playwright snippet) → confirm it reproduces twice before handing off.
- **Output:** minimal numbered repro recipe, verified twice.
- **Gate rule:** the repro must succeed twice in a row before it counts as a
  reproduction.

#### e2e-test-generation
- **supports:** test-driven-development
- **Trigger:** "write e2e tests" requests, or after a web feature lands.
- **Workflow:** explore the flow live via accessibility snapshots to harvest
  the real roles/labels/names → derive assertions from observed end states →
  generate spec code using `getByRole` / `getByLabel` style locators only →
  if the project has Playwright installed, run the new test and require green;
  otherwise deliver the spec with setup instructions and say so plainly.
- **Output:** spec file built from observed locators; green run when runnable.
- **Gate rule:** never write a selector that was not observed in a snapshot.

## Shared conventions (stated in both READMEs)

- **Routing seam:** diagnosis (traces, heap, network detail, Lighthouse) →
  chrome-devtools-toolkit; interaction, verification, reproduction, test
  generation → playwright-toolkit. Each README points to the other.
- **Preconditions:** the corresponding MCP server (`chrome-devtools-mcp` /
  `playwright`) must be installed. Skills check tool availability first and
  report **blocked** with an install hint rather than degrading silently.
- **Evidence discipline:** every skill ends by producing an artifact (table,
  numbers, recipe, spec file) — never a bare "looks fine."
- **Failure handling:** app not running → ask for or start the dev server,
  never fabricate evidence; flaky/async pages → wait (`wait_for` /
  `browser_wait_for`) before asserting.

## Testing & integration

- Run the **skill-auditor** agent on all six skills before finishing.
- Add all six skills to the "Current skills" table in `v2/README.md` with
  their `supports:` mappings.
- Live smoke test: exercise one skill from each plugin against a trivial local
  page to confirm the MCP tool names referenced in each SKILL.md match the
  tools the servers actually expose.

## Out of scope

- Slash commands, subagents, and hooks (explicitly deferred; skills only).
- Any change to v1 skills; these reference v1, never modify it.
- CI integration or packaged distribution beyond the plugin directories.
