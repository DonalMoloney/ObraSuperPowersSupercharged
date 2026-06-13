---
name: test-impact-analysis
description: Use when the full test suite is too slow to run on every inner-loop change and you want to run only the tests a diff can actually reach — "which tests do I need for this change?", pre-merge selection, impacted CI runs. Symptoms: multi-minute suites, running everything "just in case", or picking tests by what sounds related.
author: Donal Moloney
tier: v2
supports: [test-driven-development, verification-before-completion]
type: technique
pairs-with: loop-until-green
---

## Not this skill if

- The full suite runs in seconds — just run it all; selection overhead isn't worth it, and v1 `test-driven-development` already wants the fast loop.
- The change touches a foundational module half the repo depends on — the affected set is "everything"; run the full suite.
- You cannot build a reliable dependency graph — guessing by name is worse than running everything.
- You are at the completion gate. This skill never owns the final green run; v1 `verification-before-completion` does, and its Iron Law still demands the full suite before any "done" claim.

# Test Impact Analysis

## Purpose

The TDD inner loop (v1 `test-driven-development`) wants fast feedback, but a slow full suite makes every red-green-refactor cycle painful. This skill maps a diff to the minimal set of tests that could be affected — by import/dependency graph and changed symbols — so the inner loop runs only those. The full run does not go away: v1 `verification-before-completion` still owns the completion gate and requires the whole suite green before "done".

**Core rule:** Selection is by reachability, not by name. A test is affected **iff** a path exists from a changed symbol to that test through the dependency graph. Any edge static analysis can't see (dynamic import, DI, config wiring, reflection, fixtures) **widens** the set — never narrows it.

## The method

1. **Find the changed symbols, not just files.** `git diff` → changed files → the specific functions/classes/exports that changed. A behavioral change with no signature change still affects every caller of that path.
2. **Build the reverse-dependency graph** — who imports the changed file, *transitively*. Walk *up* to all transitive dependents using whatever import-graph tooling the repo has (`nx affected`, a language import-graph tool, recursive importer search). Direct importers are the easy 20%; the dangerous dependents are 2–3 hops away.
3. **Map dependents → covering tests.** For each affected source module, collect the tests that exercise it. That subset is the inner-loop set.
4. **Widen for blind spots.** Static graphs cannot see: dynamic import / reflection, dependency injection & plugin registries, config-driven wiring, fixtures / factories / snapshots, generated code, and integration/e2e tests that touch everything. Add the tests covering those regions, or fall back to the full suite for the uncertain region. When unsure whether an edge exists, include it.
5. **Run the affected subset on the inner loop.** Use it for the red-green-refactor cycles of v1 `test-driven-development` — not as a substitute for the final run.
6. **Hand off to the completion gate.** Before claiming done, run the full suite under v1 `verification-before-completion`. If a full run ever fails on a test the subset skipped, the graph has a missing edge — fix the selection, don't widen blindly forever.

## Worked example

Change: `round_currency()` in `utils/money.py` (banker's → round-half-up; behavioral, no signature change).

| Test | Path to `money.py` | In subset? | Why |
|------|--------------------|-----------|-----|
| `test_money` | direct import | yes | reachable |
| `test_billing`, `test_checkout`, `test_reports` | transitive (→ billing/checkout/reports → money) | yes | reverse-dep walk, not name-guessing |
| `test_invoicing` | **no static import** — resolves a formatter by name via reflection from config | yes | static analysis is blind here → included by the step-4 safety net, not by luck |
| `test_user`, `test_auth`, `test_api` | no path | no | no reachability, static or dynamic |

Picking "everything money-related" by name catches `test_invoicing` only by coincidence and would **miss** an affected dependent with an unintuitive name (a `ledger.py` or `notifications.py` that quietly formats amounts). Reachability finds it; intuition doesn't.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|-----------|--------|
| Selecting tests by name/intuition ("sounds related") | Trace the reverse-dependency graph; reachability decides, not the name |
| Stopping at direct importers | Walk transitively — the costly misses are 2–3 hops from the change |
| Treating static analysis as complete | Dynamic/DI/config/reflection edges are invisible; widen on uncertainty, never narrow |
| Treating the subset as proof of done | The subset is an inner-loop accelerator; the full run at the v1 completion gate is the proof |
| Dropping integration/e2e because they're slow | Those are exactly the tests that catch cross-module ripples |

## After

PROVEN BY: changed symbols listed; reverse-dependency set computed (tool/command shown); affected subset = transitive dependents + safety-net additions for dynamic edges; subset run green on the inner loop. The completion claim itself is still gated by v1 `verification-before-completion` — full suite green, fresh, before "done". A subset green is never a completion claim under this skill.
