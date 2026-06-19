#!/usr/bin/env bash
# Stop hook: when Claude finishes a turn, re-run the project's test/verify command
# and surface the result. This is regression-guard's mechanical verifier — it fires
# regardless of model memory (Cherny's hooks-as-enforcement), so "it's green now"
# can never be a forgotten claim.
#
#   RG_MODE=warn   (default) print a note if the suite is red; never block
#   RG_MODE=block  exit 2 if the suite is red (blocks; asks for a fix)
#   RG_MODE=off    disable entirely
#   RG_TEST_CMD=…  override autodetection with an explicit command
#
# FAIL-SOFT CONTRACT: this hook must never brick a session. Any unexpected
# condition — no git repo, no detectable test command, a tool that isn't
# installed, an unparseable payload — results in a note (or silence) and exit 0.
# False blocks are what get hooks uninstalled.

set -u

# Drain stdin (the hook payload); we don't need it, but read it so we never hang.
cat >/dev/null 2>&1 || true

MODE="${RG_MODE:-warn}"
[ "$MODE" = "off" ] && exit 0

# --- Locate the project root ---------------------------------------------------
# Prefer the directory the session is working in; fall back to the git toplevel.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$PROJECT_DIR" 2>/dev/null || exit 0   # can't enter it: nothing to verify

# --- Decide the test command ---------------------------------------------------
# Explicit override always wins.
TEST_CMD="${RG_TEST_CMD:-}"

have() { command -v "$1" >/dev/null 2>&1; }

if [ -z "$TEST_CMD" ]; then
  # 1) npm test — only if package.json declares a "test" script.
  if [ -f package.json ] && have npm; then
    if grep -Eq '"test"[[:space:]]*:' package.json; then
      TEST_CMD="npm test --silent"
    fi
  fi

  # 2) pytest — if available and the repo looks like it has Python tests.
  if [ -z "$TEST_CMD" ] && have pytest; then
    if ls tests 2>/dev/null | grep -q . \
       || ls -- *test*.py 2>/dev/null | grep -q . \
       || ls -- test_*.py 2>/dev/null | grep -q .; then
      TEST_CMD="pytest -q"
    fi
  fi

  # 3) make test — if a Makefile declares a "test" target.
  if [ -z "$TEST_CMD" ] && [ -f Makefile ] && have make; then
    if grep -Eq '^test[[:space:]]*:' Makefile; then
      TEST_CMD="make test"
    fi
  fi
fi

# No detectable command: note it and bow out cleanly. Never block on absence.
if [ -z "$TEST_CMD" ]; then
  echo "regression-guard: no test command detected (looked for npm test / pytest / make test). Set RG_TEST_CMD to enable the verifier."
  exit 0
fi

# --- Run it --------------------------------------------------------------------
OUTPUT="$( eval "$TEST_CMD" 2>&1 )"
STATUS=$?

if [ "$STATUS" -eq 0 ]; then
  # Green: stay quiet so the hook is invisible on the happy path.
  exit 0
fi

# Red: surface the tail of the output with a clear pointer to the workflow.
TAIL="$( printf '%s\n' "$OUTPUT" | tail -n 20 )"
MSG="regression-guard: verifier RED — \`$TEST_CMD\` exited $STATUS.
Last lines:
$TAIL
If this is a regression, run the workflow: v2 flaky-test-quarantine (rule out flake) → bisect-the-regression (localize the commit) → fix via v1 systematic-debugging."

if [ "$MODE" = "block" ]; then
  printf '%s\n' "$MSG" >&2
  exit 2          # block the stop; ask for a green suite
fi

printf '%s\n' "$MSG"   # warn mode: visible note, never blocks
exit 0
