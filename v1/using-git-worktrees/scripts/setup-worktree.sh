#!/usr/bin/env bash
# setup-worktree.sh — mechanical helpers for the using-git-worktrees skill.
#
# Subcommands:
#   detect                          Print isolation facts (linked worktree vs
#                                   submodule vs normal repo) and the directory the
#                                   git fallback would use.
#   create <branch> [dir]           Git-fallback worktree creation: directory
#                                   priority, ignore verification (+commit),
#                                   `git worktree add`. ONLY for the no-native-tool
#                                   path — native worktree tools (EnterWorktree,
#                                   /worktree, --worktree) always take precedence.
#   setup [path]                    Auto-detect project type, run dependency setup.
#   baseline [--] <cmd...>          Run the test command and record the baseline
#                                   evidence block (command, exit, digest, summary)
#                                   to this worktree's git dir, for
#                                   finishing-a-development-branch to compare against.
#   baseline-show                   Print the recorded baseline block.
#   baseline-compare [--] [cmd...]  Re-run tests (default: the recorded command) and
#                                   print VERDICT= distinguishing a regression from
#                                   a pre-existing failure.
#
# Safety properties (these replace prose rules in SKILL.md):
#   - `create` refuses to nest a worktree inside an existing linked worktree.
#   - Project-local worktree directories are verified ignored (and the .gitignore
#     entry committed) BEFORE `git worktree add` runs, never after.
#   - The baseline lives in the worktree's own git dir, so it survives the session
#     and is removed automatically when the worktree is cleaned up.
set -euo pipefail

die()  { echo "ERROR: $*" >&2; exit 1; }
note() { echo "NOTE: $*" >&2; }

usage() {
  cat <<'EOF'
Usage: setup-worktree.sh <subcommand>
  detect                          Print isolation facts + fallback directory choice
  create <branch> [dir]           Create git-fallback worktree (no-native-tool path only)
  setup [path]                    Auto-detect and run project dependency setup
  baseline [--] <cmd...>          Run tests, record baseline evidence block
  baseline-show                   Print recorded baseline block
  baseline-compare [--] [cmd...]  Re-run tests, compare against recorded baseline
EOF
}

require_repo() {
  git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"
}

# Sets: GIT_DIR, GIT_COMMON, ROOT
git_dirs() {
  GIT_DIR=$(cd "$(git rev-parse --git-dir)" && pwd -P)
  GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
  ROOT=$(git rev-parse --show-toplevel)
}

current_branch() {
  git symbolic-ref --quiet --short HEAD || echo "DETACHED"
}

in_submodule() {
  [ -n "$(git rev-parse --show-superproject-working-tree 2>/dev/null)" ]
}

# Sets LOCATION, LOCATION_SOURCE.
# Priority: existing .worktrees > existing worktrees > existing global legacy >
# default .worktrees. An explicit user preference is passed as an argument to
# `create` and beats all of these.
choose_location() {
  local project
  project=$(basename "$ROOT")
  if [ -d "$ROOT/.worktrees" ]; then
    LOCATION="$ROOT/.worktrees";  LOCATION_SOURCE=project-local-existing
  elif [ -d "$ROOT/worktrees" ]; then
    LOCATION="$ROOT/worktrees";   LOCATION_SOURCE=project-local-existing
  elif [ -d "$HOME/.config/superpowers/worktrees/$project" ]; then
    LOCATION="$HOME/.config/superpowers/worktrees/$project"; LOCATION_SOURCE=global-legacy
  else
    LOCATION="$ROOT/.worktrees";  LOCATION_SOURCE=default
  fi
}

baseline_file() { echo "$(git rev-parse --git-dir)/superpowers-baseline"; }

digest_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -c1-12
  else
    shasum -a 256 "$1" | cut -c1-12
  fi
}

last_nonempty_line() {
  grep -v '^[[:space:]]*$' "$1" | tail -n 1 || true
}

cmd_detect() {
  git_dirs
  local state
  if in_submodule; then
    state=submodule           # GIT_DIR != GIT_COMMON here does NOT mean isolation
  elif [ "$GIT_DIR" != "$GIT_COMMON" ]; then
    state=already-isolated
  else
    state=normal-repo
  fi

  echo "STATE=$state"
  echo "BRANCH=$(current_branch)"
  echo "WORKTREE_PATH=$ROOT"
  if [ "$state" = "already-isolated" ]; then
    echo "NEXT=skip-creation-go-to-setup"
  else
    choose_location
    echo "LOCATION=$LOCATION"
    echo "LOCATION_SOURCE=$LOCATION_SOURCE"
    echo "NEXT=ask-consent-then-prefer-native-tool"
  fi
}

