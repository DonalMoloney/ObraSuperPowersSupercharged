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

echo "----"; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
