#!/bin/bash
# PostToolUse hook (Edit|Write|MultiEdit): format the just-edited file with the
# project's own formatter, so Claude's diffs stay clean without manual passes.
#
# Opt-in: does nothing unless AUTOFORMAT_ENABLED=1. A hook that rewrites files
# behind the agent can make Claude's cached view of a file stale, so it ships
# OFF. See /format-status and the plugin README.
#
# Always exits 0 — a formatter problem must never block the edit.
INPUT=$(cat)

[ "${AUTOFORMAT_ENABLED:-0}" = "1" ] || exit 0

python3 - "$INPUT" <<'PY'
import json, os, shutil, subprocess, sys

try:
    data = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)

if data.get("tool_name", "") not in ("Edit", "Write", "MultiEdit"):
    sys.exit(0)

path = (data.get("tool_input") or {}).get("file_path", "")
if not path or not os.path.isfile(path):
    sys.exit(0)

ext = os.path.splitext(path)[1].lower()
cwd = os.getcwd()

PRETTIER_EXTS = {
    ".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".json", ".jsonc",
    ".css", ".scss", ".less", ".html", ".vue", ".svelte",
    ".md", ".mdx", ".yaml", ".yml", ".graphql",
}
PRETTIER_CONFIGS = (
    ".prettierrc", ".prettierrc.json", ".prettierrc.yaml", ".prettierrc.yml",
    ".prettierrc.json5", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.mjs",
    ".prettierrc.toml", "prettier.config.js", "prettier.config.cjs",
    "prettier.config.mjs",
)


def first_available(*cmds):
    """Return the first command (list) whose binary is on PATH, else None."""
    for cmd in cmds:
        if shutil.which(cmd[0]):
            return cmd
    return None


def prettier_command():
    """Prefer a project-local prettier (strong signal the project uses it).
    Fall back to a global prettier only when a prettier config is present, so
    we don't impose prettier's style on projects that never opted into it."""
    local = os.path.join(cwd, "node_modules", ".bin", "prettier")
    if os.access(local, os.X_OK):
        return [local, "--write"]
    if shutil.which("prettier"):
        has_config = any(os.path.isfile(os.path.join(cwd, c)) for c in PRETTIER_CONFIGS)
        if not has_config and os.path.isfile(os.path.join(cwd, "package.json")):
            try:
                with open(os.path.join(cwd, "package.json")) as f:
                    has_config = "prettier" in json.load(f)
            except Exception:
                has_config = False
        if has_config:
            return ["prettier", "--write"]
    return None


# Resolve a formatter command for this file's language. Language-native tools
# (ruff/black, gofmt, rustfmt, shfmt) run on bare availability — they are the
# canonical formatter for their language with safe defaults.
if ext == ".py":
    cmd = first_available(["ruff", "format"], ["black"])
elif ext in PRETTIER_EXTS:
    cmd = prettier_command()
elif ext == ".go":
    cmd = first_available(["gofmt", "-w"])
elif ext == ".rs":
    cmd = first_available(["rustfmt"])
elif ext in (".sh", ".bash"):
    cmd = first_available(["shfmt", "-w"])
else:
    cmd = None

if not cmd:
    sys.exit(0)

try:
    subprocess.run(cmd + [path], cwd=cwd, capture_output=True, timeout=30)
except Exception:
    pass
sys.exit(0)
PY
exit 0
