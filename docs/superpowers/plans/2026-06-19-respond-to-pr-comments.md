# respond-to-pr-comments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a v2 skill that fetches *new* *human* PR comments (excluding Copilot/bots/yourself across inline, conversation, and review-summary types), drafts replies for approval, and posts only what is approved — runnable on demand or wrapped with `/loop`.

**Architecture:** A single helper script (`pr_comments.sh`, bash + `gh` + `jq`) owns the deterministic, testable parts — context resolution, the human/new filter, normalization, watermark state, and posting. `SKILL.md` owns the judgment: triage via `receiving-code-review`, drafting, the approve/edit/skip/defer gate. The filter is a pure subcommand (`filter`) tested directly with fixtures; the `gh`-calling glue (`fetch`/`reply`) is tested via a fake `gh` injected through the `GH_BIN` env seam.

**Tech Stack:** bash (`#!/usr/bin/env bash`, must work on macOS bash 3.2), `gh` CLI 2.91, `jq` 1.7, plain-bash test harness (no bats).

---

## File Structure

- Create: `v2/skills/respond-to-pr-comments/SKILL.md` — workflow + frontmatter (Task 7)
- Create: `v2/skills/respond-to-pr-comments/scripts/pr_comments.sh` — the helper (Tasks 1–6)
- Create: `v2/skills/respond-to-pr-comments/tests/run_tests.sh` — bash test harness (Tasks 1–6)
- Create: `v2/skills/respond-to-pr-comments/tests/fake_gh.sh` — `gh` stand-in for I/O tests (Task 5)
- Create: `v2/skills/respond-to-pr-comments/tests/fixtures/*.json` — canned JSON (Tasks 2,5)
- Modify: `v2/README.md` — add row to the Current skills table (Task 8)

**Key interfaces (locked here, used throughout):**

- `pr_comments.sh filter --self <login> --handled <csv>` — reads a JSON array of **tagged** comments on stdin (each object carries `_type` ∈ `inline|conversation|review` plus raw `gh` fields), prints a JSON array of normalized survivors. Pure; no I/O.
- Normalized object shape: `{id, type, author, created_at, body, url, path, line, diff_hunk, in_reply_to_id}` (inline-only fields are `null` for other types).
- `pr_comments.sh fetch [PR]` — resolves context, pulls the three comment types, tags them, pipes through `filter`. Honors `GH_BIN` (default `gh`).
- `pr_comments.sh reply <id> <type> <body-file>` — posts one reply, then records `<id>` in the watermark.
- `pr_comments.sh skip <id>` — records `<id>` as handled without posting (for declined drafts).
- Env seams: `GH_BIN` (mock `gh`), `PR_WATERMARK_DIR` (override watermark location).
- Watermark file: `${PR_WATERMARK_DIR:-$(git rev-parse --git-dir)/pr-comment-watermarks}/<pr>.json`, shape `{"pr":N,"last_poll":<iso|null>,"handled_ids":[...]}`.
- Denylist constant (case-insensitive): `copilot`, `github-copilot[bot]`, `copilot-pull-request-reviewer[bot]`, `coderabbitai[bot]`, `github-actions[bot]`.

> Note vs spec: the spec described `--skip <id>` as a flag on `reply`; this plan implements it as a sibling `skip` subcommand (cleaner dispatch, same behavior). The skill calls `skip`.

---

### Task 1: Script skeleton + test harness

**Files:**
- Create: `v2/skills/respond-to-pr-comments/scripts/pr_comments.sh`
- Create: `v2/skills/respond-to-pr-comments/tests/run_tests.sh`

- [ ] **Step 1: Write the failing test**

Create `v2/skills/respond-to-pr-comments/tests/run_tests.sh`:

