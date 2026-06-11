---
name: claude-md-watcher
description: Use when the PostToolUse hook has flagged CLAUDE.md as potentially stale — reads the drift ledger and patches only the affected sections. Also callable directly as a targeted alternative to full sync-claude-md.
author: Donal Moloney
track: memory
type: process
chains-to: verify-before-done
---

## Not this skill if
- No drift ledger exists and CLAUDE.md seems current — nothing to do
- You want a full audit/rewrite of CLAUDE.md — use `sync-claude-md` instead

# claude-md-watcher — targeted CLAUDE.md sync from drift ledger

The PostToolUse hook wrote `.claude/claude-md-drift.json` because a structurally significant
file changed. This skill reads that ledger, maps each entry to the CLAUDE.md section it
affects, diffs claim vs reality, and patches only what drifted.

## When to Use

- The hook reminder appeared: `⚠ CLAUDE.md may be stale (...) — invoke claude-md-watcher skill to patch`
- User says "sync CLAUDE.md", "update CLAUDE.md", or "the docs are stale"
- You are about to start a new task and suspect CLAUDE.md is behind

## Workflow

### Step 1 — Read drift ledger

```bash
cat .claude/claude-md-drift.json 2>/dev/null || echo '{"changes":[]}'
```

If `changes` is empty or the file is missing: fall back to `sync-claude-md` for a full audit.
Otherwise proceed in targeted mode.

### Step 2 — Map drift entries to CLAUDE.md sections

| rule_matched | CLAUDE.md sections to check |
|---|---|
| `package-manifest` | **Setup** (install/run commands), **Architecture** (framework bullet) |
| `new-top-level-dir` | **Project structure** (directory tree), **File layout** (ownership table) |
| `entry-point` | **Architecture** (entry-point bullet) |
| `env-config` | **Setup** (env vars block) |
| `ci-build-config` | **Setup** (build/deploy commands) |
| `sub-claude-md` | Full merge check — read both files and reconcile conflicts |

### Step 3 — Diff claim vs reality

For each affected section:
1. Read the current CLAUDE.md section text.
2. Read the changed file(s) from the drift entry.
3. State explicitly what CLAUDE.md claims vs what is true on disk.
4. If they match: mark section as current, move on.
5. If they diverge: prepare a patch (show as a diff block).

### Step 4 — Propose patch

Show the user each diff before applying:

```
Section: Setup
Claim:   npm install && npm start
Reality: pnpm install && pnpm dev  (package.json changed to pnpm)

Patch:
- npm install && npm start
+ pnpm install && pnpm dev
```

Wait for approval before writing.

### Step 5 — Apply and clear

After approval:
1. Apply each patch with the Edit tool.
2. Clear the drift ledger:

```bash
printf '{"changes":[]}\n' > .claude/claude-md-drift.json
```

3. Report: `CLAUDE.md synced — N sections updated, drift ledger cleared.`

### Step 6 — Verify Setup commands (if Setup section was patched)

If the Setup section changed, run the updated commands to confirm they work:

```bash
# Run whatever is now in the Setup section of CLAUDE.md
```

Pairs with `verify-before-done` — treat a patched Setup section as a proof obligation.

## Rules

1. **Never rewrite sections that are current.** Only patch what the drift ledger implicates.
2. **Always show diff before writing.** Never silently edit CLAUDE.md.
3. **Clear ledger only after a successful write.** If Edit fails, leave the ledger intact.
4. **Fallback gracefully.** If the ledger is missing or empty, say so and offer to run `sync-claude-md`.

## Pairs with

- [`sync-claude-md`](../sync-claude-md/SKILL.md) — full audit fallback when ledger is empty
- [`verify-before-done`](../verify-before-done/SKILL.md) — verify Setup commands after patching
