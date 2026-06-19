#!/usr/bin/env bash
set -euo pipefail

GH_BIN="${GH_BIN:-gh}"
# "copilot" has no [bot] suffix so needs explicit listing; the rest are defense-in-depth.
# Already lower-cased so jq need not call ascii_downcase on the list per invocation.
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
      and ((.user.login | ascii_downcase) as $l | ($denylist | index($l)) == null)
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
resolve_self() {
  local s; s="$("$GH_BIN" api user | jq -r '.login')"
  if [ -z "$s" ] || [ "$s" = "null" ]; then echo "pr_comments: could not resolve GitHub login (run: gh auth status)" >&2; exit 1; fi
  printf '%s' "$s"
}

watermark_dir() { printf '%s' "${PR_WATERMARK_DIR:-$(git rev-parse --git-dir 2>/dev/null || printf '.')/pr-comment-watermarks}"; }
read_handled() { # arg: pr -> csv (possibly empty)
  local f; f="$(watermark_dir)/$1.json"
  if [ -f "$f" ]; then jq -r '.handled_ids | map(tostring) | join(",")' "$f"; else printf ''; fi
}

do_fetch() {
  local pr repo self inline conv reviews handled
  pr="$(resolve_pr "${1:-}")"
  repo="$(resolve_repo)"
  self="$(resolve_self)"
  inline="$("$GH_BIN" api --paginate "/repos/$repo/pulls/$pr/comments" | jq -s 'add | map(. + {_type:"inline"})')"
  conv="$("$GH_BIN" api --paginate "/repos/$repo/issues/$pr/comments" | jq -s 'add | map(. + {_type:"conversation"})')"
  reviews="$("$GH_BIN" api --paginate "/repos/$repo/pulls/$pr/reviews" | jq -s 'add | map(select(.body != null and .body != "") | . + {_type:"review"})')"
  handled="$(read_handled "$pr")"
  jq -n --argjson a "$inline" --argjson b "$conv" --argjson c "$reviews" '$a + $b + $c' \
    | do_filter --self "$self" --handled "$handled"
}

add_handled() { # args: pr id
  local dir f tmp; dir="$(watermark_dir)"; f="$dir/$1.json"
  mkdir -p "$dir"
  if [ ! -f "$f" ]; then printf '{"pr":%s,"last_poll":null,"handled_ids":[]}\n' "$1" > "$f"; fi
  tmp="$(mktemp)"
  jq --argjson id "$2" '.handled_ids = ((.handled_ids + [$id]) | unique) | .last_poll = (now | todate)' "$f" > "$tmp" && mv "$tmp" "$f"
}

do_reply() {
  local id="$1" type="$2" bodyfile="$3" pr repo body
  pr="$(resolve_pr "")"; repo="$(resolve_repo)"
  body="$(cat "$bodyfile")"
  case "$type" in
    inline)               "$GH_BIN" api --method POST "/repos/$repo/pulls/$pr/comments/$id/replies" -f "body=$body" >/dev/null;;
    conversation|review)  "$GH_BIN" api --method POST "/repos/$repo/issues/$pr/comments" -f "body=$body" >/dev/null;;
    *) echo "unknown comment type: $type" >&2; exit 1;;
  esac
  add_handled "$pr" "$id"
}

do_skip() { local id="$1" pr; pr="$(resolve_pr "")"; add_handled "$pr" "$id"; }

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    filter) do_filter "$@";;
    fetch) do_fetch "$@";;
    reply) do_reply "$@";;
    skip) do_skip "$@";;
    -h|--help|help) usage;;
    *) usage >&2; exit 2;;
  esac
}
main "$@"
