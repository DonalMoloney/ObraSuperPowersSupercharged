---
name: format-markdown-for-confluence
description: Use when authoring, formatting, or converting any content for Confluence Cloud pages — covers page templates, panel/macro rules, CQL search, upload patterns, and information hierarchy for status pages, design docs, meeting notes, incident reports, and sprint reviews.
author: Donal Moloney
track: D
type: process
chains-to: verify-before-done
---

## Not this skill if
- The output is legacy Confluence wiki markup — this skill targets **Confluence Cloud** (new editor / storage format).
- The file is a `SKILL.md` — use `unify-skill-style` or `format-markdown-for-claude` instead.
- You need programmatic upload or MCP API operations — see `SpillwaveSolutions/confluence-skill` for REST API scripts.

# format-markdown-for-confluence — generic page authoring & formatting

Confluence pages fail in two ways: information buried in prose that no one reads past the fold, and raw markdown pasted in that renders broken. This skill covers the full authoring workflow — picking a page template, applying the right macros and panels, formatting content to scan at a glance, searching for related pages, and publishing cleanly.

## Core principle

**One idea per visual unit.** Every status, decision, risk, or step must be reachable in a single eye movement — not buried in a sentence.

## Page templates — pick one before writing

| Page type | Lead macro | Required sections |
|---|---|---|
| **Status / project update** | Status macro (🔴🟡🟢) at top | Summary panel → Status table → Decisions → Next steps |
| **Design doc / RFC** | Info panel (problem statement) | Problem → Goal + Non-goals → Approach → Alternatives → Open questions |
| **Meeting notes** | Date lozenge | Attendees → Agenda → Decisions (with owners) → Actions (task macros) |
| **Incident report** | Error panel (severity) | Timeline → Impact → Root cause → Remediation → Prevention |
| **Sprint review** | Progress bar macro | Delivered → Carried → Metrics → Retrospective |
| **How-to / runbook** | Note panel (prerequisites) | Prerequisites → Steps (numbered) → Verification → Rollback |
| **ADR (decision record)** | Info panel | Context → Decision → Consequences → Status |

Start with the template skeleton. Fill sections in order. Never start with blank prose.

## Structural mapping: Markdown → Confluence

| Markdown pattern | Confluence equivalent | Rule |
|---|---|---|
| `# Title` | Page title (not in body) | Remove from body; set as the page name. |
| `## Section` | `<h2>` heading | Keep max two heading levels in body. |
| `### Subsection` | `<h3>` — use sparingly | Collapse `####`+ to bold inside a panel or table cell. |
| Bold inline `**fact**` | Info panel row or table cell | Bolded mid-sentence = hidden scannable fact. Move it. |
| `> Note:` blockquote | Info panel (ℹ️) | Bare blockquotes are invisible in Confluence — always convert. |
| `> ⚠️ Warning:` | Warning panel | |
| `> ❌ Error / blocker:` | Error panel | |
| `> ✅ Tip:` | Success/Tip panel | |
| Long bullet list (> 5 items) | Grouped sections or table | Bullet walls are the #1 readability killer. |
| Paired data `Key: Value` | Two-column table | Status, owners, dates, links — always table. |
| Code block | Code macro with language set | Untagged fences lose syntax highlighting. |
| Inline `` `code` `` | Inline code (preserved) | All commands, paths, identifiers. |
| `- [ ] task` | Confluence task macro | Creates assignable, trackable tasks in page task list. |
| `---` horizontal rule | Section heading or whitespace | Rules don't render — use headings. |
| Long detail / appendix | Expand macro (accordion) | Keeps the page clean; detail on demand. |
| Image / diagram | Drawio, Mermaid, or attachment | Always add a caption below the image. |

## Panel types — when to use each

| Panel | Emoji | Use for |
|---|---|---|
| Info | ℹ️ | Context, notes, background, prerequisites |
| Warning | ⚠️ | Conditions that may cause problems |
| Error | ❌ | Hard blockers, known failures, breaking changes |
| Success/Tip | ✅ | Green-path steps, shortcuts, recommended actions |
| Note | 📝 | Neutral callouts that don't fit the above |

**Rule:** Every `> ` blockquote in source becomes a panel. Every page > 50 lines gets a summary Info panel at the very top (2 sentences: what this page covers, who should read it).

## Information hierarchy — inside any section

Apply this order:

1. One-line summary sentence — what this section tells the reader.
2. Status / decision / owner table (if applicable) — scannable facts first.
3. Panel — any warning, prerequisite, or key constraint.
4. Body content — prose, bullets, numbered steps.
5. Code block — commands, config, output samples.
6. Expand block — additional detail, historical context, raw logs.

## CQL search — find related pages before writing

Before creating a new page, search for duplicates or parents:

```
# Find pages in a space by keyword
space = "ENG" AND text ~ "incident response"

# Find pages by label
label = "runbook" AND space = "OPS"

# Find recently updated pages by type
type = page AND space = "DEV" AND lastModified > "2026-01-01"

# Find by ancestor (get child pages)
ancestor = 123456789

# Full-text across all spaces
text ~ "database migration" ORDER BY lastModified DESC
```

Use CQL in: Confluence search bar, `mcp__atlassian__confluence_search`, or `mark` CLI queries.

## Macro quick reference

