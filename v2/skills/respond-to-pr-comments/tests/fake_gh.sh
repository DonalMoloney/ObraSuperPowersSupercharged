#!/usr/bin/env bash
# Fake `gh` for tests. Emits fixture JSON keyed on args. POSTs are recorded to $FAKE_GH_LOG.
set -euo pipefail
FIX="$(cd "$(dirname "$0")" && pwd)/fixtures"
ARGS="$*"

if printf '%s' "$ARGS" | grep -q -- '--method POST'; then
  printf '%s\n' "$ARGS" >> "${FAKE_GH_LOG:-/dev/null}"
  echo '{}'; exit 0
fi

case "$ARGS" in
  *"repo view"*)            echo '{"owner":{"login":"acme"},"name":"widgets"}';;
  *"pr view"*)              echo '{"number":123}';;
  "api user")               echo '{"login":"me"}';;
  *"pulls/123/comments"*)   cat "$FIX/inline.json";;
  *"issues/123/comments"*)  cat "$FIX/conv.json";;
  *"pulls/123/reviews"*)    cat "$FIX/reviews.json";;
  *) echo "fake_gh: unhandled args: $ARGS" >&2; exit 1;;
esac
