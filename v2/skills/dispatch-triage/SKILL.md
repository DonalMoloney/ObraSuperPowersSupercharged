---
name: dispatch-triage
description: Use when choosing which model tier a subagent dispatch needs, or when diagnosing a BLOCKED or failed subagent return before deciding how to re-dispatch — turns task signals into a tier decision and a BLOCKED report into the right remediation.
author: Donal Moloney
tier: v2
supports: [subagent-driven-development]
type: decision
pairs-with: compile-goal-to-contract
---

## Not this skill if

- You are writing the dispatch prompt's *content* — acceptance criteria, scope, done-when — that is v2 **compile-goal-to-contract**, the chain partner upstream of this skill.
- You are merging results returned by parallel subagents — that is v2 **merge-parallel-results**.
- The return status is NEEDS_CONTEXT or DONE_WITH_CONCERNS — v1 **subagent-driven-development** already handles those directly (provide the missing context / read the concerns). This skill triages BLOCKED.

# Dispatch Triage

## Purpose

Two decisions in v1 **subagent-driven-development** are stated as instructions without a procedure:

1. **Model selection.** v1 names three complexity signals (file count, spec completeness, integration scope) but gives no matrix and no rule for when the signals disagree. v1 gives the signals; the table below makes them a decision rule.
2. **BLOCKED handling.** v1 lists four remediation paths but zero criteria for telling which one applies. The diagnosis ladder below supplies the missing questions, each answered from observable evidence in the BLOCKED report.

This skill pairs with v2 **compile-goal-to-contract**: the contract is the input artifact. Task size and risk are read off the contract's fields (acceptance-criteria count, constraints, open-decisions) rather than guessed from the conversation.

**Core rule:** Every tier choice cites matrix scores; every re-dispatch cites a ladder diagnosis. No gut-feel dispatches, no blind retries.

## Table A — model-tier selection matrix

Score each dimension independently, then resolve.

| Dimension | Cheap (fast) tier | Standard tier | Most capable tier |
|---|---|---|---|
| **File count** | 1–2 files, all named in the task | 3–5 files, all identifiable upfront | File set unknown, or spans modules that must be discovered |
| **Spec completeness** (from the contract) | Contract complete: every acceptance criterion testable, `open-decisions: none`, ≤5 acceptance criteria | Minor gaps, each bounded by a decision rule ("if X then Y"); or >5 acceptance criteria | No contract, or unresolved open-decisions, or constraints requiring trade-off judgment (perf budgets, API compatibility) |
| **Integration scope** | Isolated function or file; no shared interfaces touched | Touches shared interfaces; multi-file coordination with known call sites | Task must invent interfaces that don't exist yet, or its blast radius can't be enumerated up front |

**Resolution rules (mixed signals):**

1. **Highest-tier signal wins.** A task that is 1 file (cheap) but has unresolved trade-off constraints (most capable) dispatches at most capable. Never average.
2. **When in doubt, one tier up for review roles.** Spec and code-quality reviewers take the implementer's tier plus one — a deliberate v2 relaxation of v1's review-gets-most-capable default, which still applies to architecture and final review.
3. **Unresolved open-decisions are not a tier signal — they are a gate failure.** Do not dispatch at all; return to v2 **compile-goal-to-contract** to resolve them first.
4. Subject to rules 1–3, pick the cheapest tier the matrix permits — same cost principle as v1.

## Table B — BLOCKED-return diagnosis ladder

Walk the questions top to bottom. The first "yes" — backed by quoted evidence from the BLOCKED report — selects the remediation. Each row maps to one of v1's four remediation paths.

| # | Question (asked of the BLOCKED report) | Observable evidence | Diagnosis | v1 remediation |
|---|---|---|---|---|
| 1 | Did the agent name a **specific missing fact, file, or decision**? | Report cites a concrete unknown: "couldn't find where X is configured", "spec doesn't say which auth scheme". Check: is the missing fact one of the contract's **open-decisions**? If yes, the contract gate was passed incomplete — resolve it via v2 **compile-goal-to-contract** before re-dispatch. | Context problem | More context, **same model** |
| 2 | Did it understand all inputs but produce **circular, contradictory, or stalled analysis**? | Report shows it had the facts yet loops: restates the problem, proposes then retracts approaches, contradicts its own earlier reasoning. | Reasoning complexity | Re-dispatch with a **more capable model** |
| 3 | Did it **complete part of the task and stall on a separable part**? | Report shows finished sub-work plus a blocker on an unrelated remainder: "implemented the parser; blocked on the migration step". | Oversized task | **Break the task into smaller pieces** |
| 4 | Did it report the task **conflicts with the reality of the codebase**? | Report cites a false premise in the plan: "the spec assumes module Y exists / API Z accepts this parameter — it does not". | Wrong plan | **Escalate to the human** |

**No question answers yes:** the BLOCKED report itself is deficient. Ask the agent for a structured blocker statement (what was attempted, what specifically stopped it, what it would need) before choosing any remediation. That clarification round counts toward the re-dispatch cap.

## Re-dispatch cap

**Maximum 2 re-dispatches per task.** After the second re-dispatch fails, stop and escalate to the human with the **diagnosis trail**: for each attempt, the BLOCKED report, the ladder question that fired, the evidence quoted, and the remediation applied. Three informed failures mean the problem is upstream of dispatch — usually the contract or the plan.

## Procedure

1. Gather inputs: full task text, the approved contract from v2 **compile-goal-to-contract** (acceptance criteria, constraints, open-decisions), and the expected file set.
2. Gate check: if open-decisions is not "none", stop — resolve via v2 **compile-goal-to-contract** before any dispatch.
3. Score the three Table A dimensions; record the per-dimension tier and apply highest-signal-wins (plus the review-role bump where applicable).
4. Dispatch at the chosen tier per v1 **subagent-driven-development**, set re-dispatch counter to 0.
5. On a BLOCKED return: walk the Table B ladder top to bottom; record the first question that answers yes and the report text that proves it.
6. Apply the mapped remediation, increment the counter, and re-dispatch (or escalate immediately if question 4 fired — a wrong plan is never fixed by re-dispatching).
7. If the counter reaches 2 and the task is still BLOCKED, escalate to the human with the full diagnosis trail. Verify before closing the task that every tier choice and re-dispatch in the record carries its scores or diagnosis.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Averaging mixed signals ("two cheap, one capable — call it standard") | Highest-tier signal wins; never average |
| Retrying the same model unchanged after BLOCKED | v1 forbids this outright; the ladder decides *what* changes before any retry |
| Diagnosing from intuition ("probably needs a bigger model") | Every diagnosis quotes evidence from the BLOCKED report |
| Bumping the tier when the real problem is a missing fact | Question 1 comes first — context problems are fixed with context, at the same cost |
| Re-dispatching forever because each attempt "almost worked" | Hard cap: 2 re-dispatches, then escalate with the diagnosis trail |
| Picking a tier without a contract because the task "seems small" | Task size and risk come from contract fields; no contract means the spec-completeness column already scores most-capable — or better, go back and compile one |

PROVEN BY: the per-task dispatch record — three Table A dimension scores plus the resolved tier for every dispatch; for every BLOCKED return, the ladder question that fired with quoted report evidence and the remediation applied; a re-dispatch count ≤ 2 or an escalation carrying the full diagnosis trail. A tier choice with no recorded matrix scores, or a re-dispatch with no recorded ladder diagnosis, is invalid under this skill.
