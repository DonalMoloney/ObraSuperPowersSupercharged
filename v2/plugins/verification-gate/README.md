# verification-gate (v2 plugin)

Harness enforcement of v1 **verification-before-completion**: a Stop hook flags
success claims ("all tests pass", "fixed", "done") made when no verification
command has run since the last file edit. A PostToolUse hook keeps the
edit/verify timestamps. Spec: `docs/superpowers/specs/2026-06-10-v2-candidates/01-verification-gate.md`.

tier: v2 · supports: verification-before-completion, test-driven-development · pairs-with: v2 loop-until-green

## Components

| Part | Role |
|---|---|
| `hooks/track-verification.sh` | PostToolUse (Bash/Edit/Write): timestamps edits and verify commands per session |
| `hooks/stop-gate.sh` | Stop: compares timestamps, scans last assistant message for claims, warns or blocks |
| `commands/verify-status.md` | `/verify-status`: prints gate state and verdict |

## Configuration (environment variables)

| Var | Default | Meaning |
|---|---|---|
| `VGATE_MODE` | `warn` | `warn` prints a note; `block` exits 2 (blocks the stop); `off` disables |
| `VGATE_VERIFY_COMMANDS` | common test runners | regex of Bash commands that count as verification |
| `VGATE_CLAIM_PATTERNS` | conservative claim set | regex of success-claim phrases that arm the gate |

Start in `warn` (the default) and tune the regexes on real sessions before
switching to `block` — false positives are the failure mode that gets
enforcement hooks uninstalled.

## Verification

PROVEN BY: the four hook tests in
`docs/superpowers/plans/2026-06-10-parallel-plan-executor-and-verification-gate.md`
— unverified claim blocks with exit 2, verified claim passes, non-claim message
passes, warn mode prints without blocking.
