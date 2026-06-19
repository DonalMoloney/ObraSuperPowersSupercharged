---
description: Show auto-format state — whether the hook is enabled and which project formatters are available for this repo
---

Report the auto-format plugin state for this project:

1. **Enabled?** Check `AUTOFORMAT_ENABLED`. If it is `1`, the PostToolUse hook formats each edited file. Otherwise it is OFF (the default) and edits are left untouched.
2. **Detect available formatters** in the current project, mirroring what the hook checks:
   - Python: `command -v ruff` (preferred) or `command -v black`
   - JS/TS/CSS/HTML/MD/YAML (prettier): `./node_modules/.bin/prettier` (project-local, used whenever present) — or a global `prettier` **only if** a prettier config file or a `"prettier"` key in `package.json` exists
   - Go: `command -v gofmt`
   - Rust: `command -v rustfmt`
   - Shell: `command -v shfmt`
3. **Report**:
   - Hook status: ENABLED / OFF
   - For each language above: the resolved formatter command, or "none available"
   - The net effect: which file extensions would be auto-formatted on edit right now
4. **Explain the toggle**:
   - Enable for a session: export `AUTOFORMAT_ENABLED=1` before launching Claude Code (or in the shell profile).
   - Disable: unset it or set it to `0`.
5. **Note the caveat**: when enabled, the hook rewrites files *after* an edit, so Claude's cached view of a just-formatted file can go stale until it re-reads. This is why the plugin ships OFF by default.
