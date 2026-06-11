#!/usr/bin/env bash
# lint-skill.sh — mechanical linter for SKILL.md files.
# Shipped with writing-skills (Option C — skill linter; CC3 executable helpers).
#
# Catches format, not effectiveness — a passing skill still needs pressure
# testing (see pressure-test.sh in this directory).
#
# Checks:
#   1. frontmatter      opening/closing --- block, non-empty name and
#                       description, total frontmatter <= 1024 characters
#   2. kebab-case-name  lowercase letters, digits, single hyphens
#   3. description      starts with "Use when"
#   4. word-budget      by skill class: always-loaded 200 | standard 500 |
#                       reference 2000. Override with --max-words N (the
#                       escape hatch for genuinely irreducible skills).
#   5. at-force-loads   no @path/with/slashes outside code fences or inline
#                       backticks. Cross-file @ links force-load files and
#                       burn context. Same-directory @file.md references
#                       (no slash) are the skill's own progressive-disclosure
#                       business and are not flagged.
#
# Usage:
#   bash lint-skill.sh [--class always-loaded|standard|reference] [--max-words N] <path>...
#   <path> may be a SKILL.md file, a skill directory, or a tree to scan for
#   SKILL.md files.
#
# Exit 0 only if every check on every file passes — usable as cheap CI.

set -u

die() { echo "lint-skill.sh: $*" >&2; exit 2; }

usage() {
  cat <<'EOF'
lint-skill.sh — mechanical linter for SKILL.md files (writing-skills)

Usage:
  bash lint-skill.sh [--class always-loaded|standard|reference] [--max-words N] <path>...

<path> may be a SKILL.md file, a skill directory, or a tree to scan.
Checks: frontmatter validity, kebab-case name, "Use when" description,
word budget by class (always-loaded 200 / standard 500 / reference 2000),
no cross-file @ force-loads. Exit 0 only if every check on every file passes.
EOF
}

report() { printf '  %-4s %-18s %s\n' "$1" "$2" "$3"; }

CLASS=standard
MAX_WORDS=""
PATHS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --class)     CLASS=${2:?--class needs a value}; shift 2 ;;
    --max-words) MAX_WORDS=${2:?--max-words needs a value}; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    -*)          die "unknown flag: $1" ;;
    *)           PATHS="$PATHS
$1"; shift ;;
  esac
done

[ -n "$PATHS" ] || { usage; exit 2; }

case "$CLASS" in
  always-loaded) BUDGET=200 ;;
  standard)      BUDGET=500 ;;
  reference)     BUDGET=2000 ;;
  *) die "unknown class: $CLASS (always-loaded|standard|reference)" ;;
esac
[ -n "$MAX_WORDS" ] && BUDGET=$MAX_WORDS

NL='
'

# Resolve arguments to a newline-separated list of SKILL.md files.
FILES=""
set -f
IFS=$NL
for p in $PATHS; do
  IFS=$' \t\n'
  [ -n "$p" ] || { IFS=$NL; continue; }
  if [ -f "$p" ]; then
    FILES="$FILES$NL$p"
  elif [ -d "$p" ]; then
    if [ -f "$p/SKILL.md" ]; then
      FILES="$FILES$NL$p/SKILL.md"
    else
      found=$(find "$p" -type f -name SKILL.md | sort)
      [ -n "$found" ] || die "no SKILL.md found under: $p"
      FILES="$FILES$NL$found"
    fi
  else
    die "not found: $p"
  fi
  IFS=$NL
done
IFS=$' \t\n'
set +f

