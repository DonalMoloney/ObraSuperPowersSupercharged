---
name: find-dangling-refs
description: Use after any rename or before a release — scans the repo for references to skill slugs that no longer exist (or to retired aliases) and for skills with zero inbound references. Read-only.
author: Donal Moloney
track: D
type: support
chains-to: ~
---

## Not this skill if
- You're performing the rename itself — use `rename-skill` (it calls this to verify).
- You need a full call-graph with edge weights — use `skill-dependency-graph` instead.
- The only thing that changed is a doc file, not a skill slug — inline grep is sufficient.

# find-dangling-refs — broken-link + orphan scan

## Purpose

Catch the one missed reference a manual rename leaves behind, and surface skills nothing points to. Run it after any slug rename, before any release tag, or whenever you suspect the routing table has drifted from the actual `skills/` tree.

## Core rule

> **Rule:** Report only — change nothing. This is the verifier other skills depend on.

## Triggers

**Use when:**
- You just completed a rename via `rename-skill` and want a final verification pass.
- You are preparing a release and need a clean reference audit before tagging.
- Someone asks "are any skill links broken?" or "is anything pointing to a retired slug?".
- A skill was deleted and you need to confirm no documents still cite it.
- You want to identify orphan skills — skills that exist but are never referenced from routing, other skills, or docs.

**Don't use when:**
- You want to fix the broken references, not just find them — this skill reports; act on its output separately.
- You only need to check a single file or a single slug — a one-liner `grep` is faster.
- The repo has no `skills/` directory yet (nothing to audit).

## Algorithm

Collect the live slug set from `skills/*/SKILL.md` frontmatter → structurally search all docs for `chains-to` / `pairs-with` / inline slug mentions → any target not in the live set is dangling. Inbound-degree = 0 = orphan (same check as `skill-dependency-graph`).

## Steps

### Step 1 — Build the live slug set

Extract every `name:` field from `skills/*/SKILL.md` frontmatter. This is the ground truth: any slug in this set is a live, published skill. Also extract any known aliases from frontmatter `aliases:` lists if present. Record the full set before proceeding — do not filter it.

- Collect: `grep -r '^name:' skills/*/SKILL.md` or parse YAML frontmatter directly.
- Also collect slugs from `v2/skills-to-adapt/*/SKILL.md` if the scan scope includes in-development skills; note these separately as "in-dev, not yet published".

### Step 2 — Collect all outbound references across the repo

Use `ast-grep` or `comby` to locate every place any document names a skill slug. Do not use a plain-text regex alone — structural search avoids false positives in code blocks and comments.

Search locations to cover:
- Every `chains-to:` and `pairs-with:` frontmatter field in all `skills/` and `v2/` SKILL.md files.
- Inline backtick slug mentions (e.g., `` `rename-skill` ``) in `.md` files across the whole repo.
- `CLAUDE.md` and `AGENTS.md` upstream tables and workflow references.
- `upstream-diff.md` skill name rows.
- Any routing config or plugin manifest files that reference skill names.

Record each hit as a `(file, line, referenced-slug)` triple.

### Step 3 — Diff references against the live set to produce the dangling list

For each `(file, line, referenced-slug)` triple from Step 2:
- If `referenced-slug` is in the live slug set → clean, skip.
- If `referenced-slug` is not in the live slug set → dangling reference; add to the dangling list.

Group the dangling list by `referenced-slug` so you can see at a glance which missing slug is cited in multiple places. Within each group, list every `(file, line)` that cites it.

Flag separately any reference to a slug that exists only in `v2/skills-to-adapt/` — these are "premature references" (pointing to an unpublished skill), not broken links, but they should be noted.

### Step 4 — Compute inbound degree to produce the orphan list

For each slug in the live slug set, count how many times it appears as a referenced-slug in Step 2's full hit list. Slugs with inbound-degree = 0 are orphans: they exist but nothing points to them.

Exceptions — do not flag these as orphans even with zero inbound references:
- The router skill (`skill-router` or equivalent entry-point skill) — it is invoked by the user, not by other skills.
- Skills explicitly marked `type: entry` in frontmatter.

List every orphan slug with its file path.

### Step 5 — Format and emit the report

Produce two clearly separated sections:

**Section A — Dangling references** (file:line → missing slug, grouped by missing slug)
**Section B — Orphan skills** (slug → file path, zero inbound references)

If both sections are empty, emit: `No dangling references. No orphan skills. Audit clean.`

Do not edit any file. Do not suggest fixes inline. The report is the entire output of this skill.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Using plain-text `grep` for slug extraction | Use frontmatter-aware parsing; `grep` matches slugs inside code blocks, URLs, and prose, inflating false positives |
| Treating in-dev `v2/` slugs as live | Track them separately; a reference to a `v2/` slug is a premature reference, not a broken link |
| Flagging the router/entry skill as an orphan | Exclude skills with `type: entry` from the orphan check — they are invoked by users, not other skills |
| Stopping after the first missing slug per file | Report all dangling refs in all files; a partial report leads to repeated re-runs |
| Counting self-references as inbound | A skill's own frontmatter referencing itself does not count toward inbound degree |

## Verification / Proof

This skill is read-only and produces no side effects. Verification means confirming the report is complete and accurate, not that any change was applied.

A valid `PROVEN BY:` block for this skill must contain:

- Total live slug count (e.g., "Scanned 42 live slugs from `skills/*/SKILL.md`").
- Total reference hits collected before diffing (e.g., "Found 217 outbound reference triples across 31 files").
- Dangling reference count and list, or explicit "0 dangling".
- Orphan slug count and list, or explicit "0 orphans".
- Confirmation that no file was modified during the run.

```
PROVEN BY:
  - Live slugs scanned: <N>
  - Outbound reference triples collected: <N> across <N> files
  - Dangling references: <N> [list or "none"]
  - Orphan skills: <N> [list or "none"]
  - Files modified: 0
```

Because this skill has `chains-to: ~`, there is no downstream skill to hand off to. The report is the terminal artifact. If dangling references are found, the caller (`rename-skill` or a human) is responsible for acting on the output.

## Adapt from
- **`ast-grep`** (AST-aware structural search, Rust) or **`comby`** (language-agnostic, works on
  Markdown) for precise reference-finding without regex false positives.
  <https://github.com/ast-grep/ast-grep> · <https://github.com/comby-tools/comby>
