# verification-gate — v2 candidate spec

| Field | Value |
|---|---|
| Type | **plugin** (hooks + command) |
| Theme | Harness |
| Tier | v2 |
| Supports (v1) | verification-before-completion, test-driven-development |
| Composes with (v2) | loop-until-green |
| Status | built 2026-06-10 — see `v2/plugins/verification-gate/` |

## Problem

v1 `verification-before-completion` is a discipline skill: it asks the model to
run verification before claiming success. Nothing *enforces* it. When context is
long or the model is rationalizing ("the change is trivial"), the skill can be
skipped silently. Hooks run outside the model's discretion — they are the only
component that can make the discipline mechanical.

## What it does

Blocks completion claims ("done", "fixed", "passing", "all tests pass") at the
harness level until a verification command has actually executed in the current
session, and surfaces what evidence is missing.

## Parts

### `plugin.json`
Manifest declaring hooks and the command. Name `verification-gate`, tier noted in
description.

### `hooks/stop-gate.sh` (Stop hook)
- Fires when Claude ends its turn.
- Scans the final assistant message for success-claim patterns
  (`done|fixed|passing|complete|works now`, configurable regex list).
- Checks session state (a marker file written by the PostToolUse hook) for
  evidence that a verification command ran *after* the last file edit.
- If a claim is made without evidence: exit code 2 with message
  "Success claim without verification — run the test/build command first
  (v1 verification-before-completion)."

### `hooks/track-verification.sh` (PostToolUse hook on Bash)
- Records timestamp + command for any Bash call matching the project's
  verification commands (test runners, builds, linters — configurable list).
- Records timestamp of every Edit/Write so the stop-gate can enforce
  "verification ran AFTER the last edit", not just "ran at some point".

### `commands/verify-status.md` (slash command)
`/verify-status` — prints the current gate state: last edit time, last
verification command + result, whether a completion claim would currently pass.

### `config` (settings block)
- `claim_patterns`: regex list for what counts as a success claim.
- `verify_commands`: regex list for what counts as verification.
- `mode`: `block` | `warn` — the escape hatch. Defaults to `warn` for the first
  week of use; `block` once the patterns are tuned.

## Workflow

1. User installs plugin; defaults to `warn` mode.
2. Claude edits files → PostToolUse hook timestamps edits.
3. Claude runs tests → hook timestamps verification.
4. Claude claims "done" → Stop hook compares timestamps; passes or blocks with a
   pointer to v1 `verification-before-completion`.

## Interfaces

- **v1 verification-before-completion**: the hook's block message names the skill
  so the model invokes it rather than rephrasing the claim to dodge the regex.
- **v2 loop-until-green**: a block from this gate is a natural entry point into
  the loop.

## Success criteria

- A "done" claim with zero Bash verification since the last edit is blocked in
  `block` mode and warned in `warn` mode.
- False-positive rate low enough that the user keeps `block` mode on (measure:
  no more than ~1 wrongful block per working day before tuning).
- `/verify-status` accurately reports gate state.

## Risks / open questions

- **False positives** are the killer risk: "done reading the file" is not a
  success claim. Pattern list must be conservative; `warn` default mitigates.
- Where does session state live — temp dir keyed by session ID? Needs cleanup.
- Should the regex approach be replaced by a prompt-based Stop hook (hook invokes
  `claude -p` to classify the claim)? More accurate, slower, costs tokens.
  Decide in design review.
