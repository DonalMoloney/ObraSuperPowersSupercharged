---
name: test-impact-analysis
description: Use when the full test suite is too slow to run on every change and you want to run only the tests a diff can affect — pre-merge gates, "which tests do I need to run for this change?", selective/impacted CI runs. Symptoms: 30-minute suites, running everything "just in case", or picking tests by what sounds related.
author: Donal Moloney
track: B
type: technique
chains-to: loop-until-green
pairs-with: ci-fan-out-gate
---

## Not this skill if
- The full suite runs in under ~1–2 minutes — just run it all; selection overhead isn't worth it.
- The change touches a foundational module half the repo depends on — the "affected set" is "everything"; run the full suite.
- You cannot build a reliable dependency graph **and** have no full-suite backstop — run everything rather than guess.

# test-impact-analysis — run the tests a change can actually reach

## Purpose

Run only the tests a change can reach — but derive that set by **tracing the dependency graph**, not by guessing which tests *sound* related. A behavioral change ripples through every transitive dependent; name-based intuition silently drops the dependents that aren't named after the thing you changed, and you ship green with a hole in the coverage.

## Core rule

> **Rule:** Selection is by reachability, not by name. A test is affected **iff** a path exists from the changed symbol to that test through the dependency graph. Any edge static analysis can't see (dynamic import, DI, config wiring, reflection, fixtures) **widens** the set — never narrows it.

## Triggers

**Use when**
- A slow suite makes the pre-merge gate painful and you want "just the affected tests".
- You're asked "which tests do I need to run for this change?"
- Setting up selective / impacted test runs in CI.

**Don't use when** — see *Not this skill if* above.

## The method

1. **Find the changed symbols, not just files.** `git diff` → changed files → the specific functions/classes/exports that changed. A behavioral change with no signature change still affects every caller of that path.
2. **Build the reverse-dependency graph** (who imports me, *transitively*). Walk *up* from each changed file to all transitive dependents — `nx affected`, `gta`, a language import-graph tool, or recursive importer search. Direct importers are the easy 20%; the dangerous dependents are 2–3 hops away.
3. **Map dependents → covering tests.** For each affected source module, collect the tests that exercise it.
4. **Widen for blind spots (the safety net).** Static graphs cannot see: dynamic import / reflection (`importlib`, `getattr`), dependency injection & plugin registries, config-driven wiring, fixtures / factories / snapshots, generated code, and integration/e2e tests that touch everything. Add the tests covering those regions, or fall back to the full suite for the uncertain region. When unsure whether an edge exists, include it.
5. **Verify the subset is complete — don't trust it.** The selection is a *claim* ("these are all the affected tests"). Back it: run the full suite in the background / post-merge as a backstop, and periodically diff the selected-set result against a full run. If a full run ever fails on a test the subset skipped, the graph has a missing edge — fix the selection, don't widen blindly forever.
6. **Run the affected set → `loop-until-green`.**

## Worked example

Change: `round_currency()` in `utils/money.py` (banker's → round-half-up; behavioral, no signature change).

| Test | Path to `money.py` | Run? | Why |
|------|--------------------|------|-----|
| `test_money` | direct import | ✅ | reachable |
| `test_billing`, `test_checkout`, `test_reports` | transitive (→ billing/checkout/reports → money) | ✅ | reverse-dep walk, not name-guessing |
| `test_invoicing` | **no static import** — `invoicing.py` resolves a formatter by name via `importlib` from config | ✅ | static analysis is blind here → included by the step-4 safety net, not by luck |
| `test_user`, `test_auth`, `test_api`, `test_notifications` | no path | ⏭ | no reachability, static or dynamic |

Contrast the failure mode: picking "everything money-related" by name catches `test_invoicing` only by coincidence and would **miss** an affected dependent with an unintuitive name (a `ledger.py` or `notifications.py` that quietly formats amounts). Reachability finds it; intuition doesn't.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|-----------|--------|
| Selecting tests by name/intuition ("sounds related") | Trace the reverse-dependency graph; reachability decides, not the name |
| Stopping at direct importers | Walk transitively — the costly misses are 2–3 hops from the change |
| Treating static analysis as complete | Dynamic/DI/config/reflection edges are invisible; widen on uncertainty, never narrow |
| Treating the subset as proof of safety | The subset is a claim — back it with a full-suite backstop + periodic selected-vs-full diff |
| Dropping integration/e2e because they're slow | Those are exactly the tests that catch cross-module ripples |

## After

```
PROVEN BY: changed symbols listed; reverse-dependency set computed (<tool/command shown>);
affected tests = transitive dependents + safety-net additions for dynamic edges; subset run green
(loop-until-green); full-suite backstop run/scheduled; selected-vs-full diff shows no skipped failures.
```

Gate any completion claim through `verify-before-done` + `proof-gate`. Run the affected set behind `ci-fan-out-gate`; shard it further with `distributed-test-sharding` (v2, unpublished) when it's still large enough to warrant splitting.

## Adapt from
- **`nrwl/nx`** (MIT) — `nx affected`: project dependency graph + affected-target detection. <https://nx.dev>
- **`digitalocean/gta`** (Apache-2.0) — Go Test Auto: affected-package detection from the import graph. <https://github.com/digitalocean/gta>