```bash
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

echo "----"; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: FAIL — `pr_comments.sh` does not exist (`No such file or directory`), assertions report NOT OK.

- [ ] **Step 3: Write minimal implementation**

Create `v2/skills/respond-to-pr-comments/scripts/pr_comments.sh`:

```bash
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: PASS — `passed=2 failed=0`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add v2/skills/respond-to-pr-comments/scripts/pr_comments.sh v2/skills/respond-to-pr-comments/tests/run_tests.sh
git commit -m "feat(respond-to-pr-comments): script skeleton + test harness"
```

---

### Task 2: `filter` — human filtering

Drop bots (`user.type=="Bot"`), `[bot]`-suffix logins, your own login, and the denylist (case-insensitive, catches `Copilot` posting as a `User`).

**Files:**
- Modify: `v2/skills/respond-to-pr-comments/scripts/pr_comments.sh`
- Create: `v2/skills/respond-to-pr-comments/tests/fixtures/mixed.json`
- Modify: `v2/skills/respond-to-pr-comments/tests/run_tests.sh`

- [ ] **Step 1: Write the failing test**

Create `v2/skills/respond-to-pr-comments/tests/fixtures/mixed.json`:

```json
[
  {"_type":"conversation","id":1,"user":{"login":"alice","type":"User"},"body":"hi","created_at":"2026-06-19T10:00:00Z","html_url":"u1"},
  {"_type":"conversation","id":2,"user":{"login":"dependabot[bot]","type":"Bot"},"body":"bump","created_at":"2026-06-19T10:01:00Z","html_url":"u2"},
  {"_type":"review","id":3,"user":{"login":"some-bot[bot]","type":"User"},"body":"lgtm","submitted_at":"2026-06-19T10:02:00Z","html_url":"u3"},
  {"_type":"conversation","id":4,"user":{"login":"me","type":"User"},"body":"mine","created_at":"2026-06-19T10:03:00Z","html_url":"u4"},
  {"_type":"review","id":5,"user":{"login":"Copilot","type":"User"},"body":"nit","submitted_at":"2026-06-19T10:04:00Z","html_url":"u5"},
  {"_type":"conversation","id":6,"user":{"login":"coderabbitai[bot]","type":"Bot"},"body":"x","created_at":"2026-06-19T10:05:00Z","html_url":"u6"},
  {"_type":"inline","id":7,"user":{"login":"bob","type":"User"},"body":"fix this","created_at":"2026-06-19T10:06:00Z","html_url":"u7","path":"a.py","line":10,"diff_hunk":"@@ -1 +1 @@","in_reply_to_id":null}
]
```

Append to `run_tests.sh` (before the final `echo "----"` summary block):

```bash
# --- Task 2: human filter ---
authors() { jq -r '[.[].author] | sort | join(",")'; }
out="$(bash "$SCRIPT" filter --self me --handled "" < "$FIX/mixed.json" | authors)"
assert_eq "human filter keeps only real non-self humans" "alice,bob" "$out"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: FAIL — `filter` subcommand falls through to `usage; exit 2`, so output is empty; assertion shows `actual: ` (empty).

- [ ] **Step 3: Write minimal implementation**

In `pr_comments.sh`, add the `do_filter` function above `main`, and add a `filter` case to the dispatcher:

```bash
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
  '
}
```

Update `main`'s `case` to add (before the `-h|--help` line):

```bash
    filter) do_filter "$@";;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: PASS — new line `ok - human filter keeps only real non-self humans`, `failed=0`.

- [ ] **Step 5: Commit**

```bash
git add v2/skills/respond-to-pr-comments/scripts/pr_comments.sh v2/skills/respond-to-pr-comments/tests/run_tests.sh v2/skills/respond-to-pr-comments/tests/fixtures/mixed.json
git commit -m "feat(respond-to-pr-comments): human filter (exclude bots/Copilot/self)"
```

---

### Task 3: `filter` — drop already-handled IDs

**Files:**
- Modify: `v2/skills/respond-to-pr-comments/scripts/pr_comments.sh`
- Modify: `v2/skills/respond-to-pr-comments/tests/run_tests.sh`

- [ ] **Step 1: Write the failing test**

Append to `run_tests.sh` (before the summary block):

```bash
# --- Task 3: new (handled-id) filter ---
out="$(bash "$SCRIPT" filter --self me --handled "7" < "$FIX/mixed.json" | authors)"
assert_eq "handled filter drops id 7 (bob)" "alice" "$out"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: FAIL — `do_filter` ignores `$handled`; output is still `alice,bob`. Assertion shows `actual: alice,bob`.

