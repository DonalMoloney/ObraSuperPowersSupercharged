#!/bin/bash
# PostToolUse hook (Write|Edit): when the edited file is a SKILL.md, score it
# against this repo's structural + content rubric and surface failures.
#
#   SQG_MODE=warn   (default) print the report on a low score; never block
#   SQG_MODE=block  exit 2 on a low score (blocks the tool result, asks for a fix)
#   SQG_MODE=off    disable entirely
#   SQG_THRESHOLD=N override the pass threshold (default 80; read by score_skill.py)
#
# The gate only fires on files literally named SKILL.md, so ordinary edits are
# untouched. Conservative by default (warn) — false blocks are what get hooks
# uninstalled (see verification-gate's tuning note).
INPUT=$(cat)
MODE="${SQG_MODE:-warn}"
[ "$MODE" = "off" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCORER="$SCRIPT_DIR/../scripts/score_skill.py"

python3 - "$INPUT" "$MODE" "$SCORER" <<'PY'
import json, os, subprocess, sys

raw, mode, scorer = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)                       # unparseable payload: never false-block

ti = data.get("tool_input") or {}
path = ti.get("file_path") or ti.get("path") or ""
if os.path.basename(path) != "SKILL.md" or not os.path.isfile(path):
    sys.exit(0)                       # not a skill write: nothing to gate

try:
    proc = subprocess.run(
        [sys.executable, scorer, "--json", path],
        capture_output=True, text=True, timeout=20)
except Exception:
    sys.exit(0)                       # scorer unavailable: never false-block

try:
    report = json.loads(proc.stdout or "{}")
except Exception:
    sys.exit(0)

if report.get("passing", True):
    sys.exit(0)                       # ship-ready: stay quiet

score = report.get("score", "?")
thresh = report.get("threshold", 80)
fixes = report.get("fixes") or []
header = (f"skill-quality-gate: {path} scored {score}/100 "
          f"(threshold {thresh}) — not ship-ready (v1 writing-skills rubric).")
body = "\n".join(f"  - {fx}" for fx in fixes)
msg = header + ("\nFixes:\n" + body if body else "")
msg += ("\nDeeper review: v2 skill-quality-validator (structural) + "
        "skill-evaluator (content); behavioral proof: v2 skill-test-harness.")

if mode == "block":
    print(msg, file=sys.stderr)
    sys.exit(2)                       # block the tool result; request a fix
print(msg)                            # warn mode: visible note, no block
sys.exit(0)
PY
exit 0
