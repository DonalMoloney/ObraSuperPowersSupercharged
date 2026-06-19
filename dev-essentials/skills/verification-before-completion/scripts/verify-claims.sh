#!/usr/bin/env bash
# verify-claims.sh — run the project's verification manifest, emit evidence blocks.
# Part of the verification-before-completion skill (Option A — Verification manifest).
#
# Manifest format (verify.yaml): flat "claim-type: command" pairs, one per line.
#   tests-pass: pytest -q
#   build-succeeds: npm run build
# Blank lines and lines starting with # are ignored. No nesting, no quoting.
#
# Usage:
#   verify-claims.sh [--manifest PATH] [claim-type ...]
#       Run every manifest entry (or only the named claim types) FRESH and print
#       one timestamped evidence block per claim. Exit 0 only if all pass.
#   verify-claims.sh --init [--manifest PATH]
#       Scaffold a commented starter manifest (refuses to overwrite).
#
# Paste the printed evidence blocks into your completion message: the claim and
# the evidence that proves it travel together.

set -u

MANIFEST="verify.yaml"
INIT=0
REQUESTED=""

while [ $# -gt 0 ]; do
  case "$1" in
    --manifest)
      [ $# -ge 2 ] || { echo "ERROR: --manifest requires a path" >&2; exit 2; }
      MANIFEST="$2"; shift 2 ;;
    --init) INIT=1; shift ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --*) echo "ERROR: unknown flag $1 (see --help)" >&2; exit 2 ;;
    *) REQUESTED="$REQUESTED $1"; shift ;;
  esac
done

if [ "$INIT" -eq 1 ]; then
  if [ -e "$MANIFEST" ]; then
    echo "ERROR: refusing to overwrite existing $MANIFEST" >&2
    exit 1
  fi
  cat > "$MANIFEST" <<'EOF'
# verify.yaml — claim types this project can prove, and the command proving each.
# Format: flat "claim-type: command" pairs, one per line. No nesting.
# Lines starting with # are ignored. Uncomment/edit entries with REAL commands,
# then run verify-claims.sh to execute them and emit evidence blocks.
#
# tests-pass: pytest -q
# build-succeeds: npm run build
# lint-clean: ruff check .
# types-check: npx tsc --noEmit
EOF
  echo "Wrote starter manifest to $MANIFEST."
  echo "Edit it with this project's real commands, then re-run verify-claims.sh."
  exit 0
fi

if [ ! -f "$MANIFEST" ]; then
  echo "ERROR: no manifest at $MANIFEST." >&2
  echo "Run '$0 --init' to scaffold one, or pass --manifest PATH." >&2
  exit 2
fi

LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/verify-claims.XXXXXX")" || exit 2

total=0
failed=0
missing=0
FOUND=""

wanted() {
  [ -z "$REQUESTED" ] && return 0
  case " $REQUESTED " in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

run_entry() {
  claim="$1"
  cmd="$2"
  total=$((total + 1))
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  log="$LOG_DIR/$claim.log"
  bash -c "$cmd" </dev/null >"$log" 2>&1
  rc=$?
  echo "### Evidence: $claim"
  echo "- command: $cmd"
  echo "- exit code: $rc"
  echo "- timestamp (UTC): $ts"
  echo "- output (last 10 lines; full log: $log):"
  tail -n 10 "$log" | sed 's/^/    /'
  echo
  if [ "$rc" -ne 0 ]; then
    failed=$((failed + 1))
  fi
}

while IFS= read -r line || [ -n "$line" ]; do
  # strip leading whitespace, skip blanks and comments
  trimmed="$(printf '%s' "$line" | sed 's/^[[:space:]]*//')"
  case "$trimmed" in
    ''|\#*) continue ;;
  esac
  case "$trimmed" in
    *:*) ;;
    *) echo "WARNING: skipping malformed line (no colon): $line" >&2; continue ;;
  esac
  claim="$(printf '%s' "${trimmed%%:*}" | sed 's/[[:space:]]*$//')"
  cmd="$(printf '%s' "${trimmed#*:}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [ -z "$claim" ] || [ -z "$cmd" ]; then
    echo "WARNING: skipping malformed line: $line" >&2
    continue
  fi
  wanted "$claim" || continue
  FOUND="$FOUND $claim"
  run_entry "$claim" "$cmd"
done < "$MANIFEST"

if [ -n "$REQUESTED" ]; then
  for r in $REQUESTED; do
    case " $FOUND " in
      *" $r "*) ;;
      *)
        echo "ERROR: claim type '$r' has no entry in $MANIFEST — no manifest entry, no pass." >&2
        missing=$((missing + 1)) ;;
    esac
  done
fi

if [ "$total" -eq 0 ] && [ "$missing" -eq 0 ]; then
  echo "ERROR: no runnable entries in $MANIFEST (all commented out?). Edit it, then re-run." >&2
  exit 2
fi

passed=$((total - failed))
echo "== Verification summary: $passed/$total claims verified, $failed failed, $missing missing =="

if [ "$failed" -eq 0 ] && [ "$missing" -eq 0 ]; then
  exit 0
fi
exit 1
