---
name: spec-from-codebase
description: Use to reverse-engineer a written spec from an undocumented subsystem — parallel explorers trace execution paths and data flow, a synthesizer writes the spec, and challenge-spec grills it. The onboarding/handoff inverse of outline-plan.
author: Donal Moloney
track: A
type: process
chains-to: challenge-spec
---

## Not this skill if
- You're planning new work, not documenting existing code — use `outline-plan`
- You just need to understand it for yourself — use `see-big-picture` / `Explore`
- The subsystem has an existing spec you only need to validate — use `challenge-spec` directly
- You need an architecture-level view across multiple subsystems — use `see-big-picture` first

# spec-from-codebase — recover the spec the code never had

## Purpose

Produce a trustworthy written spec for code that has none: inputs, outputs, invariants, edge-case behavior, and assumptions — recovered from the implementation and then stress-tested.

## Triggers

**Use when:**
- Onboarding to a legacy subsystem with no documentation
- Preparing for a refactor: you need to pin current behavior before changing it
- Handing off a subsystem to another engineer or team
- Asked "what does this actually do?" and the answer must be authoritative, not informal
- Writing a test suite against behavior that was never specified — the spec comes first

**Don't use when:**
- The code is trivial (single function, < 50 lines) — read it directly
- A spec already exists and you only need to check whether the code matches it — use `challenge-spec`
- You are designing new behavior, not recovering existing behavior — use `outline-plan`
- The goal is personal understanding with no deliverable — use `see-big-picture`

## Core rule

> **Rule:** Every spec clause traces to code (`file:line`) or is flagged as inferred. Never present an assumption as a documented guarantee.

## Algorithm

### Step 1 — Scope the subsystem and its boundaries

Identify the entry points: public functions, API routes, CLI commands, event handlers, or exported classes that represent the subsystem's surface. List them explicitly before dispatching any explorer. Name the boundary: what is inside the subsystem, what calls it from outside, and what it calls that is out of scope. Record this boundary list — it anchors all subsequent exploration and prevents scope creep.

If the subsystem boundary is unclear, read the directory structure and any existing comments to form a working hypothesis. The boundary can be revised after the first explorer pass, but must be declared before dispatching.

### Step 2 — Dispatch parallel explorers

Fan out one explorer agent per entry point (or per major execution path when a single entry point branches heavily). Each explorer receives:
- The entry point to trace
- The boundary list from Step 1
- Instructions to return observed behavior with `file:line` citations for every claim

Each explorer traces:
- Input types and validation (what is accepted, what is rejected, where the checks live)
- Execution path through the subsystem (control flow, branching conditions, loops)
- Data transformations (what changes, in what order, what invariants hold mid-flight)
- Outputs and return values (normal path and error path)
- External calls made from inside the subsystem (databases, APIs, other modules)
- Error handling: what exceptions are caught, what propagates, what is silently swallowed

Cap concurrency at 5–6 raw parallel agents. If entry points exceed 6, group related paths and assign one explorer per group. Do not start synthesis until all explorers have returned.

### Step 3 — Synthesize the spec with provenance tags

Assemble the spec from explorer outputs. The spec structure must contain these sections:

- **Purpose** — one sentence: what problem the subsystem solves
- **Inputs** — each parameter or incoming payload: type, constraints, source
- **Outputs** — each return value or side effect: type, conditions under which it occurs
- **Invariants** — conditions that hold before, during, and after execution
- **Edge cases** — boundary inputs, empty inputs, concurrent calls, failure modes
- **Assumptions** — anything the subsystem relies on that is not enforced in code

Tag every clause as one of:
- `[observed: file:line]` — directly witnessed in code; include the citation
- `[inferred]` — logical conclusion from observed behavior; flag it explicitly

Do not merge observed and inferred clauses without tagging them separately. Do not smooth over gaps — put them in the open-questions list instead.

### Step 4 — Grill the draft with challenge-spec

Pass the full draft spec to `challenge-spec`. It will ask one probing question at a time to expose gaps, contradictions, and unverified assumptions. For each question raised:

- If the answer traces to a `file:line` citation, add it to the relevant clause and mark it `[observed]`
- If the answer requires another exploration pass, dispatch a targeted explorer and return to Step 3
- If the answer is genuinely unknown, add it to the open-questions list with a note on how to resolve it (e.g., "requires runtime testing" or "requires author confirmation")

Do not close this step until `challenge-spec` reaches a natural stopping point (no more high-confidence questions). The grill loop may require two or three rounds.

### Step 5 — Emit the spec and open-questions list

Produce the final deliverable as two artifacts:

1. **The spec** — all sections from Step 3, fully tagged, challenge-hardened, with all citations intact
2. **Open questions** — a numbered list; each entry states the unknown, why it matters, and the suggested resolution path

Format the spec for the handoff audience: engineers unfamiliar with this subsystem should be able to read it without the codebase open. Keep clause language precise and free of implementation jargon where possible.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Presenting inferred behavior as documented fact | Tag every clause `[observed: file:line]` or `[inferred]`; never omit the tag |
| Scoping the exploration too wide before dispatching | Declare the boundary list in Step 1; explorers that drift outside it return noise |
| Starting synthesis before all explorers return | Wait for all explorer results; partial synthesis produces contradictory clauses |
| Skipping `challenge-spec` because the draft "looks complete" | The draft always has gaps; `challenge-spec` exposes the ones the synthesizer normalizes away |
| Burying open questions inside spec clauses | Collect them in a separate numbered list; hidden unknowns become silent bugs in the next refactor |
| Treating error-handling paths as out of scope | Error paths are first-class spec content; explorers must trace them explicitly |

## Proof

Hand off to `challenge-spec` once synthesis completes; hand off to `verify-before-done` once the grill loop closes and the final spec is assembled.

The output must contain:
- A spec with every clause tagged `[observed: file:line]` or `[inferred]`
- A numbered open-questions list (empty only if `challenge-spec` raised no unresolved gaps)
- Confirmation that all entry points identified in Step 1 were covered by at least one explorer
- `PROVEN BY:` the per-entry-point explorer evidence log (agent IDs or explicit per-path confirm lines) plus the `challenge-spec` session record showing which questions were resolved and which were escalated to open questions

## Adapt from
- **`feature-dev:code-explorer`** (this environment) — execution-path/data-flow tracing pattern.
- **`mermaid-js/mermaid`** — render the recovered flow/sequence as a diagram artifact.
  <https://github.com/mermaid-js/mermaid>
