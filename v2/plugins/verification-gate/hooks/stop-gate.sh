#!/bin/bash
# Stop hook: when the last assistant message makes a success claim but no
# verification command has run since the last edit, warn (default) or block.
# VGATE_MODE=warn|block|off   VGATE_CLAIM_PATTERNS / VGATE_VERIFY_COMMANDS: regex overrides.
INPUT=$(cat)
MODE="${VGATE_MODE:-warn}"
[ "$MODE" = "off" ] && exit 0
python3 - "$INPUT" "$MODE" <<'PY'
import json, os, re, sys

data = json.loads(sys.argv[1])
mode = sys.argv[2]
if data.get("stop_hook_active"):
    sys.exit(0)                       # already continuing from a stop block: never loop
session = data.get("session_id") or "default"
state = os.path.join(os.environ.get("TMPDIR", "/tmp"), "verification-gate", session)

def ts(name):
    try:
        with open(os.path.join(state, name)) as f:
            return float(f.read().strip())
    except Exception:
        return None

last_edit, last_verify = ts("last_edit"), ts("last_verify")
if last_edit is None:
    sys.exit(0)                       # nothing edited this session: nothing to gate
if last_verify is not None and last_verify > last_edit:
    sys.exit(0)                       # verified after the last edit: claim is backed

# Fire only on an actual success claim in the LAST assistant message —
# conservative patterns; false positives are the killer risk.
default = (r"\b(all tests pass(ing)?|tests? (now )?pass(ing)?|works now"
           r"|(is|are) fixed|fixed the \w+|implementation (is )?complete"
           r"|task (is )?(done|complete[d]?))\b")
claim = re.compile(os.environ.get("VGATE_CLAIM_PATTERNS", default), re.I)

text = ""
try:
    with open(data.get("transcript_path", "")) as f:
        for line in f:
            try:
                entry = json.loads(line)
            except Exception:
                continue
            if entry.get("type") == "assistant":
                content = (entry.get("message") or {}).get("content") or []
                parts = [c.get("text", "") for c in content
                         if isinstance(c, dict) and c.get("type") == "text"]
                if parts:
                    text = "\n".join(parts)
except Exception:
    sys.exit(0)                       # unreadable transcript: never false-block

if not claim.search(text):
    sys.exit(0)

msg = ("verification-gate: success claim without verification — no verify command "
       "has run since the last edit. Run the test/build command and show its output "
       "first (v1 verification-before-completion).")
if mode == "block":
    print(msg, file=sys.stderr)
    sys.exit(2)
print(msg)                            # warn mode: visible note, no block
sys.exit(0)
PY
