# Frontend Skills Folder — Design

**Date:** 2026-06-10
**Status:** Approved (brainstorming complete)

## Goal

Add a new top-level `frontend/` folder to ObraSuperPowersSupercharged holding
skills that make frontend work faster and better in three ways the user named:
do frontend design a lot better, verify things, and find bugs (plus performance,
added during scoping). Round one ships 8 handwritten skills, two per cluster.

This is the project's first **domain** folder. v1–v5 are organized by provenance
and discipline (where a skill came from, what quality bar it meets); `frontend/`
is organized by subject matter and sits beside them, not inside them.

## Decisions made during brainstorming

| Question | Decision |
|----------|----------|
| Relation to tier system | New top-level `frontend/` folder beside v1–v5 |
| Tooling stance | Lean on installed browser tools: Chrome DevTools MCP and Playwright MCP — skills name concrete tool steps, not abstract process |
| Scope | All four clusters: design quality, visual verification, bug hunting, performance |
| Round-one size | Focused roster, 8 skills (2 per cluster) |

## Folder structure

```
frontend/
├── README.md            # purpose, discipline rule, skill table
└── skills/
    └── <skill-name>/
        └── SKILL.md
```

- Layout matches the v2–v5 convention: `skills/<kebab-case-name>/SKILL.md`.
- Frontmatter contract: `name`, `description` (must state WHEN to use, per
  project rules), and `cluster: design | verify | debug | perf`.

## The folder's discipline rule

Every skill in `frontend/` MUST end with a `## Verification` section that names
the concrete browser-tool evidence required before claiming the work done —
screenshots at specific viewports, a clean console sweep, an audit result, a
re-run trace. "A lot better" means proven better, not asserted better. This is
the frontend analog of v1 `verification-before-completion`'s "evidence before
assertions."

Skills that extend a v1 skill reference it instead of duplicating its content
(same anti-duplication rule as v2). Skills that overlap the Anthropic
`frontend-design` plugin skill cite it as upstream inspiration; nothing is
copied verbatim.

## Round-one roster (8 skills)

### Cluster: design

1. **`design-direction-first`** — Before writing any UI code, commit to an
   explicit design direction: typography choice, color system, spatial system,
   and one memorable detail. Prevents generic-AI-aesthetic output. Triggers on
   "build a page / component / app." Upstream inspiration: Anthropic
   `frontend-design` skill.
2. **`design-system-first`** — Discover and reuse the project's existing design
   tokens and components before inventing new ones; mint new tokens only when
   nothing fits, and record why. Triggers when adding UI to an existing
   codebase.

### Cluster: verify

3. **`visual-verification-loop`** — Frontend analog of
   `verification-before-completion`. Before claiming any UI change done:
   screenshot at mobile / tablet / desktop viewports, sweep the console for
   errors and warnings, and click through the changed flow live via Playwright
   or Chrome DevTools MCP. No "done" claim without this evidence.
4. **`a11y-and-audit-gate`** — Accessibility snapshot review (roles, labels,
   contrast, keyboard path) plus a Lighthouse audit. Red findings get fixed
   before shipping; the gate re-runs to confirm.

### Cluster: debug

5. **`frontend-bug-forensics`** — Systematic evidence gathering when a UI
   misbehaves, extending v1 `systematic-debugging`: read console messages,
   then network requests, then inspect DOM/state via `evaluate_script` — in
   that order — before forming any hypothesis. Anti-pattern guard: no blind
   CSS/JS tweaking.
6. **`layout-break-hunt`** — Proactive visual-regression hunting: resize
   through breakpoints, toggle content extremes (long text, empty states,
   overflow, RTL where relevant), screenshot-compare against the intended
   design.

### Cluster: perf

7. **`web-vitals-triage`** — Record a performance trace, read the LCP / CLS /
   INP insights, fix the single top offender, then re-trace to prove the
   improvement. One offender per loop iteration.
8. **`render-and-bundle-discipline`** — Catch unnecessary re-renders, oversized
   payloads, and render-blocking resources using the network request list and
   trace data. Budget-driven: state the budget, measure against it.

Each skill is self-contained (one purpose, one clear trigger), names its v1
relative or upstream where one exists, and ends with the mandatory
`## Verification` section.

## Other changes

- **`frontend/README.md`** — explains the folder's purpose, the discipline
  rule, and holds a skill table (name, cluster, what it extends/cites) in the
  style of `v2/README.md`.
- **`CLAUDE.md`** — add a `frontend/` row to the tier-rules table so future
  sessions know: domain folder, browser-tool-driven, mandatory Verification
  section, references v1 rather than duplicating it.

## Out of scope (round one)

- Plugins, agents, or hooks for the frontend folder — skills only.
- Visual screenshot-diffing infrastructure (pixel-comparison tooling); skills
  describe manual screenshot comparison via the MCP tools.
- Framework-specific skills (React-only, Next-only). Round-one skills are
  framework-neutral; the browser tools work against any running web app.

## Verification of this work itself

- `skill-auditor` agent runs over all 8 new skills before the work is called
  done (per the project workflow rule for new or changed skills).
- Each SKILL.md frontmatter parses (name, description, cluster present);
  descriptions state WHEN to use.
- README table lists exactly the 8 shipped skills.
