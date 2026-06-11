#!/usr/bin/env bash
# finish-branch.sh — mechanical helpers for the finishing-a-development-branch skill.
#
# Subcommands:
#   detect                       Print environment facts (state, branch, base,
#                                provenance, which menu to show, cleanup ownership).
#   merge <feature> [base]       CWD-safe merge of <feature> into [base]. Does NOT
#                                clean up — run the test suite on the merged result
#                                first, then call `cleanup`.
#   cleanup <feature> [--force]  Provenance-checked worktree removal, THEN branch
#                                delete (safe order by construction). --force uses
#                                `git branch -D` (discard path).
#
# Safety properties (these replace prose rules in SKILL.md):
#   - Always cds to the main repo root before merge/cleanup, so `git worktree
#     remove` is never run from inside the worktree being removed.
#   - Removes the worktree BEFORE deleting the branch, so `git branch -d` can't
#     fail on a worktree reference.
#   - Refuses to remove worktrees it doesn't own: only paths under `.worktrees/`,
#     `worktrees/`, or `~/.config/superpowers/worktrees/` are superpowers-created.
set -euo pipefail

die()  { echo "ERROR: $*" >&2; exit 1; }
note() { echo "NOTE: $*" >&2; }

usage() {
  cat <<'EOF'
Usage: finish-branch.sh <subcommand>
  detect                       Print environment facts (state, branch, base, provenance, menu)
  merge <feature> [base]       CWD-safe merge of <feature> into [base]; no cleanup
  cleanup <feature> [--force]  Remove superpowers-owned worktree, then delete branch
EOF
}

require_repo() {
  git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"
}

# Sets: GIT_DIR, GIT_COMMON, WORKTREE_PATH, MAIN_ROOT
git_dirs() {
  GIT_DIR=$(cd "$(git rev-parse --git-dir)" && pwd -P)
  GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
  WORKTREE_PATH=$(git rev-parse --show-toplevel)
  MAIN_ROOT=$(git -C "$GIT_COMMON/.." rev-parse --show-toplevel)
}

current_branch() {
  git symbolic-ref --quiet --short HEAD || echo "DETACHED"
}

# detect_base [ref] — first of main/master that shares history with ref (default HEAD)
detect_base() {
  local ref=${1:-HEAD} b
  for b in main master; do
    if git rev-parse --verify --quiet "refs/heads/$b" >/dev/null \
       && git merge-base "$ref" "$b" >/dev/null 2>&1; then
      echo "$b"
      return
    fi
  done
  echo "UNKNOWN"
}

# provenance — none (normal repo) | superpowers (we created it) | external (harness/user)
provenance() {
  if [ "$GIT_DIR" = "$GIT_COMMON" ]; then
    echo none
    return
  fi
  case "$WORKTREE_PATH" in
    */.worktrees/*|*/worktrees/*|"$HOME/.config/superpowers/worktrees/"*)
      echo superpowers ;;
    *)
      echo external ;;
  esac
}

cmd_detect() {
  git_dirs
  local branch base prov state menu cleanup
  branch=$(current_branch)
  base=$(detect_base)
  prov=$(provenance)

  if [ "$GIT_DIR" = "$GIT_COMMON" ]; then
    state=normal-repo;        menu=standard-4
  elif [ "$branch" = "DETACHED" ]; then
    state=worktree-detached;  menu=detached-3
  else
    state=worktree-branch;    menu=standard-4
  fi

  case "$prov" in
    none)        cleanup=no-worktree ;;
    superpowers) cleanup=script-owned ;;
    external)    cleanup=harness-owned-do-not-remove ;;
  esac

  cat <<EOF
STATE=$state
BRANCH=$branch
BASE_BRANCH=$base
WORKTREE_PATH=$WORKTREE_PATH
MAIN_ROOT=$MAIN_ROOT
PROVENANCE=$prov
MENU=$menu
CLEANUP=$cleanup
EOF
}

cmd_merge() {
  local feature=${1:-} base=${2:-}
  [ -n "$feature" ] || die "usage: finish-branch.sh merge <feature-branch> [base-branch]"
  git_dirs
  git rev-parse --verify --quiet "refs/heads/$feature" >/dev/null \
    || die "branch '$feature' not found"

  if [ -z "$base" ]; then
    base=$(detect_base "$feature")
    [ "$base" != "UNKNOWN" ] \
      || die "cannot auto-detect base branch; pass it explicitly: finish-branch.sh merge $feature <base>"
    note "base branch auto-detected: $base"
  fi
  [ "$feature" != "$base" ] || die "feature and base branch are the same ('$feature')"

  # CWD safety: never operate from inside a worktree
  cd "$MAIN_ROOT"

  git checkout "$base"
  if git rev-parse --verify --quiet '@{upstream}' >/dev/null 2>&1; then
    git pull --ff-only \
      || die "could not fast-forward '$base' from upstream; resolve manually, then re-run"
  else
    note "'$base' has no upstream; skipping pull"
  fi

  if ! git merge "$feature"; then
    die "merge of '$feature' into '$base' failed; resolve conflicts manually (branch and worktree preserved)"
  fi

  echo "MERGE_SHA=$(git rev-parse HEAD)"
  echo "Merged '$feature' into '$base'."
  echo "NEXT: run the project test suite on the merged result; only after it passes, run: finish-branch.sh cleanup $feature"
}

cmd_cleanup() {
  local feature=${1:-} force=no
  [ -n "$feature" ] || die "usage: finish-branch.sh cleanup <feature-branch> [--force]"
  [ "${2:-}" = "--force" ] && force=yes

  git_dirs
  local prov
  prov=$(provenance)

  if [ "$prov" = "external" ]; then
    die "worktree at $WORKTREE_PATH is harness-owned (not under .worktrees/, worktrees/, or ~/.config/superpowers/worktrees/). Leave it in place; use the platform's workspace-exit tool if one exists."
  fi

  # CWD safety: never remove a worktree from inside it
  cd "$MAIN_ROOT"

  # Order matters: worktree first, so the branch delete can't be blocked by it.
  if [ "$prov" = "superpowers" ]; then
    git worktree remove "$WORKTREE_PATH" \
      || die "git worktree remove failed for $WORKTREE_PATH (uncommitted changes?); inspect manually before retrying"
    git worktree prune  # self-healing: clean up any stale registrations
    echo "Removed worktree $WORKTREE_PATH"
  fi

  if [ "$(current_branch)" = "$feature" ]; then
    local base
    base=$(detect_base "$feature")
    [ "$base" != "UNKNOWN" ] \
      || die "'$feature' is checked out here and no base branch was found; check out another branch first"
    git checkout "$base"
  fi

  if [ "$force" = "yes" ]; then
    git branch -D "$feature"
  else
    git branch -d "$feature" \
      || die "git refused to delete '$feature' (unmerged commits?). Verify the merge landed, or re-run with --force only if discarding."
  fi
  echo "Deleted branch $feature"
  echo "CLEANUP=done"
}

require_repo
case "${1:-}" in
  detect)  cmd_detect ;;
  merge)   shift; cmd_merge "$@" ;;
  cleanup) shift; cmd_cleanup "$@" ;;
  -h|--help|help) usage ;;
  *) usage; exit 1 ;;
esac
