---
name: improve-codebase-architecture
description: Use when a bug or change keeps fighting the structure — maps architecture debt across subsystems with parallel readers, scores restructuring options with a judge panel, and writes a phased migration plan. The deferred escalation target for diagnose-bug.
author: Donal Moloney
track: B
type: process
chains-to: write-adr
---

## Not this skill if
- The problem is a single localized bug — use `diagnose-bug` / `find-root-cause`
- You only need to understand the system, not change it — use `see-big-picture`
- The change is cosmetic (renaming, formatting, comment updates) — restructuring overhead not warranted
- You have fewer than 3 subsystems — an inline `see-big-picture` pass is sufficient

# improve-codebase-architecture — map the debt, plan the migration

## Purpose

Close the gap `diagnose-bug` leaves: when three fix attempts fail because the structure is wrong, escalate to a real restructuring plan instead of patching symptoms. Clears the CLAUDE.md "Deferred TODOs" debt — once this skill exists, revert the two `see-big-picture` stand-ins in `diagnose-bug`.

## Core rule

> **Rule:** No restructuring without a phased, reversible migration plan. Each phase must ship and pass tests on its own — never a big-bang rewrite.

## Triggers

**Use when:**
- `diagnose-bug` fires its 3-attempt escalation gate
- A change touches multiple subsystems and keeps rebreaking each time it lands
- A pre-rewrite review is needed to decide whether to rewrite vs. restructure vs. leave alone
- "The architecture keeps fighting me" — repeated coupling failures across unrelated tickets
- A new feature cannot be cleanly located because there is no clear layer to put it in

**Don't use when:**
- The failure has a clear single root cause — fix it with `diagnose-bug` or `find-root-cause`
- The team already has a migration plan and only needs execution — use `execute-plan`
- You only need a snapshot of what exists without a change mandate — use `see-big-picture`

## The pattern

Three stages run in sequence; Stage 1 is internally parallel:

```
Stage 1 (Map)     — N agents, one per subsystem, produce structured debt reports
Stage 2 (Option panel) — judge panel generates and scores 2–3 restructuring options
Stage 3 (Synthesize) — write phased migration plan; freeze with write-adr
```

## Steps

### Step 1 — Reproduce the structural pain

Before mapping anything, reproduce the concrete failure that motivated escalation. Record:
- The change that failed (PR, commit, or attempted edit)
- Which subsystems it touched
- What broke and why the structure resisted the fix

This surfaces the "seam" the architecture is missing. Without this anchor, the debt map loses focus and options panel degenerates into abstract debate.

### Step 2 — Identify subsystems and dispatch parallel readers

Enumerate the subsystems involved. A subsystem is any directory, module, or layer with a coherent responsibility boundary. For each subsystem, dispatch one reader agent with these instructions:
- Trace all inbound and outbound coupling to other subsystems (imports, event subscriptions, shared state)
- Identify layering violations (high-level modules importing low-level details, or circular deps)
- Find churn hotspots — files changed in more than half of the last 20 commits
- Note any modules that have grown past a single responsibility

Cap parallel readers at 6 if dispatching raw agents; use the `Workflow` tool for larger codebases. Each agent returns a structured debt report: `{ subsystem, coupling_edges[], violations[], hotspots[], notes }`.

### Step 3 — Merge into one debt map

Collect all per-subsystem reports. Produce a single debt map containing:
- A coupling graph (which subsystem depends on which)
- Layering violations grouped by type
- Top-5 hotspot files ranked by churn
- Cross-cutting concerns that appear in more than two subsystems

Flag any conflicts between agent reports (e.g., two agents disagree on which subsystem owns a shared module). Resolve conflicts before proceeding — ambiguous ownership is itself a debt item.

### Step 4 — Run the option panel

Generate exactly 2–3 restructuring options, each from a different strategic angle:

- **Minimal-seam option** — the least structural change that breaks the failing coupling; best when risk tolerance is low.
- **Clean-layer option** — introduce or enforce a clear layering boundary (e.g., domain / application / infrastructure); higher effort, higher long-term payoff.
- **Strangler-fig option** — build the new structure alongside the old, route traffic incrementally, delete the old; best for large legacy codebases where a cut-over is too risky.

Score each option on three dimensions: **risk** (likelihood of regressions), **effort** (eng-weeks to complete Phase 1), **payoff** (reduction in future coupling failures). Use a simple 1–5 scale per dimension.

Record the scoring matrix in `decision-ledger` before selecting a winner. Do not select a winner without a logged rationale.

### Step 5 — Write the phased migration plan

From the winning option, write an ordered migration plan. Each phase must:
- Have a concrete, named deliverable (e.g., "Extract `UserRepository` interface from `UserService`")
- Be independently shippable — tests pass at the end of the phase without the next phase being started
- Include a rollback path — if the phase breaks something, state how to undo it in under 30 minutes
- Reference the coupling edges or violations it closes from the debt map

Graft low-risk wins from runner-up options where they don't conflict with the primary approach. Label these "opportunistic" in the plan so reviewers know they are optional.

Phases should be sized for 1–3 days of effort. Break anything larger into sub-phases.

### Step 6 — Freeze with write-adr

Hand the scored option matrix and the phased migration plan to `write-adr`. The ADR must capture:
- Context: the structural pain that triggered escalation
- Options considered: the 2–3 options with scores
- Decision: the winning option and rationale
- Consequences: what gets easier, what gets harder, what is deferred

Once the ADR is committed, update `diagnose-bug`'s two `see-big-picture` stand-ins to point to this skill.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Starting the option panel before the debt map is complete | Finish all parallel reader agents and merge conflicts before generating options — options built on incomplete maps score wrong |
| Picking the cleanest architectural option regardless of risk | Score all three dimensions explicitly; a technically superior option with a risk score of 5 may be worse than a risk-2 minimal-seam option in a live system |
| Writing a migration plan with one giant phase | Each phase must ship independently; break any phase that takes more than 3 days into sub-phases with their own test gates |
| Letting the ADR be written before the debt map artifact exists | The ADR "Context" section must reference the concrete coupling graph and hotspot list — not a narrative summary |
| Skipping the rollback path for each phase | State explicitly how to undo each phase in under 30 minutes; without this, teams hesitate to start and the plan stalls |
| Treating the option panel as a design review, not a scoring exercise | Generate exactly 2–3 options from distinct angles; score each; record in `decision-ledger` before selecting — do not converge by discussion alone |

## Verification / Proof

Run `verify-before-done` before handing off to `write-adr`. The output is valid when:
- The debt map exists as a concrete artifact (coupling graph + violations list + hotspot table)
- The option matrix is recorded in `decision-ledger` with numeric scores for all three dimensions
- The migration plan has at least two independently shippable phases, each with a named deliverable and a rollback path
- The ADR is committed and references both the debt map and the option matrix

```
PROVEN BY:
- debt-map artifact: <file path or inline section>
- decision-ledger entry: <entry title or ID>
- migration plan: <file path>, phases: <count>, each independently shippable: yes/no
- ADR committed: <file path or PR reference>
```

## Output

- Debt map (coupling graph + layering violations + top-5 hotspot files)
- Scored option matrix (2–3 options × risk / effort / payoff)
- Phased, reversible migration plan (ordered phases, each independently shippable and test-gated)
- ADR (committed via `write-adr`)

## Adapt from
- **`obra/superpowers-skills`** — `skills/architecture/` (debt-mapping framing).
  <https://github.com/obra/superpowers-skills>
- **`structurizr/dsl`** — C4-model coupling/layer diagrams as the debt-map artifact.
  <https://github.com/structurizr/dsl>