- [ ] **Step 3: Write minimal implementation**

In `do_filter`, add one clause to the `select(...)` (after the denylist clause, still inside the same `select`):

```bash
      and ((.id) as $i | ($handled | index($i)) == null)
```

The `select(...)` now reads:

```bash
    map(select(
      (.user.type != "Bot")
      and ((.user.login | endswith("[bot]")) | not)
      and (.user.login != $self)
      and ((.user.login | ascii_downcase) as $l | ($denylist | map(ascii_downcase) | index($l)) == null)
      and ((.id) as $i | ($handled | index($i)) == null)
    ))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: PASS — `ok - handled filter drops id 7 (bob)`; the Task 2 assertion still passes.

- [ ] **Step 5: Commit**

```bash
git add v2/skills/respond-to-pr-comments/scripts/pr_comments.sh v2/skills/respond-to-pr-comments/tests/run_tests.sh
git commit -m "feat(respond-to-pr-comments): drop already-handled comment ids"
```

---

### Task 4: `filter` — normalize output shape

**Files:**
- Modify: `v2/skills/respond-to-pr-comments/scripts/pr_comments.sh`
- Modify: `v2/skills/respond-to-pr-comments/tests/run_tests.sh`

- [ ] **Step 1: Write the failing test**

Append to `run_tests.sh` (before the summary block):

```bash
# --- Task 4: normalization shape ---
norm="$(bash "$SCRIPT" filter --self me --handled "" < "$FIX/mixed.json")"
bob="$(printf '%s' "$norm" | jq -r '.[] | select(.author=="bob") | "\(.type)|\(.path)|\(.line)|\(.url)|\(.diff_hunk)"')"
assert_eq "inline comment normalized with code fields" "inline|a.py|10|u7|@@ -1 +1 @@" "$bob"
alice="$(printf '%s' "$norm" | jq -r '.[] | select(.author=="alice") | "\(.type)|\(.path)|\(.line)"')"
assert_eq "conversation comment has null code fields" "conversation|null|null" "$alice"
keys="$(printf '%s' "$norm" | jq -r '.[0] | keys_unsorted | join(",")')"
assert_eq "normalized keys exact" "id,type,author,created_at,body,url,path,line,diff_hunk,in_reply_to_id" "$keys"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: FAIL — `do_filter` still emits raw objects (keys are `_type,id,user,body,...`), so all three assertions report NOT OK.

- [ ] **Step 3: Write minimal implementation**

In `do_filter`, append a normalization `map(...)` to the end of the `jq` program (after the `select` block, piped):

