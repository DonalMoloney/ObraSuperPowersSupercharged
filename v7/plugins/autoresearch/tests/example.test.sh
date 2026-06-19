#!/usr/bin/env bash
# Proves the loop drives the hillclimb metric down using a deterministic mock that
# nudges VALUE toward the target. (No LLM; proves the engine + example wiring.)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HARNESS="$ROOT/scripts/autoresearch.sh"

command -v python3 >/dev/null 2>&1 || { echo "skip - python3 not installed"; exit 0; }

fails=0
assert() { if eval "$2"; then echo "ok - $1"; else echo "NOT ok - $1"; fails=$((fails+1)); fi; }

# TMP = clean throwaway repo; BIN = external scratch for mock + logs (never enters TMP)
TMP="$(mktemp -d)"
BIN="$(mktemp -d)"
trap 'rm -rf "$TMP" "$BIN"' EXIT

# Copy hillclimb example files into TMP and make a clean initial commit
cp "$ROOT/examples/hillclimb/knob.py" "$TMP/"
cp "$ROOT/examples/hillclimb/eval.sh" "$TMP/"
cp "$ROOT/examples/hillclimb/autoresearch.config.json" "$TMP/"
cd "$TMP" || exit 1
git init -q
git config user.email t@t
git config user.name t
git add knob.py eval.sh autoresearch.config.json
git commit -qm init

# Mock proposer: move VALUE halfway toward 0.7 each call (monotonic improvement).
# Lives in BIN — never touches TMP directly as an untracked file.
cat > "$BIN/mock.sh" <<'EOF'
#!/usr/bin/env bash
cd "$AR_WORKTREE" || exit 1
cur="$(python3 -c 'import knob; print(knob.VALUE)')"
next="$(python3 -c "print(${cur} + (0.7 - ${cur})/2)")"
printf 'VALUE = %s\n' "$next" > knob.py
EOF
chmod +x "$BIN/mock.sh"

AUTORESEARCH_PROPOSER_CMD="$BIN/mock.sh" \
  bash "$HARNESS" autoresearch.config.json >"$BIN/run.log" 2>&1

j="$(find .autoresearch -maxdepth 2 -name 'journal.md' | head -1)"
assert "journal exists" "[ -f '$j' ]"
assert "at least one KEPT" "grep -q 'KEPT' '$j'"

# Extract best from the summary line: "baseline: <b> -> best: <x> | iterations: <n>"
best="$(grep -oE 'best: [0-9]+\.[0-9]+' "$j" | tail -1 | grep -oE '[0-9]+\.[0-9]+')"
# Baseline VALUE=0 -> metric=0.7; assert best strictly improved below that
assert "best metric < baseline 0.7" \
  "python3 -c \"import sys; sys.exit(0 if float('${best:-1}') < 0.7 else 1)\""

echo "---"
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; else echo "$fails FAILED"; exit 1; fi
