#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../scripts/pr_comments.sh"
FIX="$HERE/fixtures"
PASS=0; FAIL=0

assert_eq() { # desc expected actual
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "ok - $1";
  else FAIL=$((FAIL+1)); echo "NOT OK - $1"; printf '  expected: %s\n  actual:   %s\n' "$2" "$3"; fi
}

# Unknown subcommand exits non-zero and prints usage.
out="$(bash "$SCRIPT" bogus 2>&1)"; rc=$?
assert_eq "unknown subcommand exits non-zero" "nonzero" "$([ $rc -ne 0 ] && echo nonzero || echo zero)"
assert_eq "unknown subcommand prints usage" "yes" "$(echo "$out" | grep -q 'Usage:' && echo yes || echo no)"

# --- Task 2: human filter ---
authors() { jq -r '[.[].author] | sort | join(",")'; }
out="$(bash "$SCRIPT" filter --self me --handled "" < "$FIX/mixed.json" | authors)"
assert_eq "human filter keeps only real non-self humans" "alice,bob" "$out"

# --- Task 3: new (handled-id) filter ---
out="$(bash "$SCRIPT" filter --self me --handled "7" < "$FIX/mixed.json" | authors)"
assert_eq "handled filter drops id 7 (bob)" "alice" "$out"

# --- Task 4: normalization shape ---
norm="$(bash "$SCRIPT" filter --self me --handled "" < "$FIX/mixed.json")"
bob="$(printf '%s' "$norm" | jq -r '.[] | select(.author=="bob") | "\(.type)|\(.path)|\(.line)|\(.url)|\(.diff_hunk)"')"
assert_eq "inline comment normalized with code fields" "inline|a.py|10|u7|@@ -1 +1 @@" "$bob"
alice="$(printf '%s' "$norm" | jq -r '.[] | select(.author=="alice") | "\(.type)|\(.path)|\(.line)"')"
assert_eq "conversation comment has null code fields" "conversation|null|null" "$alice"
keys="$(printf '%s' "$norm" | jq -r '.[0] | keys_unsorted | join(",")')"
assert_eq "normalized keys exact" "id,type,author,created_at,body,url,path,line,diff_hunk,in_reply_to_id" "$keys"

echo "----"; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
