#!/usr/bin/env bash
# Default proposer: build the prompt and run a fresh headless `claude -p` in the worktree.
# Overridable in tests via AUTORESEARCH_PROPOSER_CMD.
set -uo pipefail
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v claude >/dev/null 2>&1 || { echo "proposer: 'claude' CLI not found" >&2; exit 127; }

prompt="$(node "$LIB/prompt.mjs")"

cd "$AR_WORKTREE" || exit 1
# Edits only; never let the proposer run bash or commit.
printf '%s' "$prompt" | claude -p --permission-mode acceptEdits
