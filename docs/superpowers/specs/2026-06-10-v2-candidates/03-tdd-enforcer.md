# tdd-enforcer — v2 candidate spec

| Field | Value |
|---|---|
| Type | **plugin** (hooks) |
| Theme | Harness |
| Tier | v2 |
| Supports (v1) | test-driven-development |
| Composes with (v2) | skill-lint (pattern: enforcement of a v1 discipline), verification-gate (#1) |
| Status | proposed |

## Problem

v1 `test-driven-development` mandates red-green-refactor, but the model can —
and under pressure does — write implementation first and backfill tests, or skip
them. Like #1, the fix is moving enforcement from prompt to harness.

## What it does

PreToolUse hook that watches Write/Edit calls: when new implementation code is
being created with no corresponding test activity in the session, it warns or
blocks (configurable), naming the v1 skill.

## Parts

### `plugin.json`
Manifest; hooks only (no commands, no agents).

### `hooks/tdd-check.sh` (PreToolUse hook on Write|Edit)
Logic per tool call:
1. Classify the target path: `test` (matches test globs), `source` (matches
   source globs), `other` (docs, config — always allowed).
2. Maintain session ledger (temp file): ordered list of (timestamp, path, kind).
3. Rule: a `source` write for a *new* file or a *new function/feature* is
   flagged when no `test` write or test-run Bash call happened in the preceding
   window of the ledger.
4. On flag: `warn` mode emits hook feedback ("TDD: no failing test precedes this
   implementation — v1 test-driven-development"); `block` mode exit-code-2s.

### `hooks/test-run-tracker.sh` (PostToolUse hook on Bash)
Records test-runner invocations and their pass/fail (red run before source write
is the *good* signal — the ledger needs it to distinguish red-green from
test-after).

### `config`
- `test_globs`, `source_globs` (per-project overridable).
- `mode`: `warn` (default) | `block` | `off`.
- `grace`: allow N unflagged source writes per session for genuine non-TDD work
  (refactors with existing coverage), so the hook nags rather than fights.

## Workflow (intended happy path)

1. Claude writes failing test → ledger: test write.
2. Runs it, sees red → ledger: red test run.
3. Writes implementation → hook checks ledger, finds red-test-precedes → allows
   silently.
4. Deviation (implementation first) → warned/blocked with skill pointer.

## Interfaces

- **v1 test-driven-development**: hook messages name the skill; the skill remains
  the source of truth for the discipline — the hook only detects ordering.
- **#1 verification-gate**: complementary ends of the cycle (this enforces
  red-before-code; the gate enforces green-before-done). Could later merge into
  one `discipline-hooks` plugin — keep separate until both are proven.

## Success criteria

- Implementation-first writes are flagged in real time during a deliberate
  violation test.
- Refactoring sessions with existing coverage are NOT constantly blocked
  (grace + warn defaults).

## Risks / open questions

- Highest false-positive risk of all ten candidates: bugfixes in existing
  well-covered files, generated code, migrations. The classifier is crude by
  nature. Mitigation: ship `warn`-only first; `block` mode may never be the
  default.
- "New function in existing file" detection requires diffing the Edit payload —
  v1 of the hook should only handle new-file creation and leave edits alone.
- Per-language test conventions vary; globs must come from project config, not
  hardcoded defaults.