```bash
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: PASS — all three new assertions `ok`; earlier filter assertions still pass (`authors` reads `.author`, which now exists).

- [ ] **Step 5: Commit**

```bash
git add v2/skills/respond-to-pr-comments/scripts/pr_comments.sh v2/skills/respond-to-pr-comments/tests/run_tests.sh
git commit -m "feat(respond-to-pr-comments): normalize filter output shape"
```

---

### Task 5: `fetch` — gh orchestration (via fake gh)

Pull the three comment types, tag each with `_type`, concat, pipe through `filter`. Tested with a fake `gh` injected via `GH_BIN`.

**Files:**
- Modify: `v2/skills/respond-to-pr-comments/scripts/pr_comments.sh`
- Create: `v2/skills/respond-to-pr-comments/tests/fake_gh.sh`
- Create: `v2/skills/respond-to-pr-comments/tests/fixtures/inline.json`
- Create: `v2/skills/respond-to-pr-comments/tests/fixtures/conv.json`
- Create: `v2/skills/respond-to-pr-comments/tests/fixtures/reviews.json`
- Modify: `v2/skills/respond-to-pr-comments/tests/run_tests.sh`

- [ ] **Step 1: Write the failing test**

Create `v2/skills/respond-to-pr-comments/tests/fixtures/inline.json`:

```json
[
  {"id":7,"user":{"login":"bob","type":"User"},"body":"fix this","created_at":"2026-06-19T10:06:00Z","html_url":"u7","path":"a.py","line":10,"diff_hunk":"@@ -1 +1 @@","in_reply_to_id":null}
]
```

Create `v2/skills/respond-to-pr-comments/tests/fixtures/conv.json`:

```json
[
  {"id":1,"user":{"login":"alice","type":"User"},"body":"hi","created_at":"2026-06-19T10:00:00Z","html_url":"u1"},
  {"id":4,"user":{"login":"me","type":"User"},"body":"mine","created_at":"2026-06-19T10:03:00Z","html_url":"u4"}
]
```

Create `v2/skills/respond-to-pr-comments/tests/fixtures/reviews.json`:

```json
[
  {"id":5,"user":{"login":"Copilot","type":"User"},"body":"nit","submitted_at":"2026-06-19T10:04:00Z","html_url":"u5"},
  {"id":8,"user":{"login":"carol","type":"User"},"body":"","submitted_at":"2026-06-19T10:07:00Z","html_url":"u8"}
]
```

Create `v2/skills/respond-to-pr-comments/tests/fake_gh.sh`:

```bash
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
```

Append to `run_tests.sh` (before the summary block):

```bash
# --- Task 5: fetch orchestration via fake gh ---
chmod +x "$HERE/fake_gh.sh"
out="$(GH_BIN="$HERE/fake_gh.sh" bash "$SCRIPT" fetch 123 | authors)"
assert_eq "fetch returns only new humans across all 3 types" "alice,bob,carol" "$out"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: FAIL — `fetch` subcommand not implemented, falls through to `usage; exit 2`; output empty.

- [ ] **Step 3: Write minimal implementation**

In `pr_comments.sh`, add context-resolution helpers and `do_fetch` above `main`:

```bash
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
```

Add to `main`'s `case` (before `-h|--help`):

```bash
    fetch) do_fetch "$@";;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: PASS — `ok - fetch returns only new humans across all 3 types`. (Copilot review id 5 dropped by denylist; carol's empty-body review id 8... note carol has empty body so is dropped as a review — see Step 5 fix.)

- [ ] **Step 5: Fix the empty-review expectation**

The reviews fixture gives `carol` an **empty body**, which `do_fetch` filters out (review summaries with no body are noise). So the correct expectation is `alice,bob` — carol must NOT appear. Update the Task 5 assertion in `run_tests.sh`:

```bash
out="$(GH_BIN="$HERE/fake_gh.sh" bash "$SCRIPT" fetch 123 | authors)"
assert_eq "fetch keeps new humans, drops Copilot + empty-body review" "alice,bob" "$out"
```

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: PASS — `alice,bob`. This proves the empty-body review filter and the Copilot-denylist both fire in the real `fetch` path.

- [ ] **Step 6: Commit**

```bash
git add v2/skills/respond-to-pr-comments/scripts/pr_comments.sh v2/skills/respond-to-pr-comments/tests/fake_gh.sh v2/skills/respond-to-pr-comments/tests/fixtures/inline.json v2/skills/respond-to-pr-comments/tests/fixtures/conv.json v2/skills/respond-to-pr-comments/tests/fixtures/reviews.json v2/skills/respond-to-pr-comments/tests/run_tests.sh
git commit -m "feat(respond-to-pr-comments): fetch orchestration across all comment types"
```

---

### Task 6: `reply` + `skip` — post and record watermark

**Files:**
- Modify: `v2/skills/respond-to-pr-comments/scripts/pr_comments.sh`
- Modify: `v2/skills/respond-to-pr-comments/tests/run_tests.sh`

- [ ] **Step 1: Write the failing test**

Append to `run_tests.sh` (before the summary block):

```bash
# --- Task 6: reply + skip + watermark ---
TMPWM="$(mktemp -d)"
printf 'reply body\n' > "$TMPWM/body.txt"
LOG="$TMPWM/posts.log"

