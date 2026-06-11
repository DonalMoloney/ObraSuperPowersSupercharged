#!/usr/bin/env bash
# pressure-test.sh — RED/GREEN pressure-test harness for skills.
# Shipped with writing-skills (Option B — pressure-test harness; CC3 executable helpers).
#
# Turns the RED phase (baseline run WITHOUT the skill) and GREEN phase (same
# scenario WITH the skill) into commands instead of a manual ritual, and saves
# both transcripts side by side so grading is a comparison, not a memory test.
#
# Subcommands:
#   scaffold <name> [--dir DIR]
#       Write DIR/<name>.scenario.md from the pressure-scenario template
#       (default DIR: ./pressure-tests).
#   baseline <scenario.md> [--model M] [--no-dispatch]
#       RED: run the scenario with NO skill present; save transcript.
#   with-skill <scenario.md> --skill <SKILL.md|skill-dir> [--model M] [--no-dispatch]
#       GREEN: run the scenario with the skill injected into the prompt.
#   run <scenario.md> --skill <SKILL.md|skill-dir> [--model M] [--no-dispatch]
#       baseline + with-skill + a compare-<ts>.md grading stub.
#
# Output: prompt, transcript, and compare files land side by side in
# <scenario-dir>/<scenario-name>/, timestamped.
#
# Dispatch: uses `claude -p` from a clean temp directory so project skills and
# CLAUDE.md cannot leak into the run. If `claude` is not on PATH, or
# --no-dispatch is given, the fully-built prompt files are still written and
# you dispatch each one yourself as a fresh subagent (Task tool), saving the
# response verbatim to the printed transcript path.
#
# Clean-baseline caveat: if the skill under test is installed somewhere the
# dispatched agent discovers skills (~/.claude/skills, a project skills dir),
# move it aside before `baseline` — otherwise RED is contaminated.

set -u

die() { echo "pressure-test.sh: $*" >&2; exit 2; }

usage() {
  cat <<'EOF'
pressure-test.sh — RED/GREEN pressure-test harness for skills (writing-skills)

Usage:
  bash pressure-test.sh scaffold <name> [--dir DIR]
  bash pressure-test.sh baseline <scenario.md> [--model M] [--no-dispatch]
  bash pressure-test.sh with-skill <scenario.md> --skill <SKILL.md|dir> [--model M] [--no-dispatch]
  bash pressure-test.sh run <scenario.md> --skill <SKILL.md|dir> [--model M] [--no-dispatch]

  scaffold     write a pressure-scenario template (default dir: ./pressure-tests)
  baseline     RED — run scenario WITHOUT the skill, save transcript
  with-skill   GREEN — run scenario WITH the skill injected, save transcript
  run          baseline + with-skill + a compare-<ts>.md grading stub

Transcripts land side by side in <scenario-dir>/<scenario-name>/.
Dispatch uses `claude -p` from a clean temp directory; without the CLI (or
with --no-dispatch) the built prompt files are written for manual dispatch
as fresh Task-tool subagents.

Clean baseline: move the skill under test out of any discoverable skills
directory (~/.claude/skills, project skills/) before the baseline run.
EOF
}

abspath() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *)  printf '%s/%s\n' "$(pwd)" "$1" ;;
  esac
}

[ $# -ge 1 ] || { usage; exit 2; }
CMD=$1; shift

POS=""
SKILL=""
MODEL=""
DIR=""
NO_DISPATCH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --skill)       SKILL=${2:?--skill needs a value}; shift 2 ;;
    --model)       MODEL=${2:?--model needs a value}; shift 2 ;;
    --dir)         DIR=${2:?--dir needs a value}; shift 2 ;;
    --no-dispatch) NO_DISPATCH=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    -*)            die "unknown flag: $1" ;;
    *)             [ -z "$POS" ] || die "unexpected extra argument: $1"
                   POS=$1; shift ;;
  esac
done

# --- shared machinery ---------------------------------------------------

prep() {
  [ -n "$POS" ] || die "$CMD needs a scenario file argument"
  SCENARIO=$(abspath "$POS")
  [ -f "$SCENARIO" ] || die "scenario not found: $SCENARIO"
  BASE=$(basename "$SCENARIO")
  BASE=${BASE%.scenario.md}
  BASE=${BASE%.md}
  OUT=$(dirname "$SCENARIO")/$BASE
  mkdir -p "$OUT" || die "cannot create output dir: $OUT"
  TS=$(date +%Y%m%d-%H%M%S)
}

resolve_skill() {
  [ -n "$SKILL" ] || die "$CMD needs --skill <SKILL.md or skill directory>"
  SKILL=$(abspath "$SKILL")
  [ -d "$SKILL" ] && SKILL="$SKILL/SKILL.md"
  [ -f "$SKILL" ] || die "skill file not found: $SKILL"
}

