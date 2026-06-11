---
name: bulk-rename
description: Use to rename several skills in one batch (e.g. a differentiation pass) — computes a single combined reference rewrite so cross-references between the renamed skills resolve correctly in one atomic pass.
author: Donal Moloney
track: D
type: support
chains-to: find-dangling-refs
---

## Not this skill if
- Renaming a single skill — use `rename-skill`
- The rename set is exploratory and the final names are not yet decided — settle on the map first
- You only need to update references inside file contents, not folder/file paths — a targeted sed pass is sufficient

# bulk-rename — atomic multi-skill rename

## Purpose

Run a whole rename round (like the 15-skill differentiation pass) as one transaction so cross-references among the renamed skills never point at a half-applied state. A partial rename — where some skills have their new names but others still carry the old name — creates dangling refs that are expensive to untangle. This skill prevents that by treating the full set as a single commit.

## Core rule

> **Rule:** Order and apply the renames as a single transaction, then verify with one post-pass grep.
> Either all land cleanly or none do.

## Triggers

**Use when:**
- Running a house-style or differentiation pass that renames N ≥ 2 skills at once
- Instructed "rename these N skills" with a provided old→new list
- A batch refactor requires updating both folder names and all in-file references atomically
- An alias audit reveals a cluster of skills that need coordinated slugs

**Don't use when:**
- Renaming one skill — use `rename-skill` instead; this skill's transaction overhead is not justified
- The rename list is incomplete or provisional — finalize every row before starting
- Renames are in separate branches that will diverge — coordinate the merge strategy first

## Algorithm

Build the full old→new map; topologically order so a skill is renamed before references to its new name are written; apply with one structural pass (`comby`); verify with a single repo-wide grep.

## Steps

### 1. Collect the old→new map

Build a table with one row per skill being renamed:

```
old-slug           new-slug
──────────────────────────────
using-worktrees    using-git-worktrees
spawn-agents       spawn-subagent
outline            outline-plan
```

Confirm every row is final before proceeding. A rename started with an incomplete map must be aborted and restarted — partial application is worse than no application.

Include in the map:
- Folder name (the skill directory under `skills/`)
- Frontmatter `name:` field inside `SKILL.md`
- Any `chains-to:`, `pairs-with:`, or `description:` values that reference the old slug
- Alias entries in routing tables (`AGENTS.md`, `CLAUDE.md`, skill router files)

### 2. Topologically order the renames

If any new name in the batch is also an old name of another skill in the same batch (a "chain rename"), apply the root rename first. For example: if `A → B` and `B → C` are both in the batch, apply `B → C` before `A → B` so the intermediate name `B` is never a live ambiguous state.

For most differentiation passes the renames are independent and ordering does not matter — verify this before skipping the sort step.

### 3. Dry-run with comby

Run `comby` in dry-run mode across the full repo to confirm the match pattern covers every occurrence:

```bash
comby -config rename.toml -directory . -dry-run
```

Inspect the diff output. Confirm:
- Every old slug appears in the diff the expected number of times
- No unintended matches (e.g., a slug that is a substring of another identifier)
- Path renames are included, not just content rewrites

Adjust match templates in `rename.toml` if any row produces false positives before proceeding.

### 4. Apply the rename transaction

Execute `comby` for content rewrites across all file types in one pass:

```bash
comby -config rename.toml -directory .
```

Then rename the physical directories. If `comby` does not handle path renames for your config, run a targeted rename loop immediately after the content pass — do not let content and path states diverge between commands.

Stage all changes together with `git add -A` so the entire batch appears as one diff. Do not commit per-skill; the whole batch is one atomic commit.

### 5. Update the alias table

Open `AGENTS.md` and `CLAUDE.md`. For every row in the old→new map:
- Replace the old slug with the new slug in skill name references
- Add a deprecated-alias entry if the old slug was externally visible or referenced in docs
- Update `upstream-diff.md` with a row for each renamed skill noting the slug change and the commit SHA

Do not leave any row partially updated. Touch all three files in the same staged changeset.

### 6. Verify — run find-dangling-refs

Chain to `find-dangling-refs` to confirm the batch is clean:

```bash
grep -r "old-slug" . --include="*.md" --include="*.toml" --include="*.json"
```

Run one grep per old slug from the map. A clean batch returns zero matches for every old slug outside of `upstream-diff.md` (which intentionally preserves the historical name).

If any grep returns hits, trace each one, patch it, and re-run the grep before closing.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Starting the apply pass with an incomplete map | Finalize every row before touching any file; abort and restart if a row is added mid-pass |
| Renaming folders before updating contents | Run `comby` content rewrite first, then rename directories; content pointing at old paths breaks if reversed |
| Committing per-skill mid-batch | Stage all changes together; one atomic commit means bisect and revert are safe |
| Leaving old slug in `upstream-diff.md` history rows | `upstream-diff.md` is exempt — preserve old slug in history rows, only update forward-looking references |
| Forgetting `chains-to:` / `pairs-with:` frontmatter fields | Include frontmatter field values in the `comby` match templates; they are not plain prose and are easy to miss |
| Treating a substring match as a full-slug match | Use word-boundary anchors or slug delimiters in `comby` templates to avoid `outline` matching `outline-plan` |

## Proof

Chain to `find-dangling-refs` once the staged changeset is complete.

The output must contain:

- Full old→new map used for the batch (every row)
- `comby` dry-run diff summary (files touched, match count per template)
- Post-apply grep results: one line per old slug showing zero matches (or explicitly listing exempted files such as `upstream-diff.md`)
- Alias table update confirmation (AGENTS.md + CLAUDE.md rows patched)
- `upstream-diff.md` rows added for each renamed skill

```
PROVEN BY:
  - old→new map: <N> rows
  - comby dry-run: <N> files matched, <N> matches total
  - grep clean: all <N> old slugs return 0 hits outside upstream-diff.md
  - alias table: AGENTS.md + CLAUDE.md updated
  - upstream-diff.md: <N> rows added
```

## Adapt from
- **`comby-tools/comby`** — structural search/replace across ~every language and file format in one
  run. <https://github.com/comby-tools/comby>
