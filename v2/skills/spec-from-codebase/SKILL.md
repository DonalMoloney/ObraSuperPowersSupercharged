---
name: spec-from-codebase
description: Use when you must reverse-engineer a written spec from an existing, undocumented subsystem before planning a refactor, onboarding, or handoff — parallel read-only explorers trace entry points, execution paths, and data flow, and a synthesizer writes a structured spec (purpose, behavior, interfaces, invariants) so brainstorming and writing-plans have ground truth instead of guesses.
author: Donal Moloney
tier: v2
supports: [brainstorming, writing-plans]
type: process
pairs-with: scope-decomposition
---

## Not this skill if

- You are designing NEW behavior from a green field — v1 **brainstorming** owns that; there is no existing code to recover a spec from.
- You already have a spec and only need to plan the work — go straight to v1 **writing-plans**.
- The subsystem is trivial (one function, < 50 lines) or you only need personal understanding — just read it.

# Spec From Codebase

## Purpose

v1 brainstorming and writing-plans assume a spec exists or can be designed. They have nothing to chew on when the truth lives only in undocumented code — so a fresh session re-derives behavior from memory, guesses at invariants, and plans against assumptions. This skill produces the missing ground truth: a written spec recovered from an existing subsystem, every clause traced to `file:line` or flagged as inferred. Feed its output into brainstorming (to design changes) or writing-plans (to plan a refactor) so those skills work from observed behavior, not folklore.

**Core rule:** every spec clause traces to code (`file:line`) or is tagged `[inferred]`. Never present an assumption as a documented guarantee.

## Procedure

### 1 — Declare the boundary

List the entry points that form the subsystem's surface: public functions, API routes, CLI commands, event handlers, exported classes. State what is inside, what calls it from outside, and what it calls that is out of scope. Write this list down before dispatching anyone — it anchors exploration and prevents drift. Revise it after the first pass if needed, but never dispatch without it.

### 2 — Fan out read-only explorers

Use v1 **dispatching-parallel-agents** to launch one explorer per entry point (or per major branch when one entry point forks heavily). Explorers are read-only — they trace, they do not edit. Each receives the entry point, the Step 1 boundary list, and the instruction to cite `file:line` for every claim. Each traces:

- Inputs: accepted types, validation, where checks live
- Control flow: branching, loops, the path through the subsystem
- Data flow: what transforms, in what order, what holds mid-flight
- Outputs: return values and side effects, normal and error paths
- External calls: databases, APIs, other modules
- Error handling: what is caught, what propagates, what is silently swallowed

Cap at 5–6 parallel explorers; group related paths if entry points exceed that. Do not synthesize until all have returned.

### 3 — Synthesize the spec with provenance tags

One synthesizer assembles explorer outputs into a structured spec with these sections:

- **Purpose** — one sentence: the problem the subsystem solves
- **Inputs** — each parameter/payload: type, constraints, source
- **Outputs** — each return value/side effect: type, conditions
- **Invariants** — what holds before, during, and after execution
- **Edge cases** — empty/boundary inputs, concurrency, failure modes
- **Assumptions** — what the subsystem relies on but does not enforce

Tag every clause `[observed: file:line]` (witnessed, with citation) or `[inferred]` (logical conclusion, flagged). Never merge the two without tagging. Gaps go in an open-questions list, not glossed over.

### 4 — Stress-test, then hand off

Run the draft through v2 **red-team-spec** to expose gaps, contradictions, and unverified assumptions. For each finding: cite a `file:line` and mark it `[observed]`, dispatch a targeted explorer (return to Step 3) if it needs another trace, or add it to open questions with a resolution path ("requires runtime testing", "requires author confirmation"). Then deliver two artifacts:

1. The spec — all sections, fully tagged, citations intact
2. Open questions — numbered; each states the unknown, why it matters, and how to resolve it

Hand the result to v1 **brainstorming** (to design changes) or **writing-plans** (to plan a refactor). If recovery reveals the subsystem is larger than one spec/plan cycle, route through v2 **scope-decomposition** first.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Presenting inferred behavior as documented fact | Tag every clause `[observed: file:line]` or `[inferred]` |
| Scoping too wide before dispatching | Declare the boundary list in Step 1; out-of-bounds explorers return noise |
| Synthesizing before all explorers return | Wait for all results; partial synthesis contradicts itself |
| Skipping red-team-spec because the draft "looks complete" | The draft always has gaps the synthesizer normalized away |
| Burying open questions inside clauses | Collect them in a separate numbered list |
| Treating error paths as out of scope | Error paths are first-class spec content; explorers must trace them |

## After

Verify against v1 **verification-before-completion**: every Step 1 entry point was covered by at least one explorer, every clause carries a provenance tag, and the open-questions list exists (empty only if red-team-spec raised no unresolved gaps).

PROVEN BY: the per-entry-point explorer evidence (which path each covered, with citations) plus the red-team-spec session record showing which findings were resolved and which became open questions. A spec clause with no provenance tag is invalid under this skill.
