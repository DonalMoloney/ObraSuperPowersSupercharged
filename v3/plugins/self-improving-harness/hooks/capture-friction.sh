#!/usr/bin/env bash
# Stop hook (self-improving-harness, v3 EXPERIMENTAL): when Claude finishes a turn,
# append a one-line friction/score note to the loop's audit trail so the next
# /harness-run round has a head start on what to diagnose. This is the lightweight
# "fast loop" capture from v3 IDEAS.md #5 — collection only, no gate, no judgement.
#
# FAIL-SOFT CONTRACT (non-negotiable): a capture hook must NEVER brick a session.
# It drains stdin, treats every file as possibly-missing, swallows every error, and
# exits 0 on EVERY path. A friction logger that blocks the session is worse than no
# logger — false friction is what gets hooks ripped out.
#
#   SIH_CAPTURE=off   disable entirely (still exits 0)

set -u

# --- 1. Always drain stdin (the hook payload) so we never hang the session. ------
PAYLOAD=""
PAYLOAD="$(cat 2>/dev/null || true)"

# --- 2. Honor the off switch. ---------------------------------------------------
if [ "${SIH_CAPTURE:-on}" = "off" ]; then
  exit 0
fi

# --- 3. Pick a sink, preferring the scoreboard's scratch log, then a tmp log. ----
# We never write into the SCOREBOARD.md table itself (that is /harness-run's job,
# tied to a real kept/reverted edit). We append to a sibling scratch log so the
# audit trail stays clean. Fall back to a temp file if the plugin dir is unwritable.
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
LOG=""

if [ -n "$PLUGIN_ROOT" ] && [ -d "$PLUGIN_ROOT" ] && [ -w "$PLUGIN_ROOT" ]; then
  LOG="$PLUGIN_ROOT/SCOREBOARD.scratch.log"
else
  LOG="${TMPDIR:-/tmp}/self-improving-harness-friction.log"
fi

# --- 4. Compose a one-line note. Timestamp is best-effort. ----------------------
TS="$(date '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo unknown-time)"

# Best-effort, optional context: a current suite score if a runner is reachable.
# We do NOT run the suite here (too expensive for a Stop hook) — we only note that
# a turn ended, so the next /harness-run knows there is fresh activity to mine.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
SUITE_NOTE="suite: not measured (run /harness-score)"
if [ -f "$PROJECT_DIR/run-evals.sh" ]; then
  SUITE_NOTE="suite present at $PROJECT_DIR/run-evals.sh — run /harness-score"
fi

NOTE="$TS  turn ended; $SUITE_NOTE  [self-improving-harness friction capture]"

# --- 5. Append, swallowing any write error. -------------------------------------
# `>>` creates the file if missing; the `|| true` guarantees we never fail on a
# read-only FS, a vanished dir, or a permissions surprise.
{
  printf '%s\n' "$NOTE" >> "$LOG"
} 2>/dev/null || true

# --- 6. Stay quiet on the happy path; never block. ------------------------------
exit 0
