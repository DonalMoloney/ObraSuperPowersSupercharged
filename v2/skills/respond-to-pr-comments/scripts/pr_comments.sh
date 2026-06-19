#!/usr/bin/env bash
set -euo pipefail

GH_BIN="${GH_BIN:-gh}"
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
      --self) self="${2:-}"; shift 2;;
      --handled) if [ -n "${2:-}" ]; then handled="$(printf '%s' "$2" | jq -R 'split(",") | map(tonumber)')"; fi; shift 2;;
      *) shift;;
    esac
  done
  jq --arg self "$self" --argjson handled "$handled" --argjson denylist "$DENYLIST_JSON" '
    map(select(
      (.user.type != "Bot")
      and ((.user.login | endswith("[bot]")) | not)
      and (.user.login != $self)
      and ((.user.login | ascii_downcase) as $l | ($denylist | map(ascii_downcase) | index($l)) == null)
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

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    filter) do_filter "$@";;
    -h|--help|help) usage;;
    *) usage; exit 2;;
  esac
}
main "$@"
