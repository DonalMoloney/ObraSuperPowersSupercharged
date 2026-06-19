#!/usr/bin/env bash
# bundle-review-context.sh — assemble a code-review evidence bundle and classify
# change risk so review depth can scale with it (Option A via Option C, CC3+CC5).
#
# Usage:
#   bash bundle-review-context.sh [--base SHA] [--head SHA] [--tests "CMD"] [--plan FILE] [--out FILE]
#
#   --base SHA    starting commit (default: merge-base with origin/main, else origin/master, else HEAD~1)
#   --head SHA    ending commit (default: HEAD)
#   --tests CMD   test command to run; exit code + output tail are captured as evidence
#   --plan FILE   plan/requirements file to excerpt into the bundle
#   --out FILE    also write the bundle to FILE (always printed to stdout)
#
# Heuristics and caps are env-overridable so classification can be tuned per
# project without editing the script (Option A trade-off: heuristics need tuning).

set -euo pipefail

# --- Tunable risk heuristics -------------------------------------------------
LOW_MAX_LINES="${REVIEW_LOW_MAX_LINES:-100}"
LOW_MAX_FILES="${REVIEW_LOW_MAX_FILES:-4}"
HIGH_MIN_LINES="${REVIEW_HIGH_MIN_LINES:-500}"
HIGH_MIN_FILES="${REVIEW_HIGH_MIN_FILES:-12}"
# Blast-radius paths: touching any of these forces HIGH regardless of size.
RISKY_PATH_PATTERN="${REVIEW_RISKY_PATH_PATTERN:-(migrat|schema|auth|security|crypto|payment|billing|secret|\.github/workflows|Dockerfile|deploy|terraform|helm|k8s)}"

# --- Size caps (Option C trade-off: the bundler must not over-include) -------
DIFFSTAT_CAP="${REVIEW_DIFFSTAT_CAP:-80}"     # max lines of diff stat
TEST_TAIL_CAP="${REVIEW_TEST_TAIL_CAP:-40}"   # last N lines of test output
PLAN_HEAD_CAP="${REVIEW_PLAN_HEAD_CAP:-120}"  # first N lines of plan file

BASE="" HEAD="" TESTS_CMD="" PLAN_FILE="" OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)  BASE="$2";      shift 2 ;;
    --head)  HEAD="$2";      shift 2 ;;
    --tests) TESTS_CMD="$2"; shift 2 ;;
    --plan)  PLAN_FILE="$2"; shift 2 ;;
    --out)   OUT="$2";       shift 2 ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "error: unknown argument: $1 (try --help)" >&2; exit 2 ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || {
  echo "error: not inside a git repository — set SHAs by hand per SKILL.md fallback" >&2
  exit 1
}

HEAD="${HEAD:-$(git rev-parse HEAD)}"
if [[ -z "$BASE" ]]; then
  if git rev-parse --verify -q origin/main >/dev/null 2>&1; then
    BASE=$(git merge-base origin/main "$HEAD")
  elif git rev-parse --verify -q origin/master >/dev/null 2>&1; then
    BASE=$(git merge-base origin/master "$HEAD")
  elif git rev-parse --verify -q "$HEAD~1" >/dev/null 2>&1; then
    BASE=$(git rev-parse "$HEAD~1")
  else
    echo "error: cannot derive a base commit — pass --base explicitly" >&2
    exit 1
  fi
fi

# Lockfiles are churn, not risk: exclude them from size signals.
EXCLUDES=(
  ':(exclude)*package-lock.json' ':(exclude)*yarn.lock' ':(exclude)*pnpm-lock.yaml'
  ':(exclude)*Cargo.lock' ':(exclude)*poetry.lock' ':(exclude)*go.sum' ':(exclude)*Gemfile.lock'
)

FILES_CHANGED=$(git diff --name-only "$BASE".."$HEAD" -- . "${EXCLUDES[@]}" | wc -l | tr -d ' ')
LINES_CHANGED=$(git diff --numstat "$BASE".."$HEAD" -- . "${EXCLUDES[@]}" \
  | awk '$1 != "-" && $2 != "-" {sum += $1 + $2} END {print sum + 0}')
RISKY_HITS=$(git diff --name-only "$BASE".."$HEAD" | grep -E -i "$RISKY_PATH_PATTERN" || true)

# --- Classify ----------------------------------------------------------------
RISK="MEDIUM"
DEPTH="one reviewer, full code-reviewer.md template"
if [[ -n "$RISKY_HITS" || "$LINES_CHANGED" -ge "$HIGH_MIN_LINES" || "$FILES_CHANGED" -ge "$HIGH_MIN_FILES" ]]; then
  RISK="HIGH"
  DEPTH="three parallel reviewers: spec-compliance + code-quality + silent-failure"
elif [[ "$LINES_CHANGED" -le "$LOW_MAX_LINES" && "$FILES_CHANGED" -le "$LOW_MAX_FILES" ]]; then
  RISK="LOW"
  DEPTH="one reviewer, quick pass (plan alignment + obvious bugs only)"
fi

# --- Run tests if asked ------------------------------------------------------
TEST_EXIT=""
TEST_LOG=""
if [[ -n "$TESTS_CMD" ]]; then
  TEST_LOG=$(mktemp)
  trap 'rm -f "$TEST_LOG"' EXIT
  if bash -c "$TESTS_CMD" >"$TEST_LOG" 2>&1; then
    TEST_EXIT=0
  else
    TEST_EXIT=$?
  fi
fi

# --- Emit fixed-format evidence bundle (CC5) ---------------------------------
emit() {
  echo "## Review Evidence Bundle"
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Base: $BASE ($(git log -1 --format=%s "$BASE"))"
  echo "Head: $HEAD ($(git log -1 --format=%s "$HEAD"))"
  echo
  echo "### Risk classification"
  echo "Risk: $RISK"
  echo "Signals: ${FILES_CHANGED} files, ${LINES_CHANGED} lines changed (lockfiles excluded)"
  if [[ -n "$RISKY_HITS" ]]; then
    echo "Risky paths:"
    printf '%s\n' "$RISKY_HITS" | sed 's/^/  - /'
  else
    echo "Risky paths: none"
  fi
  echo "Recommended depth: $DEPTH"
  echo
  echo "### Diff stat (capped at $DIFFSTAT_CAP lines)"
  echo '```'
  git diff --stat "$BASE".."$HEAD" | head -n "$DIFFSTAT_CAP"
  echo '```'
  if [[ -n "$TESTS_CMD" ]]; then
    echo
    echo "### Test evidence"
    echo "Command: $TESTS_CMD"
    echo "Exit code: $TEST_EXIT"
    echo "Output (last $TEST_TAIL_CAP lines):"
    echo '```'
    tail -n "$TEST_TAIL_CAP" "$TEST_LOG"
    echo '```'
  fi
  if [[ -n "$PLAN_FILE" ]]; then
    echo
    if [[ -r "$PLAN_FILE" ]]; then
      echo "### Plan / requirements (first $PLAN_HEAD_CAP lines of $PLAN_FILE)"
      echo '```'
      head -n "$PLAN_HEAD_CAP" "$PLAN_FILE"
      echo '```'
    else
      echo "### Plan / requirements"
      echo "WARNING: plan file not readable: $PLAN_FILE"
    fi
  fi
}

if [[ -n "$OUT" ]]; then
  emit | tee "$OUT"
else
  emit
fi