PR_WATERMARK_DIR="$TMPWM" FAKE_GH_LOG="$LOG" GH_BIN="$HERE/fake_gh.sh" \
  bash "$SCRIPT" reply 7 inline "$TMPWM/body.txt"
assert_eq "reply inline hits replies endpoint" "yes" "$(grep -q 'pulls/123/comments/7/replies' "$LOG" && echo yes || echo no)"
assert_eq "reply records id 7 in watermark" "[7]" "$(jq -c '.handled_ids' "$TMPWM/123.json")"

PR_WATERMARK_DIR="$TMPWM" FAKE_GH_LOG="$LOG" GH_BIN="$HERE/fake_gh.sh" \
  bash "$SCRIPT" reply 5 review "$TMPWM/body.txt"
assert_eq "reply review hits issues/comments endpoint" "yes" "$(grep -q 'issues/123/comments' "$LOG" && echo yes || echo no)"

POSTS_BEFORE="$(wc -l < "$LOG")"
PR_WATERMARK_DIR="$TMPWM" FAKE_GH_LOG="$LOG" GH_BIN="$HERE/fake_gh.sh" \
  bash "$SCRIPT" skip 9
POSTS_AFTER="$(wc -l < "$LOG")"
assert_eq "skip posts nothing" "$POSTS_BEFORE" "$POSTS_AFTER"
assert_eq "skip records id 9 in watermark" "[5,7,9]" "$(jq -c '.handled_ids' "$TMPWM/123.json")"
rm -rf "$TMPWM"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: FAIL — `reply`/`skip` not implemented (`usage; exit 2`); watermark file `123.json` never created, `jq` errors / assertions NOT OK.

- [ ] **Step 3: Write minimal implementation**

In `pr_comments.sh`, add `add_handled`, `do_reply`, `do_skip` above `main`:

```bash
add_handled() { # args: pr id
  local dir f tmp; dir="$(watermark_dir)"; f="$(watermark_file "$1")"
  mkdir -p "$dir"
  if [ ! -f "$f" ]; then printf '{"pr":%s,"last_poll":null,"handled_ids":[]}\n' "$1" > "$f"; fi
  tmp="$(mktemp)"
  jq --argjson id "$2" '.handled_ids = ((.handled_ids + [$id]) | unique) | .last_poll = (now | todate)' "$f" > "$tmp" && mv "$tmp" "$f"
}

do_reply() {
  local id="$1" type="$2" bodyfile="$3" pr repo o r body
  pr="$(resolve_pr "")"; repo="$(resolve_repo)"; o="${repo%%/*}"; r="${repo##*/}"
  body="$(cat "$bodyfile")"
  case "$type" in
    inline)               "$GH_BIN" api --method POST "/repos/$o/$r/pulls/$pr/comments/$id/replies" -f "body=$body" >/dev/null;;
    conversation|review)  "$GH_BIN" api --method POST "/repos/$o/$r/issues/$pr/comments" -f "body=$body" >/dev/null;;
    *) echo "unknown comment type: $type" >&2; exit 1;;
  esac
  add_handled "$pr" "$id"
}

do_skip() { local id="$1" pr; pr="$(resolve_pr "")"; add_handled "$pr" "$id"; }
```

Add to `main`'s `case` (before `-h|--help`):

```bash
    reply) do_reply "$@";;
    skip) do_skip "$@";;
```

Note: `unique` sorts numerically, so handled_ids stays sorted ascending — matching the `[5,7,9]` expectation.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: PASS — all reply/skip assertions `ok`; `failed=0` overall.

- [ ] **Step 5: Commit**

```bash
git add v2/skills/respond-to-pr-comments/scripts/pr_comments.sh v2/skills/respond-to-pr-comments/tests/run_tests.sh
git commit -m "feat(respond-to-pr-comments): reply + skip with watermark recording"
```