cmd_create() {
  local branch=${1:-} dir=${2:-}
  [ -n "$branch" ] || die "usage: setup-worktree.sh create <branch-name> [directory]"
  note "git-fallback path (Step 1b). If a native worktree tool exists, use it instead — do not run create."

  git_dirs
  if ! in_submodule && [ "$GIT_DIR" != "$GIT_COMMON" ]; then
    die "already inside a linked worktree ($ROOT); refusing to nest. Run 'detect' and skip to setup."
  fi

  if [ -n "$dir" ]; then
    LOCATION=$dir; LOCATION_SOURCE=user-preference
  else
    choose_location
  fi
  note "directory: $LOCATION (source: $LOCATION_SOURCE)"

  # Ignore verification — project-local locations only. Global paths need none.
  case "$LOCATION" in
    "$ROOT"/*)
      local rel=${LOCATION#"$ROOT"/}
      rel=${rel%%/*}
      if ! git -C "$ROOT" check-ignore -q "$rel"; then
        printf '/%s/\n' "$rel" >> "$ROOT/.gitignore"
        git -C "$ROOT" add .gitignore
        git -C "$ROOT" commit -m "chore: ignore $rel worktree directory" >/dev/null
        note "added /$rel/ to .gitignore and committed"
      fi
      ;;
  esac

  mkdir -p "$LOCATION"
  local path="$LOCATION/$branch"
  [ ! -e "$path" ] || die "$path already exists; choose another branch name or remove it first"

  if ! git worktree add "$path" -b "$branch"; then
    die "git worktree add failed (sandbox denial?). Tell the user, then work in place: run 'setup' and 'baseline' in the current directory instead."
  fi

  echo "WORKTREE_PATH=$path"
  echo "BRANCH=$branch"
  echo "NEXT=cd into WORKTREE_PATH, then: setup-worktree.sh setup && setup-worktree.sh baseline -- <test command>"
}

cmd_setup() {
  local dir=${1:-.}
  cd "$dir"
  local ran=no
  if [ -f package.json ];     then ran=yes; note "package.json -> npm install";        npm install; fi
  if [ -f Cargo.toml ];       then ran=yes; note "Cargo.toml -> cargo build";          cargo build; fi
  if [ -f requirements.txt ]; then ran=yes; note "requirements.txt -> pip install";    pip install -r requirements.txt; fi
  if [ -f pyproject.toml ];   then ran=yes; note "pyproject.toml -> poetry install";   poetry install; fi
  if [ -f go.mod ];           then ran=yes; note "go.mod -> go mod download";          go mod download; fi
  [ "$ran" = yes ] || note "no recognized manifest; skipping dependency install"
  echo "SETUP=done"
}

cmd_baseline() {
  [ "${1:-}" = "--" ] && shift
  [ $# -gt 0 ] || die "usage: setup-worktree.sh baseline [--] <test command...>"
  local file out cmd exit_code status
  file=$(baseline_file)
  out="$file.out"
  cmd="$*"

  note "running baseline: $cmd"
  set +e
  "$@" >"$out" 2>&1
  exit_code=$?
  set -e
  if [ "$exit_code" -eq 0 ]; then status=pass; else status=fail; fi

  {
    echo "BASELINE_CMD=$cmd"
    echo "BASELINE_EXIT=$exit_code"
    echo "BASELINE_STATUS=$status"
    echo "BASELINE_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo NONE)"
    echo "BASELINE_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "BASELINE_DIGEST=$(digest_of "$out")"
    echo "BASELINE_SUMMARY=$(last_nonempty_line "$out")"
    echo "BASELINE_OUTPUT=$out"
  } > "$file"

  cat "$file"
  echo "BASELINE_FILE=$file"
  if [ "$status" = fail ]; then
    note "baseline is FAILING. Report the failures and ask whether to proceed or investigate (SKILL.md Step 4). The failing baseline is recorded so finish-time comparison can tell pre-existing breakage from new breakage."
  fi
}

cmd_baseline_show() {
  local file
  file=$(baseline_file)
  [ -f "$file" ] || die "no baseline recorded for this worktree (run: setup-worktree.sh baseline -- <test command>)"
  cat "$file"
}

cmd_baseline_compare() {
  local file
  file=$(baseline_file)
  [ -f "$file" ] || die "no baseline recorded for this worktree (run: setup-worktree.sh baseline -- <test command>)"

  local b_cmd b_exit b_digest b_out
  b_cmd=$(grep '^BASELINE_CMD=' "$file" | cut -d= -f2-)
  b_exit=$(grep '^BASELINE_EXIT=' "$file" | cut -d= -f2-)
  b_digest=$(grep '^BASELINE_DIGEST=' "$file" | cut -d= -f2-)
  b_out=$(grep '^BASELINE_OUTPUT=' "$file" | cut -d= -f2-)

  [ "${1:-}" = "--" ] && shift
  local out exit_code
  out="$(git rev-parse --git-dir)/superpowers-final.out"
  set +e
  if [ $# -gt 0 ]; then
    note "running final: $*"
    "$@" >"$out" 2>&1
  else
    note "running recorded baseline command: $b_cmd"
    bash -c "$b_cmd" >"$out" 2>&1
  fi
  exit_code=$?
  set -e

  local digest verdict
  digest=$(digest_of "$out")
  if [ "$b_exit" -eq 0 ] && [ "$exit_code" -eq 0 ]; then
    verdict=clean                  # passed at baseline, passes now
  elif [ "$b_exit" -eq 0 ] && [ "$exit_code" -ne 0 ]; then
    verdict=regression             # you broke it
  elif [ "$b_exit" -ne 0 ] && [ "$exit_code" -eq 0 ]; then
    verdict=fixed                  # was broken at baseline, passes now
  else
    verdict=pre-existing-failure   # was already broken at baseline
  fi

  echo "BASELINE_EXIT=$b_exit"
  echo "FINAL_EXIT=$exit_code"
  echo "FINAL_SUMMARY=$(last_nonempty_line "$out")"
  echo "FINAL_OUTPUT=$out"
  if [ "$digest" = "$b_digest" ]; then echo "DIGEST_MATCH=yes"; else echo "DIGEST_MATCH=no"; fi
  echo "VERDICT=$verdict"
  if [ "$verdict" = "pre-existing-failure" ]; then
    note "both runs fail — diff the outputs to check for NEW failures on top of the old ones: diff $b_out $out"
  fi
}

require_repo
case "${1:-}" in
  detect)           cmd_detect ;;
  create)           shift; cmd_create "$@" ;;
  setup)            shift; cmd_setup "$@" ;;
  baseline)         shift; cmd_baseline "$@" ;;
  baseline-show)    cmd_baseline_show ;;
  baseline-compare) shift; cmd_baseline_compare "$@" ;;
  -h|--help|help)   usage ;;
  *) usage; exit 1 ;;
esac
