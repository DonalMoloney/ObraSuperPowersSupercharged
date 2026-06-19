#!/usr/bin/env bash
set -euo pipefail

GH_BIN="${GH_BIN:-gh}"
# "copilot" has no [bot] suffix so needs explicit listing; the rest are defense-in-depth.
DENYLIST_JSON='["copilot","github-copilot[bot]","copilot-pull-request-reviewer[bot]","coderabbitai[bot]","github-actions[bot]"]'

usage() {
  cat <<'USAGE'
Usage:
  pr_comments.sh fetch [PR]
  pr_comments.sh filter --self <login> --handled <csv>   (tagged JSON on stdin)
  pr_comments.sh reply <id> <type> <body-file>           (type: inline|conversation|review)
  pr_comments.sh skip <id>
USAGE
}

do_filter() {
  local self="" handled="[]"
  while [ $# -gt 0 ]; do
    case "$1" in
      --self) self="${2:-}"; shift; [ $# -gt 0 ] && shift;;
      --handled) if [ -n "${2:-}" ]; then handled="$(printf '%s' "$2" | jq -R 'split(",") | map(tonumber)')"; fi; shift; [ $# -gt 0 ] && shift;;
      *) shift;;
    esac
  done
  jq --arg self "$self" --argjson handled "$handled" --argjson denylist "$DENYLIST_JSON" '
    map(select(
      (.user.type != "Bot")
      and ((.user.login | endswith("[bot]")) | not)
      and (.user.login != $self)
      and ((.user.login | ascii_downcase) as $l | ($denylist | map(ascii_downcase) | index($l)) == null)
      and ((.id) as $i | ($handled | index($i)) == null)
    ))
    | map({
        id: .id,
        type: ._type,
        author: .user.login,
        created_at: (.created_at // .submitted_at),
        body: .body,
        url: .html_url,
        path: (.path // null),
        line: (.line // .original_line // null),
        diff_hunk: (.diff_hunk // null),
        in_reply_to_id: (.in_reply_to_id // null)
      })
  '
}

resolve_repo() { "$GH_BIN" repo view --json owner,name | jq -r '.owner.login + "/" + .name'; }
resolve_pr()   { if [ -n "${1:-}" ]; then printf '%s' "$1"; else "$GH_BIN" pr view --json number | jq -r '.number'; fi; }
resolve_self() { "$GH_BIN" api user | jq -r '.login'; }

watermark_dir()  { printf '%s' "${PR_WATERMARK_DIR:-$(git rev-parse --git-dir)/pr-comment-watermarks}"; }
watermark_file() { printf '%s/%s.json' "$(watermark_dir)" "$1"; }
read_handled() { # arg: pr -> csv (possibly empty)
  local f; f="$(watermark_file "$1")"
  if [ -f "$f" ]; then jq -r '.handled_ids | map(tostring) | join(",")' "$f"; else printf ''; fi
}

do_fetch() {
  local pr repo self o r inline conv reviews handled
  pr="$(resolve_pr "${1:-}")"
  repo="$(resolve_repo)"; o="${repo%%/*}"; r="${repo##*/}"
  self="$(resolve_self)"
  inline="$("$GH_BIN" api --paginate "/repos/$o/$r/pulls/$pr/comments" | jq 'map(. + {_type:"inline"})')"
  conv="$("$GH_BIN" api --paginate "/repos/$o/$r/issues/$pr/comments" | jq 'map(. + {_type:"conversation"})')"
  reviews="$("$GH_BIN" api --paginate "/repos/$o/$r/pulls/$pr/reviews" | jq 'map(select(.body != null and .body != "")) | map(. + {_type:"review"})')"
  handled="$(read_handled "$pr")"
  jq -n --argjson a "$inline" --argjson b "$conv" --argjson c "$reviews" '$a + $b + $c' \
    | do_filter --self "$self" --handled "$handled"
}

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    filter) do_filter "$@";;
    fetch) do_fetch "$@";;
    -h|--help|help) usage;;
    *) usage >&2; exit 2;;
  esac
}
main "$@"
