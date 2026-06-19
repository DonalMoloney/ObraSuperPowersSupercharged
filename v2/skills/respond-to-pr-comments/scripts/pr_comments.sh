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

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    -h|--help|help) usage;;
    *) usage; exit 2;;
  esac
}
main "$@"
