# Bug Hunter Plugin — Design

**Date:** 2026-06-10
**Status:** Approved design, pending implementation plan
**Tier:** v2 plugin (`supports: systematic-debugging, requesting-code-review`)

## Purpose

A reusable Claude Code plugin that autonomously hunts bugs in any codebase. One
command (`/hunt-bugs`) dispatches six read-only specialist agents in parallel, each
owning one bug taxonomy class, then a seventh adversarial verifier agent filters
false positives before a single ranked report is produced.

The plugin is strictly read-only: it reports bugs with evidence; it never fixes
them. Confirmed findings feed into the v1 `systematic-debugging` workflow.

## Decisions made during brainstorming

| Question | Decision |
|----------|----------|
| Bug target | Any codebase (general-purpose, reusable) — not this skills repo |
| Packaging | Claude Code plugin |
| Trigger | `/hunt-bugs` swarm command (user-triggered, autonomous execution) |
| Output | Ranked report only — no auto-fix, no issue filing |
| Agent slicing | By bug class (Approach A), plus a scope argument borrowed from the scout approach |

## Architecture

```
v2/plugins/bug-hunter/
  .claude-plugin/plugin.json     # name, version, description
  commands/hunt-bugs.md          # the /hunt-bugs swarm orchestrator
  agents/
    silent-failure-hunter.md
    boundary-bug-hunter.md
    race-condition-hunter.md
    resource-leak-hunter.md
    contract-drift-hunter.md
    injection-and-trust-hunter.md
    finding-verifier.md
  fixtures/                      # one deliberately-buggy file per bug class
  README.md                      # roster table + usage
```

## Agent roster

All six hunters share one template: read-only tools (`Read, Glob, Grep, Bash`), a
tightly scoped "you hunt exactly this bug class" system prompt containing a
checklist of concrete patterns to grep for and reason about, and a required
structured output format (see Finding format).

| Agent | Bug class |
|-------|-----------|
| `silent-failure-hunter` | Swallowed exceptions, empty catch blocks, error-hiding fallbacks, ignored return codes |
| `boundary-bug-hunter` | Off-by-one, null/None/undefined paths, empty collections, integer edges, encoding edges |
| `race-condition-hunter` | Shared mutable state, check-then-act gaps, async/await misuse, unsafe lazy initialization |
| `resource-leak-hunter` | Unclosed files/connections/subscriptions, missing finally/defer/context managers |
| `contract-drift-hunter` | Code that no longer matches docstrings/types/comments, callers violating callee assumptions, dead branches |
| `injection-and-trust-hunter` | Unsanitized input reaching SQL/shell/paths/eval, unsafe deserialization |
| `finding-verifier` | Not a hunter. Receives all raw findings, re-reads each location with full surrounding context, and is explicitly adversarial — its job is to reject findings. It never adds new findings, only confirms or rejects. |

## Finding format

Every hunter reports each finding as:

- `file:line`
- Evidence snippet
- Why it is a bug (not a style preference)
- How it would manifest at runtime
- Confidence: high / medium / low

## Data flow

1. `/hunt-bugs [path | --diff]` resolves scope:
   - No argument → whole repo. If the scope exceeds 200 source files, the command
     asks the user to narrow rather than burning a partial sweep.
   - `--diff` → changed files only (`git diff` + staged).
   - A path → that subtree.
2. The command dispatches all six hunters **in parallel in a single message**, each
   given the same scope.
3. Findings are collected from all hunters.
4. The `finding-verifier` is dispatched with the full finding list; it confirms or
   rejects each one.
5. The command prints one final report:
   - Ranked by severity (P0 crash/data-loss, P1 incorrect results, P2 degraded
     behavior, P3 latent hazard), then by confidence within severity.
   - Rejected findings listed one line each at the bottom, so the filtering is
     auditable.
   - Hunters that found nothing are listed as "clean".

## Error handling

- A hunter that finds nothing reports "clean" — a result, not a failure.
- A hunter that errors out is noted in the report as a **coverage gap**, never
  silently dropped.
- The verifier rejecting everything is a valid outcome; the report says so plainly.

## Testing

- `fixtures/` contains one small deliberately-buggy file per bug class (planted
  off-by-one, swallowed exception, etc.), each bug documented in a fixture
  manifest so the expected findings are checkable.
- Acceptance check: `/hunt-bugs fixtures/` finds every planted bug and the
  verifier does not reject them.
- `plugin-validator` agent pass on plugin structure; `skill-auditor` pass before
  commit, per repo workflow.

## Out of scope (YAGNI)

- Auto-fixing (`--fix`) — rejected during brainstorming.
- Filing findings as tasks/issues or persistent backlogs.
- Hook-triggered, scheduled, or proactive invocation — the command is the only
  entry point.
- Runtime observation / probe-test agents (Approach B material; revisit only if
  report-only hunting proves insufficient).
