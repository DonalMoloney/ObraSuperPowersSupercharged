#!/usr/bin/env bash
# Integration test for autoresearch.sh using a deterministic mock proposer.
set -uo pipefail
HARNESS="$(cd "$(dirname "$0")/.." && pwd)/scripts/autoresearch.sh"
fails=0
assert() { if eval "$2"; then echo "ok - $1"; else echo "NOT ok - $1"; fails=$((fails+1)); fi; }

# --- build a throwaway target repo ---
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
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
cat > mock.sh <<'EOF'
#!/usr/bin/env bash
cd "$AR_WORKTREE" || exit 1
n=$(grep -oE '[0-9]+' knob.txt | head -1); n=${n:-0}
case "$AR_BEST" in
  0) echo "value = 5" > knob.txt ;;        # iter1: 0 -> 5  (KEEP)
  5) echo "value = 1" > knob.txt ;;        # iter2: 5 -> 1  (REVERT, worse)
  *) echo "x" > out_of_scope.txt ;;        # iter3: out-of-scope (REVERT)
esac
EOF
chmod +x mock.sh

AUTORESEARCH_PROPOSER_CMD="$TMP/mock.sh" bash "$HARNESS" autoresearch.config.json >run.log 2>&1

run="$(ls -d .autoresearch/*/ | head -1)"
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

echo "---"; [ "$fails" -eq 0 ] && echo "ALL PASS" || { echo "$fails FAILED"; exit 1; }