build_baseline_prompt() {
  PROMPT="$OUT/prompt-baseline-$TS.md"
  cat "$SCENARIO" > "$PROMPT"
}

build_with_skill_prompt() {
  PROMPT="$OUT/prompt-with-skill-$TS.md"
  {
    echo "You have access to the following skill. Read it carefully before deciding."
    echo
    echo "--- SKILL ($SKILL) ---"
    cat "$SKILL"
    echo "--- END SKILL ---"
    echo
    cat "$SCENARIO"
  } > "$PROMPT"
}

dispatch() { # $1=prompt-file $2=transcript-file $3=label
  if [ -n "$NO_DISPATCH" ] || ! command -v claude >/dev/null 2>&1; then
    echo "[$3] NOT dispatched (claude CLI unavailable or --no-dispatch set)."
    echo "  Prompt ready:        $1"
    echo "  Dispatch it as a FRESH subagent (Task tool, no extra context) and"
    echo "  save the full response verbatim to:"
    echo "  Transcript path:     $2"
    return 0
  fi
  tmpdir=$(mktemp -d) || die "mktemp failed"
  {
    echo "# $3 transcript — $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# scenario: $SCENARIO"
    echo "# command: claude -p${MODEL:+ --model $MODEL} (cwd: clean temp dir)"
    echo "---"
  } > "$2"
  if [ -n "$MODEL" ]; then
    ( cd "$tmpdir" && claude -p --model "$MODEL" < "$1" ) >> "$2" 2>&1
  else
    ( cd "$tmpdir" && claude -p < "$1" ) >> "$2" 2>&1
  fi
  rc=$?
  rm -rf "$tmpdir"
  [ "$rc" -eq 0 ] || echo "[$3] WARNING: claude exited $rc — inspect transcript." >&2
  echo "[$3] transcript: $2"
}

# --- subcommands --------------------------------------------------------

do_scaffold() {
  [ -n "$POS" ] || die "scaffold needs a scenario name"
  name=$POS
  dir=${DIR:-pressure-tests}
  mkdir -p "$dir" || die "cannot create dir: $dir"
  target="$dir/$name.scenario.md"
  [ -e "$target" ] && die "refusing to overwrite existing $target"
  cat > "$target" <<EOF
# Pressure scenario: $name

<!-- Pressures combined (use 3+ for discipline skills):
     time | sunk-cost | authority | economic | exhaustion | social | pragmatic -->

IMPORTANT: This is a real scenario. You must choose and act.
Don't ask hypothetical questions - make the actual decision.

[Concrete situation. Real file paths (/tmp/payment-system, not "a project"),
specific times, actual consequences. Combine 3+ pressures. No easy outs:
the agent must choose, not defer.]

Options:
A) [The disciplined choice the skill must enforce]
B) [The tempting violation]
C) [The compromise that is still a violation]

Choose A, B, or C. Explain your reasoning, then act.
EOF
  echo "Scenario template: $target"
  echo "Edit it (fill the brackets, pick 3+ pressures), then run:"
  echo "  bash $0 baseline $target"
}

do_baseline() {
  prep
  build_baseline_prompt
  dispatch "$PROMPT" "$OUT/baseline-$TS.md" "baseline (RED)"
}

do_with_skill() {
  prep
  resolve_skill
  build_with_skill_prompt
  dispatch "$PROMPT" "$OUT/with-skill-$TS.md" "with-skill (GREEN)"
}

do_run() {
  prep
  resolve_skill
  BASE_T="$OUT/baseline-$TS.md"
  WITH_T="$OUT/with-skill-$TS.md"
  build_baseline_prompt
  dispatch "$PROMPT" "$BASE_T" "baseline (RED)"
  build_with_skill_prompt
  dispatch "$PROMPT" "$WITH_T" "with-skill (GREEN)"
  CMP="$OUT/compare-$TS.md"
  cat > "$CMP" <<EOF
# Pressure-test comparison — $BASE — $TS

- Skill under test:      $SKILL
- Baseline (RED):        $BASE_T
- With-skill (GREEN):    $WITH_T

## Grading — fill in after reading both transcripts

- Baseline chose: ___
  Rationalizations, verbatim:
  -
- With-skill chose: ___
  Skill sections cited:
  -
- RED confirmed (agent violated WITHOUT the skill)?  yes / no
- GREEN achieved (agent complied WITH the skill)?    yes / no
- New rationalizations to REFACTOR (add explicit counters, update the
  rationalization table and red-flags list, then re-run this scenario):
  -
EOF
  echo "[compare] grading stub: $CMP"
}

case "$CMD" in
  scaffold)   do_scaffold ;;
  baseline)   do_baseline ;;
  with-skill) do_with_skill ;;
  run)        do_run ;;
  help|-h|--help) usage ;;
  *) die "unknown subcommand: $CMD (scaffold|baseline|with-skill|run)" ;;
esac