| Macro | When to use |
|---|---|
| **Status** | Inline traffic-light badge (🔴🟡🟢) for project/task state |
| **Panel** | Any callout — Info/Warning/Error/Success |
| **Expand** | Collapsible accordion for supplemental detail |
| **Code** | Any code with language tag for syntax highlighting |
| **Task list** | Action items with assignee and due date |
| **Table of Contents** | Auto-generated TOC for pages > 100 lines |
| **Page Properties** | Key-value metadata table (searchable via Page Properties Report) |
| **Page Properties Report** | Aggregate status across many pages (e.g., sprint board) |
| **Date** | Inline date lozenge — links to calendar |
| **Jira Issues** | Inline Jira issue list filtered by JQL |
| **Drawio / Mermaid** | Embedded diagrams — always prefer over images |
| **Column layout** | Two- or three-column layout for side-by-side comparisons |

## Authoring procedure

1. **Pick a template** (table above). Create the heading skeleton before writing any content.
2. **Search first** — run a CQL query to find duplicates or a parent page to nest under.
3. **Strip `# Title` from body.** Set it as the page name. First body element is now the first `##` section.
4. **Add a summary Info panel** at top if the page will exceed 50 lines.
5. **Audit blockquotes.** Convert every `> ` to the matching panel type. Default to Info if unsure.
6. **Break bullet walls.** Any flat list > 5 items: group under a sub-heading, convert to a table, or split into two columns.
7. **Convert paired data.** Any `Key: Value` pattern → two-column table with **Field / Value** header.
8. **Collapse heading depth.** Max two levels (`##` and `###`). Demote `####`+ to bold inside a panel.
9. **Tag every code fence.** Add `bash`, `python`, `sql`, `json`, `yaml`, etc. Bare fences lose all highlighting.
10. **Convert `- [ ] tasks`** to Confluence task macros with assignee and due date.
11. **Wrap supplemental detail** in Expand macros: raw output, historical notes, long examples, alternatives.
12. **Add Page Properties macro** to any status/project page so it appears in space-wide reports.
13. **Run the checklist** before saving.

## Upload patterns (large content)

MCP tools cap uploads at ~10–20 KB. For larger pages or pages with images, use the REST API:

```bash
# Update existing page (from SpillwaveSolutions/confluence-skill)
python3 upload_confluence_v2.py document.md --id PAGE_ID

# Create new page under a parent
python3 upload_confluence_v2.py document.md --space ENG --parent-id PARENT_ID

# Dry-run preview before saving
python3 upload_confluence_v2.py document.md --id PAGE_ID --dry-run

# Git-to-Confluence sync (mark CLI)
# Add frontmatter to .md file:
# <!-- Space: ENG -->
# <!-- Parent: Team Docs -->
mark -f document.md
```

For images: convert diagrams with `mmdc` (Mermaid CLI) or export Drawio to PNG first, then reference with `![Caption](./images/diagram.png)` — the upload script attaches images automatically.

## Red flags

| Thought | Reality |
|---|---|
| "The bullets read fine to me." | You have context the reader lacks. Lists of facts → tables. |
| "I'll keep the blockquote — it's just a note." | Bare blockquotes are nearly invisible in Confluence. Convert to a panel. |
| "Four heading levels is fine." | Confluence pages with 4+ levels confuse the tree view. Collapse to 2. |
| "I'll skip the summary panel — the title says it all." | Title is invisible while scrolling. Top panel anchors every reader. |
| "The code block doesn't need a language tag." | Untagged code renders as monospace only — no highlighting. Always tag. |
| "I'll keep the `---` dividers." | Horizontal rules don't render in Confluence. Use headings. |
| "I don't need to search first — I know this page doesn't exist." | Duplicate pages are the #1 Confluence clutter source. Run CQL first. |
| "I'll add the Page Properties macro later." | Later means never. Add it during authoring so the page shows in reports. |

## Before / after example

**Before — raw markdown:**

```markdown
## Status

- Owner: Donal
- Due: 2026-06-15
- Priority: High

> Note: This feature is behind a flag until QA signs off.

Steps to deploy:
- Pull latest main
- Run `make build`
- Set `DEPLOY_ENV=prod`
- Run `./scripts/deploy.sh`
- Verify health check at `/health`
- Notify #deployments in Slack
```

**After — Confluence-optimised (status page template):**

```
[Info panel] This page tracks the deploy status for Feature X.
Owner: Donal | Review by 2026-06-15.

## Status
| Field    | Value      |
|----------|------------|
| Owner    | Donal      |
| Due      | 2026-06-15 |
| Priority | 🔴 High    |

[Warning panel] Feature is behind a flag until QA signs off.

## Deploy steps
1. Pull latest `main`.
2. Run `make build`.
3. Set `DEPLOY_ENV=prod`.
4. Run `./scripts/deploy.sh`.
5. Verify `/health` returns `200`.
6. Post to `#deployments` in Slack.
```

Key changes: page template applied, paired data → table, blockquote → Warning panel (not Info — it's a hold condition), flat bullets → ordered steps, status badge added, identifiers backticked.

## Checklist (gate before save)

- [ ] Page template skeleton in place before any prose was written.
- [ ] CQL search run — no duplicate page exists; parent page identified.
- [ ] `# Title` removed from body; set as the page name.
- [ ] Summary Info panel at top (if page > 50 lines).
- [ ] Every `> ` blockquote converted to the matching panel type.
- [ ] No flat bullet list longer than 5 items without grouping or a table.
- [ ] All `Key: Value` paired data in a two-column table.
- [ ] Heading depth ≤ 2 levels (`##` and `###` only).
- [ ] Every code fence carries a language tag.
- [ ] `- [ ] tasks` converted to Confluence task macros with assignee + due date.
- [ ] Supplemental / long detail in Expand macros.
- [ ] Page Properties macro added to status/project pages.
- [ ] All paths, commands, env vars, and identifiers backticked.
- [ ] Large pages (> 20 KB) or image-heavy pages use REST API upload, not MCP.
