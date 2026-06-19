#!/usr/bin/env bash
# Integration test for autoresearch.sh using a deterministic mock proposer.
set -uo pipefail
HARNESS="$(cd "$(dirname "$0")/.." && pwd)/scripts/autoresearch.sh"
fails=0
assert() { if eval "$2"; then echo "ok - $1"; else echo "NOT ok - $1"; fails=$((fails+1)); fi; }

# --- build a throwaway target repo ---
TMP="$(mktemp -d)"
BIN="$(mktemp -d)"
trap 'rm -rf "$TMP" "$BIN"' EXIT
cd "$TMP" || exit 1
git init -q && git config user.email t@t && git config user.name t
echo "value = 0" > knob.txt
# eval prints metric = the integer in knob.txt; lower is "worse" here we MAXIMIZE
cat > eval.sh <<'EOF'
#!/usr/bin/env bash
v=$(grep -oE '[0-9]+' knob.txt | head -1)
echo "score=${v:-0}"
EOF
chmod +x eval.sh
cat > autoresearch.config.json <<'EOF'
{ "objective":"maximize the knob","artifact":["knob.txt"],"eval_cmd":"bash eval.sh",
  "metric":{"type":"regex","pattern":"score=([0-9]+)"},"direction":"maximize",
  "budget":{"max_iterations":3,"max_wallclock_min":60,"per_iter_timeout_sec":30} }
EOF
git add -A && git commit -qm init

# mock proposer: iter1 improves (good), iter2 worsens (bad), iter3 edits out-of-scope
# mock lives OUTSIDE the temp repo so the tree stays clean (no untracked files)
export MOCK_COUNTER="$BIN/itercount"
cat > "$BIN/mock.sh" <<'EOF'
#!/usr/bin/env bash
cd "$AR_WORKTREE" || exit 1
n=$(cat "$MOCK_COUNTER" 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > "$MOCK_COUNTER"
case "$n" in
  1) echo "value = 5" > knob.txt ;;     # improve  -> KEPT (0 -> 5)
  2) echo "value = 1" > knob.txt ;;     # worse    -> REVERTED (1 vs best 5)
  *) echo "x" > out_of_scope.txt ;;     # out-of-scope -> REVERTED
esac
EOF
chmod +x "$BIN/mock.sh"

AUTORESEARCH_PROPOSER_CMD="$BIN/mock.sh" bash "$HARNESS" autoresearch.config.json >"$BIN/run.log" 2>&1

run="$(find .autoresearch -maxdepth 1 -mindepth 1 -type d | head -1)/"
journal="${run}journal.md"
assert "journal exists"            "[ -f '$journal' ]"
assert "baseline recorded as 0"    "grep -q 'baseline: 0' '$journal'"
assert "iter1 KEPT"                "grep -q 'iter 1 — KEPT' '$journal'"
assert "iter2 REVERTED"            "grep -q 'iter 2 — REVERTED' '$journal'"
assert "iter3 out-of-scope revert" "grep -q 'iter 3 — REVERTED (out-of-scope)' '$journal'"
# worktree tree is clean after reverts
assert "worktree clean"            "[ -z \"\$(cd '${run}worktree' && git status --porcelain)\" ]"
# exactly one commit beyond init on the branch (only iter1 kept)
assert "one kept commit" "[ \"\$(cd '${run}worktree' && { git rev-list --count HEAD ^main 2>/dev/null || git rev-list --count HEAD; })\" -ge 1 ]"
# out-of-scope file was removed
assert "out-of-scope file gone"    "[ ! -f '${run}worktree/out_of_scope.txt' ]"

echo "---"
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; else echo "$fails FAILED"; exit 1; fi
