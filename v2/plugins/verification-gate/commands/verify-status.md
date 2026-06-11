---
description: Show verification-gate state — last edit, last verification, and whether a completion claim would currently pass
---

Report the verification-gate state for this session:

1. Find the state directory: `ls "${TMPDIR:-/tmp}/verification-gate/"` and use the entry matching the current session (newest if unsure).
2. Read `last_edit` and `last_verify` in it (epoch timestamps; either may be absent).
3. Report a three-line status:
   - Last edit: <timestamp or "none">
   - Last verification: <timestamp or "none">
   - Gate verdict: PASS if no edits yet, or verification is newer than the last edit; otherwise FAIL — a completion claim would be flagged (mode: $VGATE_MODE, default warn).
4. If the verdict is FAIL, name the fix: run the project's verification command, then re-check.
