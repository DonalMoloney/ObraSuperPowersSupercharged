# auto-format (v2 plugin)

`tier: v2` · supports: verification-before-completion, test-driven-development

Runs the **project's own formatter** on each file right after Claude edits it, so
diffs stay clean and reviews don't fill up with whitespace noise. Supports v1
**verification-before-completion** (clean, intentional diffs) and v1
**test-driven-development** (formatting never becomes a separate manual step).

## What it does

A `PostToolUse` hook on `Edit | Write | MultiEdit` looks at the edited file's
extension, finds the matching formatter **if the project actually has it**, and
formats just that one file. It never blocks an edit — any formatter problem is
swallowed and the hook always exits 0.

| Files | Formatter | Runs when |
|---|---|---|
| `.py` | `ruff format` (preferred) or `black` | the binary is on PATH |
| `.js .jsx .ts .tsx .mjs .cjs .json .jsonc .css .scss .less .html .vue .svelte .md .mdx .yaml .yml .graphql` | `prettier --write` | a **project-local** `node_modules/.bin/prettier` exists, **or** a global `prettier` plus a prettier config / `package.json` `"prettier"` key |
| `.go` | `gofmt -w` | the binary is on PATH |
| `.rs` | `rustfmt` | the binary is on PATH |
| `.sh .bash` | `shfmt -w` | the binary is on PATH |

Language-native tools (ruff/black, gofmt, rustfmt, shfmt) run whenever installed —
they're the canonical formatter for their language. Prettier is gated more tightly
so it never imposes its style on a project that didn't opt into it.

## Opt-in by design

The plugin ships **OFF**. Enable it explicitly:

```sh
export AUTOFORMAT_ENABLED=1   # then start Claude Code
```

**Why off by default:** the hook rewrites files *after* an edit. That can make
Claude's cached view of a just-formatted file stale until it re-reads — a real
footgun if it's silent and always on. Opt-in keeps the behavior predictable. Use
`/format-status` to see whether it's enabled and which formatters are wired up for
the current repo.

## Files

- `.claude-plugin/plugin.json` — manifest
- `hooks/hooks.json` — registers the PostToolUse hook
- `hooks/format-on-write.sh` — the hook (bash + embedded python3)
- `commands/format-status.md` — `/format-status`

## Extending

Add an extension → formatter branch in `format-on-write.sh`. Keep the rule:
format only when the tool is actually present, and exit 0 no matter what.