---

### Task 7: SKILL.md (workflow + frontmatter)

**Files:**
- Create: `v2/skills/respond-to-pr-comments/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

Create `v2/skills/respond-to-pr-comments/SKILL.md` with this exact content:

````markdown
---
name: respond-to-pr-comments
description: Use when a PR has new reviewer comments you want to answer — fetches new human comments (excluding Copilot/bots/yourself), drafts replies for your approval, and posts only what you approve. Run on demand or wrap with /loop to watch.
author: Donal Moloney
tier: v2
supports: [receiving-code-review, requesting-code-review]
type: technique
chains-to: receiving-code-review
pairs-with: loop-until-green
---

## Not this skill if

- You already have the feedback in hand and just need to act on it — use `receiving-code-review` directly.
- You want to *request* a review — use `requesting-code-review` / `reviewer-lenses`.
- You want to auto-implement changes from comments without a human gate — out of scope; this skill drafts and posts replies only.

## Overview

Pull *new* *human* comments off a PR, draft replies, and post only what the user approves. The deterministic work (which comments are new and human) lives in `scripts/pr_comments.sh`; this skill owns the judgment (what to say back).

**Core principle:** nothing reaches GitHub without explicit approval. The watermark advances only for comments actually handled.

## Workflow

1. **Preflight.** Run `gh auth status`. Confirm a PR exists for the branch (`gh pr view --json number`). If unauthenticated or no PR, stop and ask the user to authenticate or pass a PR number — take no other action.

2. **Fetch new human comments:**

   ```bash
   bash scripts/pr_comments.sh fetch          # auto-detects PR from branch
   bash scripts/pr_comments.sh fetch 123      # explicit PR
   ```

   Output is a JSON array of `{id, type, author, created_at, body, url, path, line, diff_hunk, in_reply_to_id}`. If it is `[]`, report **"No new human comments since last check."** and stop. (This quiet no-op is what makes watch mode unobtrusive.)

3. **Triage** each comment using `receiving-code-review`: classify as question / change-request / nit / praise. For `inline` comments, read `path`, `line`, and `diff_hunk` for context; if `in_reply_to_id` is set, treat it as a reply within a thread and fetch the parent for context.

4. **Draft** one reply per comment. For change-requests, the reply acknowledges and states intent, and you *surface the proposed code change* — but do **not** edit code here. Implementing a change is a separate, explicit hand-off the user opts into (then follow `receiving-code-review` / TDD).

5. **Present all drafts together**, each tagged with author, type, and `url`. For each, the user chooses:
   - **approve** — post as drafted
   - **edit** — user revises, then post
   - **skip** — don't reply, but mark handled (won't resurface)
   - **defer** — leave untouched (resurfaces next run)

6. **Post** approved/edited replies, then record them:

   ```bash
   printf '%s' "$REPLY_BODY" > /tmp/reply.txt
   bash scripts/pr_comments.sh reply <id> <type> /tmp/reply.txt   # posts + records
   bash scripts/pr_comments.sh skip  <id>                         # mark handled, no post
   ```

   If a post fails (e.g. resolved/locked thread), report the error and do **not** mark that id handled; continue with the rest.

7. **Summarize** what was posted vs deferred.

## Watch mode

No extra machinery — wrap this skill with the existing `/loop` skill:

```
/loop 5m respond-to-pr-comments
```

Each tick re-runs the workflow; the watermark guarantees only genuinely new human comments surface, and the step-2 no-op keeps idle ticks silent.

## Human filter

`fetch` keeps a comment only if the author is a real person other than you: it drops `user.type == "Bot"`, `[bot]`-suffix logins, your own login, and an explicit denylist (`copilot`, `github-copilot[bot]`, `copilot-pull-request-reviewer[bot]`, `coderabbitai[bot]`, `github-actions[bot]`). Extend the denylist by editing `DENYLIST_JSON` at the top of the script.

## Verification

- Run the unit suite: `bash tests/run_tests.sh` → `failed=0`. Covers human filter (Copilot/bots/self dropped), handled-id dedup, output shape, full `fetch` across all three comment types, and `reply`/`skip` watermark recording (all via fixtures + a fake `gh`).
- Live check: run `fetch` against a real PR that has both a Copilot comment and a human comment → only the human appears; run again → `[]` (watermark dedup).
````

- [ ] **Step 2: Run the unit suite to confirm the script the skill references works**

Run: `bash v2/skills/respond-to-pr-comments/tests/run_tests.sh`
Expected: PASS — `failed=0` (no code changed; this confirms the SKILL.md commands match a green script).

- [ ] **Step 3: Audit the skill**

Dispatch the `skill-auditor` agent on `v2/skills/respond-to-pr-comments/`. Address any blocking findings it reports (read-only agent — it reports, you fix). Re-run until clean.

- [ ] **Step 4: Commit**

```bash
git add v2/skills/respond-to-pr-comments/SKILL.md
git commit -m "feat(respond-to-pr-comments): SKILL.md workflow + frontmatter"
```

---

### Task 8: Register in v2 README + live verification

**Files:**
- Modify: `v2/README.md`

- [ ] **Step 1: Add the skill to the Current skills table**

Edit `v2/README.md`: in the `## Current skills` table, add a row (place it after the `review-clarification-gate` row, since both support the review workflow):

