---
name: done-gate
description: Use when about to claim "done", "ready", or "complete", and before requesting review or opening a PR — runs the full completion battery (tests, lint, PROVEN-BY evidence, assumption check), risk-scores the change, and routes it to the right review depth instead of relying on memory.
author: Donal Moloney
tier: v2
supports: [verification-before-completion, requesting-code-review]
type: process
chains-to: reviewer-lenses
---

## Not this skill if

- Mid-task progress check — gates fire at the "done" boundary only; for iterating a failing suite to green, that is v2 **loop-until-green**.
- Re-verifying after a one-line fix to a previously failed gate — re-run only the failing check, not the full battery.
- You are a subagent whose parent will run the gate — defer to the parent's gate.
- Documentation-only change with zero code delta — lint + evidence check suffice; skip the full battery explicitly.

# Done Gate

## Purpose

v1 **verification-before-completion** demands evidence before claims but leaves two things to memory: *which* checks make up the full battery, and *how much review* the change deserves afterward. This gate bundles the battery into one call and makes review depth a function of measured risk, not mood — fast-path for trivial changes, multi-lens review for risky ones.

**Core rule:** no "done" without a green battery and an attached `PROVEN BY:`. The battery runs to completion — never short-circuit on the first failure; the full picture is the point.

## Procedure

1. **Run the full battery** (all four, regardless of failures):
   - **Tests** — full suite. Record total/pass/fail/skipped. A skipped test is not a pass — flag it explicitly.
   - **Lint** — zero new warnings. A suppression introduced by this change is a flag, not a pass.
   - **Evidence check** — the task has a real `PROVEN BY:` trail per v1 **verification-before-completion**: commands were run, output was read, claims trace to output. An empty or templated evidence block is a hard fail.
   - **Assumption check** — if the project tracks assumptions (v2 **track-assumption** ledger), scan for entries this change touches whose expiry passed or whose condition is now testable. Stale assumptions attached to this change fail the battery; stale assumptions elsewhere are a warning. Fail-soft: no ledger → record "no assumption ledger" and move on.
2. **If any check failed:** the gate result is FAIL. Report per-check results and stop — no risk score, no routing, no "done".
3. **Score the blast radius.** Use v2 **blast-radius** if available; otherwise count distinct modules that import or call the changed symbols and use that count as the score. Low (0–2): isolated, no shared-state spillover. Medium (3–5): crosses a defined interface or shared utility. High (6+): public API, shared schema, global config, or critical path.
4. **Route by risk and change shape** (apply every matching row):

   | Risk / shape | Review route |
   |---|---|
   | Low — any shape | Fast path: single reviewer via v1 **requesting-code-review** |
   | Medium — any shape | v1 **requesting-code-review** with the gate result attached |
   | High — any shape | v2 **reviewer-lenses**, minimum three lenses |
   | Any — new/changed types or interfaces | Ensure the architecture lens is among the dispatched lenses |
   | Any — new error paths or swallowed exceptions | Ensure the correctness lens explicitly covers error handling |
   | Any — auth, permissions, secrets, or input handling touched | Security lens is mandatory, whatever the risk score |

5. **Emit the gate result** as one block: per-check battery lines, risk score + label + one-line rationale, the routed review depth, and the `PROVEN BY:` block. Then hand off to the routed review.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Short-circuiting the battery on the first failure | Run all four; report the full picture |
| Treating a skipped test as a pass | Skipped is flagged, never green |
| Accepting a placeholder PROVEN BY | Real, traceable evidence or hard fail |
| Routing before the battery is green | A FAIL gate emits no routing — there is nothing to review yet |
| Collapsing multiple matching shape rows into one | Every matching row applies; lenses are additive |
| Using the gate as a progress check | Boundary event only; mid-task iteration belongs to v2 **loop-until-green** |

## After

Hand the gate result to the routed review (v1 **requesting-code-review** or v2 **reviewer-lenses**). Process findings via v1 **receiving-code-review**.

PROVEN BY: the emitted gate block — four battery lines (tests N/N, lint clean, evidence check PASS, assumption scan result), risk score with rationale, and the routed review depth. A "done" claim without this block, or a routing produced from a failed battery, is invalid under this skill.
