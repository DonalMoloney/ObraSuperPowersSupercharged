#!/usr/bin/env bash
# Lifecycle test: locks budget caps, STOP file, plateau, and summary behavior.
set -uo pipefail
HARNESS="$(cd "$(dirname "$0")/.." && pwd)/scripts/autoresearch.sh"
fails=0
assert() { if eval "$2"; then echo "ok - $1"; else echo "NOT ok - $1"; fails=$((fails+1)); fi; }

# BIN lives outside every repo so scratch files never dirty any git tree.
BIN="$(mktemp -d)"
trap 'rm -rf "$BIN"' EXIT

mkrepo() {
  TMP="$(mktemp -d)"
  cd "$TMP" || exit 1
  git init -q && git config user.email t@t && git config user.name t
  echo "value = 0" > knob.txt
  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\nv=$(grep -oE "[0-9]+" knob.txt | head -1); echo "score=${v:-0}"\n' > eval.sh
  chmod +x eval.sh
  git add -A && git commit -qm init
}

# Proposer that never improves: writes the same value that is already there.
# Lives in BIN (outside the repo) so no untracked files pollute the git tree.
neverimprove() {
  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\ncd "$AR_WORKTREE" || exit 1\necho "value = 0" > knob.txt\n' > "$BIN/mock.sh"
  chmod +x "$BIN/mock.sh"
}

# ── (a) max_iterations cap ──────────────────────────────────────────────────
# Budget: 2 iterations max.  The proposer writes "value = 0" — same as the
# baseline — so the worktree stays clean (no git-detectable change) and each
# iteration is recorded as "no change".  The harness must stop after exactly 2.
mkrepo
REPO_A="$TMP"
cat > autoresearch.config.json <<'EOF'
{ "objective":"x","artifact":["knob.txt"],"eval_cmd":"bash eval.sh",
  "metric":{"type":"regex","pattern":"score=([0-9]+)"},"direction":"maximize",
  "budget":{"max_iterations":2,"max_wallclock_min":60,"per_iter_timeout_sec":30} }
EOF
# gitignore autoresearch dir so writing config doesn't dirty the tree further;
# the harness appends .autoresearch/ to .gitignore itself, but the config
# must be committed (or the tree is already dirty when we check git status).
git add autoresearch.config.json && git commit -qm "add config"
neverimprove
AUTORESEARCH_PROPOSER_CMD="$BIN/mock.sh" bash "$HARNESS" >"$BIN/out_a.log" 2>&1
j_a="$(find "$REPO_A/.autoresearch" -name 'journal.md' | head -1)"
assert "stops at max_iterations=2" "[ \"\$(grep -c '## iter' '$j_a')\" -eq 2 ]"

# ── (b) plateau early-stop + summary ────────────────────────────────────────
# Budget: 50 iterations, but stop_after_no_improve=3.
# The proposer never improves, so after 3 consecutive no-improve the harness
# must halt, print a "plateau" message, and write "## summary" to the journal.
# out.log lives in BIN so it never creates an untracked file inside the repo.
mkrepo
REPO_B="$TMP"
cat > autoresearch.config.json <<'EOF'
{ "objective":"x","artifact":["knob.txt"],"eval_cmd":"bash eval.sh",
  "metric":{"type":"regex","pattern":"score=([0-9]+)"},"direction":"maximize",
  "budget":{"max_iterations":50,"max_wallclock_min":60,"per_iter_timeout_sec":30},
  "stop_after_no_improve":3 }
EOF
git add autoresearch.config.json && git commit -qm "add config"
neverimprove
AUTORESEARCH_PROPOSER_CMD="$BIN/mock.sh" bash "$HARNESS" >"$BIN/out_b.log" 2>&1
j_b="$(find "$REPO_B/.autoresearch" -name 'journal.md' | head -1)"
assert "plateau stops after 3 no-improve" "[ \"\$(grep -c '## iter' '$j_b')\" -eq 3 ]"
assert "plateau message printed" "grep -q 'plateau' '$BIN/out_b.log'"
assert "summary written" "grep -q '## summary' '$j_b'"

echo "---"
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; else echo "$fails FAILED"; exit 1; fi
