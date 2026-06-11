---
name: rename-skill
description: Use to rename a skill — atomically updates the folder, frontmatter, every chains-to/pairs-with reference, CLAUDE.md, AGENTS.md, upstream-diff.md, OVERVIEW.md tables and alias row, and the flow diagrams, failing loudly if any stale reference remains.
author: Donal Moloney
track: D
type: support
chains-to: find-dangling-refs
---

## Not this skill if
- Renaming several skills at once — use `bulk-rename`
- Only checking for broken links — use `find-dangling-refs`

# rename-skill — atomic, verified skill rename

## Purpose

Make a rename a single safe operation across every touchpoint, honoring the CLAUDE.md rule that
CLAUDE.md and AGENTS.md stay in sync in the same change.

## Core rule

> **Rule:** A rename is done only when a post-rename grep finds zero occurrences of the old slug —
> except the intentional alias row. Attach that clean grep as `PROVEN BY:`.

## Triggers

**Use when:**
- The user says "rename skill X to Y" or "this slug is confusing"
- A differentiation pass changes a skill's public name to align with house vocabulary
- A skill folder name diverges from its `name:` frontmatter and needs to be reconciled
- Merging two similar skills where one slug must be retired in favour of the other

**Don't use when:**
- Renaming more than one skill in a single pass — use `bulk-rename` to avoid partial-update risk
- The goal is only to detect stale references without making changes — use `find-dangling-refs`
- The skill does not yet exist in `skills/` (nothing to rename; author it first)

## Touchpoints (all, atomically)

1. `skills/<old>/` → `skills/<new>/`
2. `name:` frontmatter in the renamed skill's own SKILL.md
3. All `chains-to:` and `pairs-with:` fields across every other skill that reference the old slug
4. `CLAUDE.md` — skill name entries, Upstreams rows, gap-list references
5. `AGENTS.md` — routing table, skill descriptions, any inline examples
6. `upstream-diff.md` — slug column, status column, notes
7. `OVERVIEW.md` tables **+ add an `old → new` alias row** so existing users are not silently broken
8. `diagram/flow/skills-reference.md` and `diagram/flow/flow.md` — node labels and edge annotations

## The pattern

```
1. pre-grep   → build exhaustive reference set
2. repren     → rename contents + paths in one pass
3. alias-row  → add old → new entry to OVERVIEW.md
4. post-grep  → prove zero stale occurrences; fail loudly if any remain
5. proof      → hand off to find-dangling-refs for final structural check
```

## Steps

### Step 1 — Pre-grep: build the reference set

Run a recursive case-sensitive grep for the exact old slug across the entire repo:

```
grep -r --include="*.md" "<old-slug>" .
```

Collect every file path and line number into a working list. Record the total hit count — you will use this as the baseline to confirm the post-rename grep has cleared everything. Do not proceed if the grep errors or if the working list is empty (it means the slug was never registered, and no rename is needed).

### Step 2 — Structural rename with `repren`

Pass the old-slug → new-slug mapping to `repren` with `--full` so it renames both file contents and paths in one atomic pass:

```
repren --full --rename --from "<old-slug>" --to "<new-slug>" skills/ docs/ diagram/ CLAUDE.md AGENTS.md upstream-diff.md OVERVIEW.md
```

Do not hand-edit files individually after this step — partial manual edits alongside `repren` produce split-brain diffs that are hard to review. Let `repren` own the mechanical substitution; you handle only the alias row and proof step.

After `repren` completes, verify the folder has been physically moved:

```
ls skills/<new-slug>/SKILL.md
```

If the file is missing, `repren` silently skipped the folder rename — re-run with the `--rename` flag explicit.

### Step 3 — Add the alias row to OVERVIEW.md

Locate the aliases table in `OVERVIEW.md`. Add one row:

```
| <old-slug> | <new-slug> | renamed |
```

This row is the **only permitted occurrence** of the old slug in the repo after step 4. All other occurrences are errors. Add the row before running the post-grep so you do not confuse the alias row with a stale reference.

### Step 4 — Post-grep: prove zero stale references

Re-run the same grep from Step 1:

```
grep -r --include="*.md" "<old-slug>" .
```

Inspect every hit. Accept the result only if the old slug appears in exactly one location — the alias row you added in Step 3. If any other file still contains the old slug, fix it immediately and re-run the grep. Do not move forward while stale references remain.

If `find-dangling-refs` is available as a registered skill, trigger it now as a structural cross-check. It will verify that no `chains-to:` or `pairs-with:` field references the old slug anywhere in the frontmatter graph.

### Step 5 — Commit atomically

Stage every changed file in a single commit. The commit message must include both the old and new slug so the rename is traceable in `git log`:

```
chore: rename skill <old-slug> → <new-slug>
```

Do not split the rename across multiple commits. A partial rename in the tree is a broken state.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Running `repren` only on `skills/` and missing cross-refs in `CLAUDE.md` or `AGENTS.md` | Always pass every touchpoint directory and file explicitly to `repren` in one invocation |
| Forgetting to add the alias row before post-grep, then treating its absence as proof of success | Add the alias row in Step 3 before running the post-grep; the single remaining hit is expected |
| Committing the rename in two commits — first the folder move, then the cross-ref updates | Stage all changes atomically; a partial rename mid-tree breaks every agent that reads routing tables |
| Grepping only `*.md` files and missing YAML or JSON configs that embed the slug | Extend the grep pattern: `grep -r "<old-slug>" .` without `--include` to catch non-Markdown occurrences |
| Assuming `repren --rename` always moves the folder on case-only renames on macOS (HFS+) | Confirm `ls skills/<new-slug>/SKILL.md` after the run; if missing, rename the folder manually with `mv` |
| Updating `CLAUDE.md` but not `AGENTS.md` in the same commit | The CLAUDE.md rule requires both files change together; check both are in the staged diff before committing |

## Proof

Hand off to `find-dangling-refs` once Step 4 is clean.

The output must contain:

- Post-rename grep result showing exactly one hit (the alias row) for the old slug
- Confirmation that `skills/<new-slug>/SKILL.md` exists and its `name:` frontmatter matches `<new-slug>`
- Confirmation that `CLAUDE.md` and `AGENTS.md` were updated in the same commit
- Alias row added to `OVERVIEW.md` (old slug → new slug, status: renamed)

```
PROVEN BY:
  grep: 1 hit for "<old-slug>" — alias row only (OVERVIEW.md:<line>)
  folder: skills/<new-slug>/SKILL.md present; name: <new-slug>
  CLAUDE.md: updated in commit <sha>
  AGENTS.md: updated in same commit <sha>
  alias row: OVERVIEW.md — <old-slug> → <new-slug> | renamed
```

## Adapt from
- **`jlevy/repren`** — power rename/refactor tool that **already ships a Claude Code skill**; renames
  file contents and paths in one pass. Wrap it + add the verify-grep gate. <https://github.com/jlevy/repren>
