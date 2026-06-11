# frontend — domain skills for frontend work

Skills that make frontend work faster and better in four ways: design quality,
visual verification, bug hunting, and performance. This is the project's first
**domain** folder — organized by subject matter, not provenance. It sits beside
v1–v5, not inside them, and carries no `tier:` field.

All skills lean on the installed browser tools — **Chrome DevTools MCP** and
**Playwright MCP** — and name concrete tool steps (`take_screenshot`,
`list_console_messages`, `performance_start_trace`, …), not abstract process.
Skills are framework-neutral: the browser tools work against any running web app.

Rules:
- Frontmatter must include `name`, `description` (stating WHEN to use), and
  `cluster: design | verify | debug | perf`. No `tier:` field.
- Skills that extend a v1 skill reference it — never duplicate its content.
- Skills overlapping the Anthropic `frontend-design` plugin skill cite it as
  upstream inspiration; nothing is copied verbatim.

## The discipline rule

Every skill in this folder MUST end with a `## Verification` section naming the
concrete browser-tool evidence required before claiming the work done —
screenshots at specific viewports, a clean console sweep, an audit result, a
re-run trace. "A lot better" means **proven** better, not asserted better. This
is the frontend analog of v1 `verification-before-completion`'s "evidence
before assertions."

Layout: skills live in `skills/<skill-name>/SKILL.md`.

## Current skills

| Skill | Cluster | Extends / cites |
|---|---|---|
| `design-direction-first` | design | cites Anthropic `frontend-design` plugin skill (upstream inspiration) |
| `design-system-first` | design | — (standalone; pairs with `design-direction-first`) |
| `visual-verification-loop` | verify | extends v1 `verification-before-completion` |
| `a11y-and-audit-gate` | verify | extends v1 `verification-before-completion` |
| `frontend-bug-forensics` | debug | extends v1 `systematic-debugging` |
| `layout-break-hunt` | debug | — (standalone; feeds `frontend-bug-forensics` when a break is found) |
| `web-vitals-triage` | perf | extends v1 `systematic-debugging` (one-hypothesis loop) |
| `render-and-bundle-discipline` | perf | extends v1 `verification-before-completion` (budgets as evidence) |
