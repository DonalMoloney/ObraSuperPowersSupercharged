#!/usr/bin/env bash
#
# autonomy-control :: enforce-autonomy.sh (PreToolUse, matcher Edit|Write|MultiEdit)
#
# Enforces the currently-declared autonomy level at tool-call time. This is the
# net-new value of the autonomy-control plugin: autonomy-slider declares the level
# and permission-tiers maps it into settings.json, but a PreToolUse hook is what
# makes the level *binding* — it fires mechanically on every file-mutating tool
# call regardless of what the model remembers (Cherny's hooks-as-enforcement).
#
# Contract (deliberately fail-soft and opt-in — false blocks get hooks uninstalled):
#   - Declared level comes from env CLAUDE_AUTONOMY, else from a repo file
#     .claude/autonomy-level (first non-blank line), else unset.
#   - unset / empty            -> allow (exit 0). Opt-in by default.
#   - L0  (suggest-only)       -> BLOCK writes (exit 2) with a clear message.
#   - L1  (single-file diffs)  -> WARN, then allow (exit 0).
#   - L2 / L3 / anything else  -> allow (exit 0).
# Every path exits 0 except the deliberate L0 block (exit 2). The session is never
# bricked.

# Drain stdin so the hook never hangs waiting on the tool-call payload.
cat >/dev/null 2>&1 || true

# --- resolve the declared level -------------------------------------------------
level="${CLAUDE_AUTONOMY:-}"

if [ -z "$level" ]; then
  # Look for a repo-local declaration. Prefer the dir Claude is running in.
  level_file=""
  if [ -f ".claude/autonomy-level" ]; then
    level_file=".claude/autonomy-level"
  elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "${CLAUDE_PROJECT_DIR}/.claude/autonomy-level" ]; then
    level_file="${CLAUDE_PROJECT_DIR}/.claude/autonomy-level"
  fi
  if [ -n "$level_file" ]; then
    # First non-blank line, trimmed of surrounding whitespace.
    level="$(grep -m1 -v '^[[:space:]]*$' "$level_file" 2>/dev/null \
      | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  fi
fi

# Unset / empty -> opt-in default: allow.
if [ -z "$level" ]; then
  exit 0
fi

# Normalize to uppercase so "l0" and "L0" both work.
level_uc="$(printf '%s' "$level" | tr '[:lower:]' '[:upper:]')"

# --- enforce --------------------------------------------------------------------
case "$level_uc" in
  L0)
    # Suggest-only: file writes are not permitted at this level.
    echo "autonomy-control: BLOCKED — declared autonomy level is L0 (suggest-only)." >&2
    echo "  At L0, propose the change as a diff/code block in the conversation; do not write to disk." >&2
    echo "  The human applies (or rejects) each suggestion before anything touches a file." >&2
    echo "  To proceed, raise the level (CLAUDE_AUTONOMY=L1|L2|L3 or edit .claude/autonomy-level)." >&2
    exit 2
    ;;
  L1)
    # Single-file diffs: allow, but remind to present each diff and stop.
    echo "autonomy-control: note — autonomy level L1 (single-file diffs)." >&2
    echo "  Edit one file, present its diff, and stop for review before the next edit." >&2
    exit 0
    ;;
  L2 | L3)
    # Checkpointed multi-file / full task: allow.
    exit 0
    ;;
  *)
    # Unrecognized level: fail-soft, never block on something we don't understand.
    echo "autonomy-control: note — unrecognized autonomy level '${level}'; allowing the call." >&2
    exit 0
    ;;
esac
