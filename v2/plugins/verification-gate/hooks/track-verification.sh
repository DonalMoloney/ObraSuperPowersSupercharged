#!/bin/bash
# PostToolUse hook: timestamp edits and verification commands so the Stop
# gate can enforce "verification ran AFTER the last edit".
INPUT=$(cat)
python3 - "$INPUT" <<'PY'
import json, os, re, sys, time

data = json.loads(sys.argv[1])
session = data.get("session_id") or "default"
state = os.path.join(os.environ.get("TMPDIR", "/tmp"), "verification-gate", session)
os.makedirs(state, exist_ok=True)
now = repr(time.time())
tool = data.get("tool_name", "")

if tool in ("Edit", "Write"):
    with open(os.path.join(state, "last_edit"), "w") as f:
        f.write(now)
elif tool == "Bash":
    cmd = (data.get("tool_input") or {}).get("command", "")
    default = (r"pytest|npm (run )?test|yarn test|pnpm test|go test|cargo test"
               r"|make test|tox\b|rspec|phpunit|gradle test|mvn test|jest|vitest")
    if re.search(os.environ.get("VGATE_VERIFY_COMMANDS", default), cmd):
        with open(os.path.join(state, "last_verify"), "w") as f:
            f.write(now)
PY
exit 0