```markdown
| `respond-to-pr-comments` | receiving-code-review, requesting-code-review |
```

- [ ] **Step 2: Live verification against a real PR**

Pick (or ask the user for) a real PR that has at least one human comment and, ideally, a Copilot/bot comment. From a clone on that PR's branch:

```bash
bash v2/skills/respond-to-pr-comments/scripts/pr_comments.sh fetch <PR>
```

Expected: a JSON array containing the human comment(s) and **no** Copilot/bot/self comments. Capture the output.

Then, after handling one comment (`reply` or `skip`), run `fetch` again:

Expected: the handled comment no longer appears (watermark dedup). If the PR has no remaining new human comments, output is `[]`.

> If no suitable live PR is available, record that the live check is pending and rely on the fixture-based `fetch` test (Task 5) as deterministic evidence; note this gap in the commit message.

- [ ] **Step 3: Final commit**

```bash
git add v2/README.md
git commit -m "docs(v2): register respond-to-pr-comments in skills table"
```

---

## Self-Review

**Spec coverage:**
- Draft-for-approval, no auto-post → Task 7 step 5 (approve/edit/skip/defer gate). ✓
- Local watermark, advances only when handled → Tasks 5 (`read_handled`), 6 (`add_handled` only in `reply`/`skip`). ✓
- Human filter excludes bots/[bot]/self/Copilot/CodeRabbit/CI → Task 2 + denylist constant. ✓
- All three comment types fetched, replies routed per type → Task 5 (`fetch`), Task 6 (`reply` endpoints). ✓
- Watch via `/loop`, quiet no-op → Task 7 (watch mode + step 2). ✓
- Approach A split (script deterministic, skill judgment) → Tasks 1–6 script, Task 7 skill. ✓
- Error handling (not authed / no PR / post failure) → Task 7 steps 1, 6. ✓
- Testing: fixture unit tests + live verification + skill-auditor → Tasks 1–6, 7 step 3, 8 step 2. ✓
- Register in v2/README.md (CLAUDE.md requirement) → Task 8. ✓

**Placeholder scan:** No TBD/TODO; every code step shows complete code; every test step gives the exact command and expected result. ✓

**Type/interface consistency:** `do_filter`/`do_fetch`/`do_reply`/`do_skip`, `read_handled`/`add_handled`/`watermark_file`/`watermark_dir`, env seams `GH_BIN`/`PR_WATERMARK_DIR`/`FAKE_GH_LOG`, normalized key order, and the `inline|conversation|review` type vocabulary are used identically across the script, tests, and SKILL.md. ✓
