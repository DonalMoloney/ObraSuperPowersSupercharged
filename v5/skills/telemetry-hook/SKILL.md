---
name: telemetry-hook
description: Use when setting up skill invocation telemetry for the first time — installs the PostToolUse hook that logs every Skill tool call to ~/.claude/skill-telemetry.jsonl, which feeds analyse-routing and audit-dead-skills.
author: Donal Moloney
track: D
type: setup
chains-to: ~
---

## Not this skill if
- Telemetry is already installed and logging — check `tail -5 ~/.claude/skill-telemetry.jsonl`
- You only want to read the log without installing the hook — skip to the jq section below

# telemetry-hook — log every skill invocation

## Purpose

Without invocation data, routing decisions are guesses. This skill wires a PostToolUse hook that silently appends one JSONL line per `Skill` tool call to `~/.claude/skill-telemetry.jsonl`. Downstream skills (`analyse-routing`, `audit-dead-skills`, `adaptive-skill-router`) consume this log to surface dead skills, routing drift, and usage patterns.

## What the hook logs

Each invocation appends one line:

```json
{"skill":"brainstorming","task_hash":"d41d8cd98f00b204e9800998ecf8427e","ts":"2026-05-30T10:42:00Z","session_id":"abc123"}
```

| Field | Value |
|-------|-------|
| `skill` | The skill name passed to the `Skill` tool |
| `task_hash` | MD5 of the raw tool input — stable fingerprint for deduplication |
| `ts` | ISO 8601 UTC timestamp |
| `session_id` | `$CLAUDE_SESSION_ID` or `"unknown"` if unset |

The hook is **idempotent and silent** — it writes nothing to stdout on success, exits 0, and exits 0 (silently) when `FORGE_TELEMETRY` is not set.

## Install via hookify

Run:

```
/hookify
```

Then add the following PostToolUse entry to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "FORGE_TELEMETRY=1 /Users/donalmoloney/PycharmProjects/superpowers2/hooks/skill-telemetry.sh"
          }
        ]
      }
    ]
  }
}
```

Replace the path with the absolute path to `hooks/skill-telemetry.sh` in your clone of this repo.

### Manual install (no hookify)

Open `~/.claude/settings.json` and merge in the JSON block above. If a `PostToolUse` key already exists, add the new entry to the existing array.

### Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `FORGE_TELEMETRY` | `0` | Set to `1` to enable logging |
| `FORGE_TELEMETRY_LOG` | `~/.claude/skill-telemetry.jsonl` | Override log path |

## Verify installation

```bash
# Confirm hook script is executable
ls -l /path/to/hooks/skill-telemetry.sh

# Invoke any skill, then check the log
tail -3 ~/.claude/skill-telemetry.jsonl
```

Expected: one new JSONL line per skill invocation.

## Reading the log — jq one-liners

```bash
# Invocation count per skill, descending
jq -s 'group_by(.skill) | map({skill: .[0].skill, count: length}) | sort_by(-.count)' \
  ~/.claude/skill-telemetry.jsonl

# Skills not invoked in the last 30 days
CUTOFF=$(date -u -v-30d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u --date='30 days ago' +%Y-%m-%dT%H:%M:%SZ)
jq --arg c "$CUTOFF" 'select(.ts < $c) | .skill' ~/.claude/skill-telemetry.jsonl | sort -u

# Session breakdown — which skills were used in which sessions
jq -s 'group_by(.session_id) | map({session: .[0].session_id, skills: map(.skill) | unique})' \
  ~/.claude/skill-telemetry.jsonl

# Most recent invocation per skill
jq -s 'group_by(.skill) | map(max_by(.ts))' ~/.claude/skill-telemetry.jsonl
```

## Downstream skills that consume this log

| Skill | What it uses |
|-------|--------------|
| `analyse-routing` | Invocation counts and sequences to detect routing drift |
| `audit-dead-skills` | Skills present in `skills/` but absent from the log for > N days |
| `adaptive-skill-router` | Frequency data to rank skill candidates at routing time |

## Pitfalls

- **Hook not firing** — confirm `FORGE_TELEMETRY=1` is in the command string in `settings.json`, not just exported in your shell. Claude Code does not inherit your shell environment.
- **Log file missing** — the script creates the parent directory on first run. If the first run silently exits 0 with no file, check that `FORGE_TELEMETRY=1` is set in the hook command.
- **Duplicate entries** — each `Skill` tool call produces one entry; if the same skill fires twice in one turn, you get two lines. Use `task_hash` to deduplicate if needed.
- **Log rotation** — the log grows unboundedly. Rotate or archive old entries if it exceeds a few MB.
