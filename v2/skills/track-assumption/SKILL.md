---
name: track-assumption
description: Use when you make a decision based on something unverified — registers the assumption with a test condition and expiry to ~/.claude/assumptions.jsonl so it cannot silently rot before v1 finishing-a-development-branch or deploy.
author: Donal Moloney
tier: v2
supports: [brainstorming, executing-plans, finishing-a-development-branch]
type: support
chains-to: verification-before-completion
---

## Not this skill if
- The fact is already verified and evidence exists — record it as an evidence block (per v1 verification-before-completion) instead
- The assumption is trivial and will be confirmed within the same task
- You are reviewing existing assumptions — record resolved decisions with v2 **write-adr**

# track-assumption — register unverified assumptions before they rot

## Purpose

An assumption made during planning or implementation is a debt. It may be correct today and wrong next week. Without an explicit record, it silently becomes a load-bearing belief that nobody questions until a production incident.

This skill does two things: (1) writes each assumption into a structured block so the user sees it, and (2) appends a JSON line to `~/.claude/assumptions.jsonl` so a CHECK step can surface expired or unverified entries before any v1 **finishing-a-development-branch** or deploy.

## Core rule

> **Rule:** Do not proceed past an assumption without writing it down. An assumption with no test condition and no expiry is an undocumented risk.

## REGISTER step — emit and append

When you make an unverified assumption, stop and:

1. Emit an assumption block in the response
2. Append a JSON line to `~/.claude/assumptions.jsonl`

### Assumption block format

````
```assumption
id: <slug — lowercase-kebab, unique in this session>
stated: <the assumption in one sentence — present tense, declarative>
why: <why this assumption is being made instead of verifying now>
test: <the specific check that would confirm or refute it — a command, query, or observable>
expiry: <YYYY-MM-DD or condition — "before merge", "before deploy", "by end of sprint">
owner: <the user or agent responsible for running the test>
status: open
```
````

### Append to JSONL

```bash
SESSION="${CLAUDE_SESSION_ID:-unknown}"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
mkdir -p ~/.claude
cat >> ~/.claude/assumptions.jsonl <<EOF
{"id":"<id>","assumption":"<stated>","test_condition":"<test>","expires":"<expiry>","session_id":"${SESSION}","ts":"${TS}","status":"open"}
EOF
```

Each JSON field maps directly from the assumption block above. Keep values on one line — JSONL is one JSON object per line.

## Field rules

**stated** — One sentence. Declarative, not hedged. "The users table has fewer than 10 000 rows" not "we think the users table might be small".

**test_condition** — Specific enough that a different engineer could run it without asking. A `SELECT COUNT(*)`, a `curl`, a failing test file — not "check the database".

**expires** — Hard date (`YYYY-MM-DD`) or merge-gate condition (`"before merge"`, `"before deploy"`). If neither is possible, write `"MUST VERIFY BEFORE PROCEED"` and stop until it is resolved.

**owner** — Named individual or `"agent"`. Unowned assumptions expire immediately.

## CHECK step — scan before finishing-a-development-branch or deploy

Before v1 **verification-before-completion** or v1 **finishing-a-development-branch** runs, scan `~/.claude/assumptions.jsonl` for open entries that are past their expiry or were never verified:

```bash
python3 - <<'PYEOF'
import json, sys, os
from datetime import date

log_path = os.path.expanduser("~/.claude/assumptions.jsonl")
if not os.path.exists(log_path):
    print("assumption check: no log found — clean")
    sys.exit(0)

today = date.today().isoformat()
problems = []
with open(log_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        e = json.loads(line)
        if e.get("status") == "open":
            exp = e.get("expires", "")
            # Flag hard-date expiries that have passed
            if exp and exp <= today and not any(exp.startswith(k) for k in ("before", "by", "MUST")):
                problems.append(e)
            # Flag MUST VERIFY entries immediately
            if "MUST VERIFY" in exp:
                problems.append(e)

if problems:
    print("ASSUMPTION BLOCKER — open entries require resolution before proceeding:")
    for p in problems:
        print(f"  [{p['id']}] expires={p['expires']} | test: {p['test_condition']}")
    sys.exit(1)
else:
    print("assumption check: clean")
PYEOF
```

An open assumption past its expiry is a completion blocker. Each must be:

- **Confirmed** — test was run, evidence recorded; append a new line with `"status":"confirmed"` and the same `id`
- **Refuted** — test was run, assumption was wrong, work adjusted; append `"status":"refuted"`
- **Escalated** — still cannot be tested; surface to user before claiming done

### Resolve an assumption

```bash
# Append a resolution entry (last status entry per id wins)
SESSION="${CLAUDE_SESSION_ID:-unknown}"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat >> ~/.claude/assumptions.jsonl <<EOF
{"id":"users-row-count","status":"confirmed","evidence":"SELECT COUNT(*) FROM users returned 4212","ts":"${TS}","session_id":"${SESSION}"}
EOF
```

## Useful jq one-liners

```bash
# All open assumptions
jq 'select(.status == "open")' ~/.claude/assumptions.jsonl

# Past-expiry open entries (naive ISO date compare)
TODAY=$(date -u +%Y-%m-%d)
jq --arg t "$TODAY" 'select(.status == "open" and (.expires // "") <= $t)' \
  ~/.claude/assumptions.jsonl

# Count by status
jq -s 'group_by(.status) | map({status: .[0].status, count: length})' \
  ~/.claude/assumptions.jsonl
```

## Cheat sheet

| Step | Action |
|------|--------|
| Assumption made | Emit assumption block; run REGISTER append command |
| Before v1 finishing-a-development-branch | Run CHECK step; resolve any blockers |
| Assumption confirmed | Append entry with `"status":"confirmed"` and `"evidence":"..."` |
| Assumption refuted | Append `"status":"refuted"`; adjust work to account for wrong assumption |
| CHECK is clean | Proceed to v1 **verification-before-completion** |

## Failure modes

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| Assumption discovered in production | Not registered at time of decision | Run REGISTER step in the moment, not retrospectively |
| Log grows without being cleared | Expiry is set to "someday" | Require a date or merge-gate condition |
| Test condition is vague | "Check the database" is not a test | Rewrite as a specific command or observable |
| Owner is absent | Left blank | Assign a named individual or `"agent"` |
| CHECK step is skipped | Habit | Wire into the v1 **verification-before-completion** invocation |

## Integration

- v2 **write-adr** — resolved assumptions graduate to decision records
- v1 **verification-before-completion** — runs CHECK step before any completion claim
- an uncleared past-expiry assumption blocks the completion evidence block (v1 verification-before-completion)
