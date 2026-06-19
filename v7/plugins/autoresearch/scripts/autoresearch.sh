#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$SCRIPT_DIR/lib"

ALLOW_DIRTY=0
CONFIG="autoresearch.config.json"
for a in "$@"; do
  case "$a" in
    --allow-dirty) ALLOW_DIRTY=1 ;;
    *) CONFIG="$a" ;;
  esac
done

die() { echo "autoresearch: $1" >&2; exit 1; }

run_timeout() {  # run_timeout SECS CMD...
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@"; return $?; fi
  if command -v gtimeout >/dev/null 2>&1; then gtimeout "$secs" "$@"; return $?; fi
  perl -e 'my $s=shift; $SIG{ALRM}=sub{exit 124}; alarm $s; exec @ARGV or exit 127;' "$secs" "$@"
}

command -v git >/dev/null 2>&1 || die "git not found"
command -v node >/dev/null 2>&1 || die "node not found"
repo="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not a git repo"
[ -f "$CONFIG" ] || die "config not found: $CONFIG"

if [ "$ALLOW_DIRTY" -eq 0 ] && [ -n "$(git status --porcelain)" ]; then
  die "working tree is dirty; commit/stash or pass --allow-dirty"
fi

node "$LIB/config.mjs" validate "$CONFIG" >/dev/null || die "invalid config"
OBJECTIVE="$(node "$LIB/config.mjs" get "$CONFIG" objective)"
EVAL_CMD="$(node "$LIB/config.mjs" get "$CONFIG" eval_cmd)"
DIRECTION="$(node "$LIB/config.mjs" get "$CONFIG" direction)"
METRIC_TYPE="$(node "$LIB/config.mjs" get "$CONFIG" metric.type)"
MAX_ITER="$(node "$LIB/config.mjs" get "$CONFIG" budget.max_iterations)"
MAX_WALL="$(node "$LIB/config.mjs" get "$CONFIG" budget.max_wallclock_min)"
ITER_TIMEOUT="$(node "$LIB/config.mjs" get "$CONFIG" budget.per_iter_timeout_sec)"
NO_IMPROVE_LIMIT="$(node "$LIB/config.mjs" get "$CONFIG" stop_after_no_improve 2>/dev/null || echo 0)"
if [ "$METRIC_TYPE" = "regex" ]; then
  METRIC_ARG="$(node "$LIB/config.mjs" get "$CONFIG" metric.pattern)"
else
  METRIC_ARG="$(node "$LIB/config.mjs" get "$CONFIG" metric.path)"
fi
ARTIFACTS_NL="$(node "$LIB/config.mjs" get-array "$CONFIG" artifact)"

run_id="$(date +%Y%m%d-%H%M%S)-$$"
rundir="$repo/.autoresearch/$run_id"
wt="$rundir/worktree"
journal="$rundir/journal.md"
stop="$rundir/STOP"
evalout="$rundir/eval.out"
mkdir -p "$rundir"

grep -qxF '.autoresearch/' "$repo/.gitignore" 2>/dev/null || echo '.autoresearch/' >> "$repo/.gitignore"

git worktree add -b "autoresearch/$run_id" "$wt" HEAD >/dev/null 2>&1 || die "could not create worktree"

measure() {  # prints metric to stdout, or nothing on failure
  if ( cd "$wt" && run_timeout "$ITER_TIMEOUT" bash -c "$EVAL_CMD" ) >"$evalout" 2>&1; then
    if [ "$METRIC_TYPE" = "regex" ]; then
      node "$LIB/metric.mjs" extract-regex "$METRIC_ARG" "$evalout" 2>/dev/null || true
    else
      node "$LIB/metric.mjs" extract-json "$METRIC_ARG" "$evalout" 2>/dev/null || true
    fi
  fi
}

revert_worktree() { ( cd "$wt" && git checkout -- . >/dev/null 2>&1 && git clean -fdq >/dev/null 2>&1 ); }

baseline="$(measure)"
[ -n "$baseline" ] || die "baseline evaluation failed (see $evalout)"
best="$baseline"

{
  echo "# autoresearch run $run_id"
  echo "objective: $OBJECTIVE"
  echo "direction: $DIRECTION | baseline: $baseline | budget: $MAX_ITER iters / $MAX_WALL min"
  echo
} > "$journal"

start="$(date +%s)"
iter=0
no_improve=0
proposer_cmd="${AUTORESEARCH_PROPOSER_CMD:-$LIB/proposer.sh}"

while [ "$iter" -lt "$MAX_ITER" ]; do
  [ -f "$stop" ] && { echo "STOP file present; stopping."; break; }
  elapsed_min=$(( ( $(date +%s) - start ) / 60 ))
  [ "$elapsed_min" -ge "$MAX_WALL" ] && { echo "wall-clock cap reached; stopping."; break; }
  if [ "$NO_IMPROVE_LIMIT" -gt 0 ] && [ "$no_improve" -ge "$NO_IMPROVE_LIMIT" ]; then
    echo "plateau ($no_improve consecutive no-improve); stopping."; break
  fi
  iter=$(( iter + 1 ))

  AR_OBJECTIVE="$OBJECTIVE" AR_BEST="$best" AR_DIRECTION="$DIRECTION" \
  AR_JOURNAL="$journal" AR_WORKTREE="$wt" AR_ARTIFACTS="$ARTIFACTS_NL" \
    "$proposer_cmd" >>"$rundir/proposer.log" 2>&1 || true

  changed="$(cd "$wt" && git status --porcelain | sed 's/^...//')"
  if [ -z "$changed" ]; then
    printf '## iter %s — REVERTED (no change)\n\n' "$iter" >> "$journal"
    no_improve=$(( no_improve + 1 )); continue
  fi

  if ! printf '%s\n' "$changed" | node "$LIB/scope.mjs" "$ARTIFACTS_NL"; then
    revert_worktree
    printf '## iter %s — REVERTED (out-of-scope)\n\n' "$iter" >> "$journal"
    no_improve=$(( no_improve + 1 )); continue
  fi

  metric="$(measure)"
  if [ -z "$metric" ]; then
    revert_worktree
    printf '## iter %s — REVERTED (eval failed/timeout)\n\n' "$iter" >> "$journal"
    no_improve=$(( no_improve + 1 )); continue
  fi

  if node "$LIB/metric.mjs" improved "$metric" "$best" "$DIRECTION"; then
    ( cd "$wt" && git add -A && git commit -q -m "autoresearch: $metric (was $best) [iter $iter]" )
    sha="$(cd "$wt" && git rev-parse --short HEAD)"
    printf '## iter %s — KEPT  (%s → %s)  commit: %s\n\n' "$iter" "$best" "$metric" "$sha" >> "$journal"
    best="$metric"; no_improve=0
  else
    revert_worktree
    printf '## iter %s — REVERTED  (%s vs best %s)\n\n' "$iter" "$metric" "$best" >> "$journal"
    no_improve=$(( no_improve + 1 ))
  fi
done

{
  echo "## summary"
  echo "baseline: $baseline -> best: $best | iterations: $iter"
} >> "$journal"

echo "autoresearch done. best=$best (baseline=$baseline) after $iter iters."
echo "branch:  autoresearch/$run_id"
echo "journal: $journal"
echo "merge:   git merge autoresearch/$run_id"
echo "discard: git worktree remove \"$wt\" && git branch -D autoresearch/$run_id"
