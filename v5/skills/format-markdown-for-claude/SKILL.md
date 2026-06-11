---
name: format-markdown-for-claude
description: Use when restructuring any markdown file Claude will read (CLAUDE.md, AGENTS.md, project docs, design notes) so an LLM can scan, parse, and extract the load-bearing rules without losing them in prose
author: Donal Moloney
track: D
type: process
chains-to: verify-before-done
---

## Not this skill if
- The file is a `SKILL.md` — use `unify-skill-style` (prose) or `optimize-skill-for-claude` (structure)
- The file is meant primarily for humans (a blog post, a public README) where narrative voice matters more than agent parseability
- The file is short (< 40 lines) and already structured as a list of rules

## When to use

Run this skill against any markdown that Claude will load as context: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, design specs, internal docs, plan files, or feedback notes. The goal is **agent legibility**: rules that survive a fast scan, no buried obligations, no rotting facts.

Use this skill when at least one of these is true:

- The file mixes narrative prose with load-bearing rules and you can't tell at a glance which is which.
- Important constraints sit inside long paragraphs instead of bullets or tables.
- The file is over ~300 lines and has no visible structure (no headings, no TOC).
- The file contains absolute statements without a "why" (rules without rationale → Claude can't judge edge cases).
- The file mixes durable guidance with time-stamped claims that will age.
- The file uses multiple synonyms for the same concept (e.g. "endpoint" and "URL" and "route" for the same thing).
- Instructions use `must` for both irreversible operations and casual recommendations.
- The file is over ~300 lines and could split heavy reference into linked files.

## How it works

The structural rules below are derived from `skills/writing-skills/anthropic-best-practices.md` and Anthropic's broader guidance on Claude-readable docs. Each rule is **load-bearing**: removing it measurably hurts Claude's ability to act on the file.

### Structural rules

| Rule | Do | Don't |
|------|-----|-------|
| Front-load intent | First H1 or first paragraph states what the file is for and who reads it. | Open with history, motivation, or anecdotes. |
| Heading hierarchy | `#` once. `##` for major sections. `###` for subsections. Never skip levels. | Jump from `#` to `###`. Use bold-line-as-heading. |
| One rule per line | Each rule, constraint, or fact gets its own bullet or row. | Multi-rule sentences joined by `and` / `;`. |
| Tables for paired data | 3+ paired items → table. Comparison data → table. | Long bullet lists when columns would scan faster. |
| Imperative for rules | "Use X for Y." "Never commit Z." | "It is generally recommended that one consider…" |
| Modal verb discipline | `must` = non-negotiable. `should` = advisory (agent may judge). `may` = optional. | Use the wrong strength and Claude either ignores the rule or treats a guideline as a mandate. |
| Rationale per rule | Each non-obvious rule gets a one-line **Why:** so Claude can handle edge cases. | Rules without rationale — Claude follows blindly or skips when context shifts. |
| Backtick identifiers | Backtick every file path, command, env var, flag, function, table name. | Bare identifiers — they vanish into prose. |
| Code fence language tags | Every fence carries a language: ` ```bash`, ` ```python`, ` ```sql`. | Bare ` ``` ` opens. |
| One-level file references | Link to leaf files directly. No `A.md → B.md → C.md` chains. | Chains cause partial reads and missing context. |
| TOC for files > 100 lines | Add `## Contents` listing all H2 sections at the top. | Long files without a TOC force Claude into preview reads that miss later sections. |
| Time-sensitive content | Wrap in `<details><summary>Legacy …</summary>…</details>`. | Inline "as of 2025…" — rots into wrong guidance. |
| Examples over abstractions | One concrete example for any rule that's hard to apply blindly. | "Follow the appropriate convention" — Claude can't infer "appropriate". |
| Absolute paths in critical docs | In `CLAUDE.md` / `AGENTS.md`, reference repo files by absolute path or repo-relative path. | "the config file" — ambiguous across worktrees. |
| Consistent terminology | Pick one word per concept and use it throughout. Glossary table at top if terms are non-obvious. | Mix "endpoint"/"URL"/"route"/"path" for the same thing — Claude may treat them as distinct concepts. |
| Degrees of freedom | Match instruction strength to fragility: exact commands for risky/irreversible ops; heuristics and intent for judgment calls. | Use the same imperative weight for a `git reset --hard` step and a "review the PR" step. |
| Progressive disclosure | Keep the main doc lean. Move any block over ~100 lines to a linked file read only when needed. | Inline all reference material — it loads every session even when irrelevant. |
| Default-first options | When presenting alternatives, recommend one default and add a one-line escape hatch for edge cases. | List N equal alternatives — Claude must choose, which burns tokens and introduces variance. |
| Assume Claude is smart | Only add context Claude doesn't already have. Challenge every sentence: "does Claude need this?" | Explain what a migration is in a doc about running migrations. |

### Section conventions for common file types

**`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`** (agent memory at session start):
- `## Quick start` — 3–5 bullets a fresh agent needs in the first minute.
- `## Project scope` — what the repo is, what it isn't.
- `## Conventions` — durable house rules.
- `## File locations` — where things live (paths).
- `## Workflow` — how work moves through the repo.
- `## References` — links to deeper docs. One level.
- `## Metadata` — last-updated date, owner.

**Design / spec docs:**
- `## Problem` (one paragraph max).
- `## Goal` and `## Non-goals` (bullets).
- `## Approach` (the core decision, with **Why:** lines).
- `## Alternatives considered` (one paragraph each).
- `## Open questions` (bullets).

**Plan / implementation docs:**
- `## Objective` (one sentence).
- `## Steps` (numbered list — each step is concrete and verifiable).
- `## Verification` (how to know each step worked).
- `## Rollback` (how to undo).

These are defaults, not mandates. Skip a section when the doc genuinely doesn't need it.

## Procedure

1. **Audit.** Read the file end-to-end. List every load-bearing rule on a scratch note.
2. **Diagnose.** Run the structural rules table against the file. Mark which rules are violated.
3. **Restructure heading hierarchy** first — get the skeleton right before touching prose. Add a TOC if the file is over 100 lines.
4. **Break prose paragraphs into bullets / tables** where they contain rules.
5. **Backtick identifiers and tag code fences.**
6. **Flatten file references** — any `A → B → C` chain becomes either inline content or `A → B` and `A → C`.
7. **Wrap time-sensitive content** in `<details>` legacy blocks.
8. **Add a one-line `**Why:**` under each non-obvious rule** so Claude can reason at edge cases. If you can't write the rationale, the rule may not belong in the file.
9. **Audit terminology.** Find every synonym for the same concept. Pick one word; replace the rest. If the file uses domain terms a fresh Claude won't know, add a one-row glossary table at the top.
10. **Match instruction strength to fragility.** For any step that is risky or irreversible (destructive git ops, migrations, deploys), write an exact command. For judgment calls, write intent + heuristic. Don't use `must` for both.
11. **Diff** against the original. Verify every scratch-note rule still appears. Verify no new rules were silently introduced.
12. Run the checklist below.

## Red flags

| Thought | Reality |
|---------|---------|
| "This paragraph reads fine to me, it's clear." | Human-clear and agent-legible are different. Bullets and tables scan; paragraphs hide rules. |
| "I'll combine these two rules — they're related." | Two rules = two rows. Combining hides one of them from a scan. |
| "I'll drop the `**Why:**` line — the rule is self-evident." | If it's self-evident, the line is cheap. If it isn't, you've removed the only thing letting Claude judge edge cases. |
| "I'll inline this referenced doc instead of linking." | Sometimes correct; check size first. A 200-line inlined doc bloats the parent and loads even when not needed. |
| "I'll keep this 'as of 2024' note inline — it's still mostly true." | "Mostly true" rots into "now wrong" silently. Wrap it. |
| "The heading hierarchy is fine, I'll just bold the section titles." | Bold isn't a heading. Claude's parser treats them differently. Use `##` / `###`. |
| "I'll skip the TOC, the file is only 130 lines." | Anything over 100 lines is a partial-read risk. TOC is cheap insurance. |
| "I'll convert every `should` to `must` to make Claude take it seriously." | That's a behavior change. `should` and `must` mean different things — preserve the original obligation strength. |
| "I'll use 'endpoint', 'URL', 'route', and 'path' interchangeably — they mean the same thing here." | Claude may not treat them as synonyms. One word per concept; consistency costs nothing. |
| "I'll mark this deploy step as `should` — it's not that risky." | If the step is wrong or skipped, things break. Risky ops get `must` + an exact command, not a heuristic. |
| "I'll keep all this reference material inline — it's only 200 extra lines." | 200 extra lines load every session. Move it to a linked file; it costs zero tokens until needed. |

## Checklist (gate before save)

- [ ] One `#` heading. All other headings step down one level at a time (no `#` → `###` jumps).
- [ ] File ≥ 100 lines → `## Contents` TOC at top listing all `##` sections.
- [ ] Every load-bearing rule is in a bullet, row, or numbered step — not buried in a paragraph.
- [ ] Every non-obvious rule has a `**Why:**` line.
- [ ] All identifiers backticked. All code fences carry language tags.
- [ ] File references are one level deep — no `A → B → C` chains.
- [ ] Time-sensitive content lives in `<details>` legacy blocks, not inline.
- [ ] Original rules all preserved (cross-check against the scratch note from step 1).
- [ ] No new rules added (this skill restructures; if a rule is missing, add it as a separate, marked change).
- [ ] Modal verbs (`must` / `should` / `may`) preserved at their original strength.
- [ ] Terminology is consistent — one word per concept throughout; synonyms eliminated.
- [ ] Instruction strength matches fragility — exact commands for risky/irreversible ops; heuristics for judgment calls.
- [ ] Any block over ~100 lines is in a linked file, not inlined in the parent doc.
- [ ] Option lists recommend a default with a one-line escape hatch, not N equal alternatives.
- [ ] No over-explanation of things Claude already knows (every sentence passes the "does Claude need this?" test).

## Example

**Before — `CLAUDE.md` excerpt (paragraph-buried rules):**

```
We use Postgres for everything and migrations live under db/migrations.
You should generally run tests before pushing because CI is slow and
flaky on Tuesdays. Don't commit the .env file. The deploy script is in
scripts/deploy.sh and as of 2025 it uses the new auth flow.
```

**After:**

```markdown
## Conventions

- **Database:** Postgres. Migrations in `db/migrations/`.
- **Tests before push.** Run the suite locally before pushing.
  **Why:** CI is slow and intermittently flaky, so a local pass saves a round-trip.
- **Never commit `.env`.** Use `.env.example` for shared template values.
- **Deploys:** `scripts/deploy.sh`.

## Old patterns
<details>
<summary>Pre-2025 deploy auth flow</summary>
`scripts/deploy.sh` previously used the legacy auth flow. The current flow is …
</details>
```

Every rule is now scannable in one pass. The flaky-CI rationale is preserved (so Claude won't drop the rule when CI seems healthy). The dated auth-flow detail is wrapped, not deleted.
