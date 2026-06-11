---
name: skill-lint
description: Use when committing any SKILL.md in this repo — runs a structural checklist (frontmatter, tier rules, sections, proof step, no placeholders) and emits a pass/fail per item before the file is merged.
author: Donal Moloney
tier: v2
supports: [writing-skills]
type: decision
chains-to: writing-skills
---

## Not this skill if
- You are auditing an entire tier in bulk — dispatch the project `skill-auditor` agent instead
- The skill has not been written yet — author it first with v1 **writing-skills**, then lint

# skill-lint — structural validator for SKILL.md files

## Purpose

Run a seven-point structural checklist against any `SKILL.md` and emit a clearly labelled pass/fail
per item. Catches missing frontmatter, wrong description format, absent sections, tier-rule
violations, and stale placeholder text before the file reaches review.

Supports v1 **writing-skills**: lint is the mechanical commit gate at the end of that skill's
TDD GREEN phase — it checks structure so review can focus on substance.

**Core rule:** A skill with any `FAIL` item is not ready to commit. Fix every `FAIL` before
proceeding.

## When to use

- Before committing a new or edited `SKILL.md`
- When the v1 **writing-skills** TDD cycle has completed the GREEN phase
- When a PR touches `v*/skills/*/SKILL.md` and a reviewer requests a lint result

## Checklist — seven items, one pass/fail each

Run every item in sequence. Record `PASS` or `FAIL`. Do not skip items.

### 1. Frontmatter completeness

**Check:** The YAML frontmatter block contains the required fields for its tier:

- All tiers: `name` (kebab-case, matching the directory) and `description`
- v2: `tier: v2` and `supports:` listing at least one real v1 skill
- v3: `tier: v3` and `status: experimental`
- v4: `tier: v4` and `inspiration:` naming originator + specific idea

`PASS` if all required fields are present and non-empty.
`FAIL` with message: `Missing frontmatter field(s): <list>`.

### 2. Description starts with "Use when"

**Check:** The `description` value begins with the exact phrase `Use when` (case-sensitive).

`PASS` if true.
`FAIL` with message: `description must start with "Use when"; got: "<first 60 chars>"`.

### 3. "When to use" or "Not this skill if" section present

**Check:** The body contains at least one of these headings:
- `## When to use` (or `## Triggers`)
- `## Not this skill if`

`PASS` if either (or both) are present.
`FAIL` with message: `Neither a when-to-use/triggers section nor "## Not this skill if" found.`

### 4. Process steps are explicit

**Check:** The body contains a numbered list (`1.`, `2.`, …) **or** a checkbox list (`- [ ]`) with
at least two items. A single bullet or a prose paragraph is not sufficient.

`PASS` if two or more numbered or checkboxed steps are present.
`FAIL` with message: `No explicit numbered or checkboxed step list found (minimum 2 steps required).`

### 5. A proof or verification step exists

**Check:** At least one of the following appears anywhere in the body:
- The phrase `PROVEN BY` (in any capitalisation)
- The word `verify` or `verification` (in any capitalisation)
- A reference to `verification-before-completion`

`PASS` if any match is found.
`FAIL` with message: `No proof or verification step found. Add a PROVEN BY block, a verify step, or a reference to verification-before-completion.`

### 6. No TODO / TBD / placeholder text

**Check:** The body does not contain any of these strings (case-insensitive):
`TODO`, `TBD`, `FILL:`, `PLACEHOLDER`, `[fill`, `[todo`, `coming soon`.

`PASS` if none are found.
`FAIL` with message: `Placeholder text found: <matched string(s) with line numbers>.`

### 7. Cross-tier references are valid

**Check:** Every skill referenced in the body or frontmatter (`supports:`, `chains-to:`,
prose references like "use v1 **X**" or "use v5 \`Y\`") resolves to a real directory in the
named tier (`v1/<name>/`, `v2/skills/<name>/`, `v5/skills/<name>/`, …).

`PASS` if every reference resolves.
`FAIL` with message: `Dangling reference(s): <skill name> not found in <tier>.`

## Output format

Emit a table with one row per checklist item:

```
## skill-lint report — <skill-name> — <YYYY-MM-DD>

| # | Check | Result | Detail |
|---|-------|--------|--------|
| 1 | Frontmatter completeness | PASS | — |
| 2 | Description starts with "Use when" | FAIL | description starts with "Checks whether…" |
| 3 | When-to-use section present | PASS | — |
| 4 | Explicit process steps | PASS | — |
| 5 | Proof / verification step | FAIL | No PROVEN BY or verify reference found |
| 6 | No placeholder text | PASS | — |
| 7 | Cross-tier references valid | PASS | — |

Overall: FAIL — 2 item(s) must be fixed before committing.
```

If all seven pass:

```
Overall: PASS — all 7 structural checks green.
```

## Pitfalls

| Mistake | Fix |
|---|---|
| Calling lint on an in-progress stub | Lint fires at commit time. Author the skill first; lint confirms it is complete. |
| Treating a PASS as a quality score | Lint is a binary structural gate, not a quality score. A passing skill still needs human/auditor review. |
| Skipping items because "the content is good" | Run all seven every time. Items are not optional. |
| Linting v3 skills against the v2 bar | v3 only requires item 1's v3 fields plus items 2 and 6 — creativity over polish, per the tier rules. |

## Pairs with

- v1 **writing-skills** — lint is the commit gate at the end of the TDD GREEN phase
- `skill-auditor` agent (this repo) — batch audit across a whole tier; lint is the single-file form

PROVEN BY: the checklist is deterministic; a manual trace against a known-good v2 skill and a deliberately broken stub produces the expected PASS/FAIL results on every item.
