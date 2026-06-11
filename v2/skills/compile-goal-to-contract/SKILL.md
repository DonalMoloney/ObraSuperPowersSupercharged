---
name: compile-goal-to-contract
description: Use when a goal is vague enough that two agents could interpret it differently, before dispatching subagents or writing a plan — compiles the goal into a verifiable contract (acceptance criteria, out-of-scope list, done-when checks, constraints) and gates autonomous dispatch on contract completeness.
author: Donal Moloney
tier: v2
supports: [subagent-driven-development, writing-plans]
type: technique
chains-to: dispatch-triage
---

## Not this skill if

- You already have a written plan with tasks — execute it; the plan was the contract. Authoring or revising that plan is v1 **writing-plans**.
- You are deciding which model tier a task needs, or diagnosing a BLOCKED return from a subagent — that is v2 **dispatch-triage**, the chain partner downstream of this skill.
- The goal is a one-liner with an obvious, unambiguous done state — contract overhead exceeds its value.
- You are mid-implementation and the goal is clear — do not interrupt to re-contract.

# Compile Goal to Contract

## Purpose

Turn an underspecified goal into a verifiable contract **before** any agent is dispatched. A vague goal dispatched to an autonomous agent produces vague output: gaps get interpreted optimistically, edge cases get skipped, and "done" is declared when the model feels done rather than when the requirement is met.

This fills a gap in v1 **subagent-driven-development**: that skill tells you to give each subagent full context and review its result, but gives no definition of what "enough context" *is* before dispatch. The contract is that definition — dispatch is gated on contract completeness, not on intuition. It also feeds v1 **writing-plans**: the contract is the spec-shaped input that skill expects ("Use when you have a spec or requirements"); compile the contract first, then plan against it rather than against the raw conversation.

**Core rule:** A contract is not a plan. It does not say *how*. It says what done looks like, what is explicitly out of scope, and what must be true for any reviewer to accept the result. The *how* belongs to v1 **writing-plans**; the *who-and-at-what-cost* belongs to v2 **dispatch-triage**.

## Contract format

Emit the contract in a fenced block with lang `contract`:

````
```contract
goal: <one sentence — the thing being built or fixed>

acceptance-criteria:
  - <testable criterion — starts with an observable verb: "Returns", "Handles", "Passes", "Renders">

out-of-scope:
  - <explicit exclusion — things the implementer might reasonably attempt but must not>

done-when:
  - <the specific test, check, or observable state that proves the work is complete>

constraints:
  - <non-negotiable limits: performance budgets, API compatibility, no new deps>

open-decisions:
  - <questions that must be answered before implementation starts — if none, write "none">
```
````

Field rules:

- **acceptance-criteria** — each criterion independently testable. If you cannot write a test or manual check for it, rewrite it until you can. Avoid "should"/"must"/"will" — use observable verbs.
- **out-of-scope** — be specific. "Performance optimisation" is not useful; "caching layer for the search endpoint" is. List things adjacent to the goal that could be mistakenly included.
- **done-when** — these become the PROVEN BY evidence targets. If you cannot name the test command or observable state right now, the goal is still underspecified.
- **constraints** — hard limits only; preferences go in acceptance criteria.
- **open-decisions** — resolve before dispatch. If a decision cannot be resolved without starting work, bound the implementer's discretion with a decision rule: "if X, then Y; if not X, then Z."

## Procedure

1. Read the goal as stated; write a draft contract in the format above.
2. Test each acceptance criterion: can it be checked without reading the conversation? Rewrite any that can't.
3. Test each done-when item: can the implementer run this check without asking anyone? Rewrite any that can't.
4. Fill out-of-scope with the three most likely scope-creep directions.
5. Resolve open-decisions — ask the user if needed, one question at a time.
6. Emit the final contract and get explicit user approval (approved, not merely read).
7. **Gate:** only with an approved, complete contract do you proceed — to v1 **writing-plans** if a multi-step plan is needed, then to v2 **dispatch-triage** to pick the executor and model tier per task. Do not dispatch agents on an incomplete contract.

Completeness check before passing the gate:

- [ ] Every acceptance criterion starts with a testable verb
- [ ] No criterion requires reading the conversation to interpret
- [ ] out-of-scope covers the three most likely scope-creep directions
- [ ] done-when items map 1:1 to collectable PROVEN BY evidence
- [ ] open-decisions is "none" or every entry has a bounding decision rule
- [ ] User has approved the contract

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Dispatch on a "good enough" goal because the agent will figure it out | Gate dispatch on the completeness checklist — every box, every time |
| Empty out-of-scope ("nothing comes to mind") | List the three adjacent things an eager implementer would bolt on |
| done-when written as "works correctly" | Name the exact command or observable state that proves it |
| Smuggling implementation steps into the contract | A contract says *what done looks like*; the *how* goes in v1 **writing-plans** |
| Re-deriving criteria per subagent during execution | Per v1 **subagent-driven-development**, every subagent receives the same contract; "is this finished?" is answered from the contract, not the conversation |

## After the contract

The contract travels downstream: v1 **writing-plans** decomposes it into tasks, v1 **subagent-driven-development** hands it to each subagent as the definition of done, and v2 **dispatch-triage** (chain partner) uses task size and risk from the contract to choose model tier and diagnose any BLOCKED returns against the open-decisions list.

PROVEN BY: the approved `contract` block plus a trace showing each done-when item mapped to a concrete check the implementer can run unassisted. A dispatch made without an approved contract — or a completion claim that cites the conversation instead of the contract's done-when evidence — is invalid under this skill.
