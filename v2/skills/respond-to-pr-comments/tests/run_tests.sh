#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../scripts/pr_comments.sh"
FIX="$HERE/fixtures"
PASS=0; FAIL=0

assert_eq() { # desc expected actual
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "ok - $1";
  else FAIL=$((FAIL+1)); echo "NOT OK - $1"; printf '  expected: %s\n  actual:   %s\n' "$2" "$3"; fi
}

# Unknown subcommand exits non-zero and prints usage.
out="$(bash "$SCRIPT" bogus 2>&1)"; rc=$?
assert_eq "unknown subcommand exits non-zero" "nonzero" "$([ $rc -ne 0 ] && echo nonzero || echo zero)"
assert_eq "unknown subcommand prints usage" "yes" "$(echo "$out" | grep -q 'Usage:' && echo yes || echo no)"

# --- Task 2: human filter ---
authors() { jq -r '[.[].author] | sort | join(",")'; }
out="$(bash "$SCRIPT" filter --self me --handled "" < "$FIX/mixed.json" | authors)"
assert_eq "human filter keeps only real non-self humans" "alice,bob" "$out"

# --- Task 3: new (handled-id) filter ---
out="$(bash "$SCRIPT" filter --self me --handled "7" < "$FIX/mixed.json" | authors)"
assert_eq "handled filter drops id 7 (bob)" "alice" "$out"

# --- Task 4: normalization shape ---
norm="$(bash "$SCRIPT" filter --self me --handled "" < "$FIX/mixed.json")"
bob="$(printf '%s' "$norm" | jq -r '.[] | select(.author=="bob") | "\(.type)|\(.path)|\(.line)|\(.url)|\(.diff_hunk)"')"
assert_eq "inline comment normalized with code fields" "inline|a.py|10|u7|@@ -1 +1 @@" "$bob"
alice="$(printf '%s' "$norm" | jq -r '.[] | select(.author=="alice") | "\(.type)|\(.path)|\(.line)"')"
assert_eq "conversation comment has null code fields" "conversation|null|null" "$alice"
keys="$(printf '%s' "$norm" | jq -r '.[0] | keys_unsorted | join(",")')"
assert_eq "normalized keys exact" "id,type,author,created_at,body,url,path,line,diff_hunk,in_reply_to_id" "$keys"

# --- Task 5: fetch orchestration via fake gh ---
chmod +x "$HERE/fake_gh.sh"
fetched="$(GH_BIN="$HERE/fake_gh.sh" bash "$SCRIPT" fetch 123)"
out="$(printf '%s' "$fetched" | authors)"
assert_eq "fetch merges paginated pages + 3 types, drops Copilot + empty-body review" "alice,bob,carol,erin" "$out"
carol_ts="$(printf '%s' "$fetched" | jq -r '.[] | select(.author=="carol") | .created_at')"
assert_eq "review created_at falls back to submitted_at" "2026-06-19T10:07:00Z" "$carol_ts"

# --- Task 6: reply + skip + watermark ---
TMPWM="$(mktemp -d)"
printf 'reply body\n' > "$TMPWM/body.txt"
LOG="$TMPWM/posts.log"; : > "$LOG"

PR_WATERMARK_DIR="$TMPWM" FAKE_GH_LOG="$LOG" GH_BIN="$HERE/fake_gh.sh" \
  bash "$SCRIPT" reply 7 inline "$TMPWM/body.txt"
assert_eq "reply inline hits replies endpoint" "yes" "$(grep -q 'pulls/123/comments/7/replies' "$LOG" && echo yes || echo no)"
assert_eq "reply records id 7 in watermark" "[7]" "$(jq -c '.handled_ids' "$TMPWM/123.json")"

PR_WATERMARK_DIR="$TMPWM" FAKE_GH_LOG="$LOG" GH_BIN="$HERE/fake_gh.sh" \
  bash "$SCRIPT" reply 5 review "$TMPWM/body.txt"
assert_eq "reply review hits issues/comments endpoint" "yes" "$(grep -q 'issues/123/comments' "$LOG" && echo yes || echo no)"
assert_eq "reply review records id 5 in watermark" "[5,7]" "$(jq -c '.handled_ids' "$TMPWM/123.json")"

POSTS_BEFORE="$(grep -c '' "$LOG")"
PR_WATERMARK_DIR="$TMPWM" FAKE_GH_LOG="$LOG" GH_BIN="$HERE/fake_gh.sh" \
  bash "$SCRIPT" skip 9
POSTS_AFTER="$(grep -c '' "$LOG")"
assert_eq "skip posts nothing" "$POSTS_BEFORE" "$POSTS_AFTER"
assert_eq "skip records id 9 in watermark (sorted unique)" "[5,7,9]" "$(jq -c '.handled_ids' "$TMPWM/123.json")"
rm -rf "$TMPWM"

# --- conversation reply routing (own temp dir/log so the grep is meaningful) ---
TMPC="$(mktemp -d)"; printf 'thanks\n' > "$TMPC/body.txt"; CLOG="$TMPC/posts.log"; : > "$CLOG"
PR_WATERMARK_DIR="$TMPC" FAKE_GH_LOG="$CLOG" GH_BIN="$HERE/fake_gh.sh" \
  bash "$SCRIPT" reply 1 conversation "$TMPC/body.txt"
assert_eq "reply conversation hits issues/comments endpoint" "yes" "$(grep -q 'issues/123/comments' "$CLOG" && echo yes || echo no)"
assert_eq "reply conversation records id 1" "[1]" "$(jq -c '.handled_ids' "$TMPC/123.json")"
rm -rf "$TMPC"

# --- full dedup cycle: fetch, handle every returned id, re-fetch must be empty ---
TMPD="$(mktemp -d)"
ids="$(PR_WATERMARK_DIR="$TMPD" GH_BIN="$HERE/fake_gh.sh" bash "$SCRIPT" fetch 123 | jq -r '.[].id')"
for id in $ids; do
  PR_WATERMARK_DIR="$TMPD" GH_BIN="$HERE/fake_gh.sh" bash "$SCRIPT" skip "$id"
done
again="$(PR_WATERMARK_DIR="$TMPD" GH_BIN="$HERE/fake_gh.sh" bash "$SCRIPT" fetch 123 | jq -c '.')"
assert_eq "re-fetch after handling all returns empty" "[]" "$again"
rm -rf "$TMPD"

echo "----"; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
