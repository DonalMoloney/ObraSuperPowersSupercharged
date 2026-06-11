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
