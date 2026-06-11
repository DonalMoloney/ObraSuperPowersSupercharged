# bug-hunter (v2 plugin)

Swarm bug hunting for any codebase. `/hunt-bugs [path | --diff]` dispatches six
read-only bug-class specialist agents in parallel, an adversarial verifier
filters false positives, and one ranked evidence-backed report is produced.
Report-only — it never fixes. Confirmed findings feed the v1
**systematic-debugging** workflow.
Spec: `docs/superpowers/specs/2026-06-10-bug-hunter-plugin-design.md` (repo root).

tier: v2 · supports: systematic-debugging, requesting-code-review

## Roster

| Agent | Bug class |
|---|---|
| `silent-failure-hunter` | Swallowed exceptions, error-hiding fallbacks, ignored return codes |
| `boundary-bug-hunter` | Off-by-one, None paths, empty collections, numeric/string edges |
| `race-condition-hunter` | Unsynchronized shared state, check-then-act gaps, unsafe lazy init |
| `resource-leak-hunter` | Unclosed handles/connections, cleanup skipped on exception paths |
| `contract-drift-hunter` | Code vs docstring/type/comment mismatches, dead branches |
| `injection-and-trust-hunter` | Unsanitized input reaching SQL/shell/paths/eval, unsafe deserialization |
| `finding-verifier` | Adversarial false-positive filter — confirms or rejects, never adds |

## Usage

- `/hunt-bugs` — whole project (asks you to narrow above 200 source files)
- `/hunt-bugs src/auth/` — one subtree
- `/hunt-bugs --diff` — changed files only

Severities: P0 crash/data-loss · P1 incorrect results · P2 degraded behavior ·
P3 latent hazard. Rejected findings are listed at the bottom of every report so
the filtering is auditable.

## Fixtures

`fixtures/` holds one deliberately-buggy Python file per bug class (20 planted
bugs, documented in `fixtures/MANIFEST.md` — never marked in the code itself).
Acceptance: every hunter finds its planted bugs and the verifier confirms them.
