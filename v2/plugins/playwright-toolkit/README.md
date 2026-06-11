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