lint_file() {
  local IFS=$' \t\n'
  local f=$1 fails=0
  local first close fm fmlen name desc desclow words hits missing

  echo "== $f (class: $CLASS, budget: $BUDGET words) =="

  # 1. Frontmatter validity
  name=""
  desc=""
  first=$(head -n 1 "$f" | tr -d '\r')
  close=$(awk 'NR>1 && /^---[[:space:]]*$/ {print NR; exit}' "$f")
  if [ "$first" != "---" ] || [ -z "$close" ]; then
    report FAIL "frontmatter" "no opening/closing --- frontmatter block"
    fails=$((fails+1))
  else
    fm=$(awk -v end="$close" 'NR>1 && NR<end' "$f")
    fmlen=$(printf '%s' "$fm" | wc -c | tr -d ' ')
    name=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -n 1 \
      | sed -e 's/[[:space:]]*$//' -e 's/^["'\'']//' -e 's/["'\'']$//')
    desc=$(printf '%s\n' "$fm" | awk '
      /^description:/ { sub(/^description:[[:space:]]*/, ""); d=$0; on=1; next }
      on && /^[[:space:]]/ { l=$0; sub(/^[[:space:]]+/, "", l); d=d " " l; next }
      on { on=0 }
      END { print d }' \
      | sed -e 's/^[>|][+-]\{0,1\}[[:space:]]*//' -e 's/^["'\'']//' -e 's/["'\'']$//')
    if [ -z "$name" ] || [ -z "$desc" ]; then
      missing=""
      [ -z "$name" ] && missing="name"
      [ -z "$desc" ] && missing="${missing:+$missing, }description"
      report FAIL "frontmatter" "missing/empty required field(s): $missing"
      fails=$((fails+1))
    elif [ "$fmlen" -gt 1024 ]; then
      report FAIL "frontmatter" "frontmatter is $fmlen chars (max 1024)"
      fails=$((fails+1))
    else
      report PASS "frontmatter" "name + description present, ${fmlen}/1024 chars"
    fi
  fi

  # 2. kebab-case name
  if [ -z "$name" ]; then
    report FAIL "kebab-case-name" "no name field to check"
    fails=$((fails+1))
  else
    case "$name" in
      *[!a-z0-9-]*|-*|*-|*--*)
        report FAIL "kebab-case-name" "\"$name\" (want lowercase letters/digits, single hyphens)"
        fails=$((fails+1)) ;;
      *)
        report PASS "kebab-case-name" "\"$name\"" ;;
    esac
  fi

  # 3. Description starts with "Use when"
  desclow=$(printf '%s' "$desc" | tr '[:upper:]' '[:lower:]')
  case "$desclow" in
    "use when"*)
      report PASS "description" "starts with \"Use when\"" ;;
    *)
      report FAIL "description" "must start with \"Use when\"; got: \"$(printf '%s' "$desc" | cut -c 1-60)\""
      fails=$((fails+1)) ;;
  esac

  # 4. Word budget by skill class
  words=$(wc -w < "$f" | tr -d ' ')
  if [ "$words" -le "$BUDGET" ]; then
    report PASS "word-budget" "$words/$BUDGET words"
  else
    report FAIL "word-budget" "$words words > $BUDGET (wrong --class? genuinely irreducible? use --max-words)"
    fails=$((fails+1))
  fi

  # 5. No cross-file @ force-loads (outside code fences and inline backticks)
  hits=$(awk '
    /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    {
      l = $0
      gsub(/`[^`]*`/, "", l)
      if (l ~ /(^|[[:space:](])@[A-Za-z0-9._~-]+\/[^ \t]*/) print "line " NR ": " $0
    }' "$f")
  if [ -z "$hits" ]; then
    report PASS "at-force-loads" "none found"
  else
    report FAIL "at-force-loads" "@path links force-load files and burn context:"
    printf '%s\n' "$hits" | sed 's/^/        /'
    fails=$((fails+1))
  fi

  [ "$fails" -eq 0 ]
}

TOTAL=0
FAILED=0
set -f
IFS=$NL
for f in $FILES; do
  IFS=$' \t\n'
  [ -n "$f" ] || { IFS=$NL; continue; }
  TOTAL=$((TOTAL+1))
  lint_file "$f" || FAILED=$((FAILED+1))
  IFS=$NL
done
IFS=$' \t\n'
set +f

echo
echo "lint-skill: $TOTAL file(s) checked, $FAILED with failures."
[ "$FAILED" -eq 0 ]
