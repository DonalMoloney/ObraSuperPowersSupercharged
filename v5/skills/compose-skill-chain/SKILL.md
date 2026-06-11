---
name: compose-skill-chain
description: Use when a multi-skill sequence has just succeeded — records it as a named, reusable chain so the same route can be invoked directly next time without re-deriving it.
author: Donal Moloney
track: D
type: support
chains-to: skill-router
---

## Not this skill if
- The chain failed or produced mixed results — record a note in `docs/chain-log.md` but do not promote it
- The sequence was incidental — only promote a chain that solved a recognisable, recurring task type
- A chain already exists for this task type — update it instead of creating a duplicate

# compose-skill-chain — turn a successful multi-skill run into a reusable macro

## Purpose

When a sequence of skills solves a problem well, that route is typically re-derived from scratch next time. The model picks similar skills in a similar order, but with friction: re-reading descriptions, second-guessing sequencing, possibly taking a worse path.

A named chain eliminates this. It captures the exact sequence, the task type it solves, the entry conditions, and the evidence that it worked. `skill-router` can invoke it directly on the next matching task.

## Core rule

> **Rule:** Promote only runs where every skill in the chain completed without backtracking. A chain derived from a confused or partial run teaches the wrong route.

## Chain format

Emit the chain as a fenced block with lang `chain`:

````
```chain
name: <slug — lowercase-kebab, unique>
solves: <one sentence describing the task type this chain handles>
entry-condition: <the situation or trigger phrase that should invoke this chain>
skills:
  - <skill-slug-1>
  - <skill-slug-2>
  - <...>
evidence: |
  <one or two sentences from the PROVEN BY: block of the run that produced this chain>
notes: <optional — known variants, skip conditions, or ordering constraints>
```
````

## Fields

**solves** — Describe the task type generically, not the specific task. "Introduce a new feature end-to-end from spec to shipped PR" not "Add the export button to the dashboard".

**entry-condition** — What the user says or what the situation looks like that should trigger this chain. Be specific enough that `skill-router` can match it confidently.

**skills** — Ordered list. Parallel skills (run simultaneously) are grouped on a single line separated by `+`. Example: `scope-feature + challenge-spec` means both run together before the next step.

**evidence** — Paste the `PROVEN BY:` summary from the run that produced this chain. This is the proof that the chain works.

## Process

1. After a successful multi-skill run, review the sequence of skills invoked
2. Confirm every skill completed without backtracking (check task list or turn log)
3. Write the chain block
4. Write the chain to `skills/v1/chains/<name>.chain.md` (one chain per file), then run `bash skills/v1/chains/index-chains.sh` to refresh `INDEX.md`
5. Add a row to the `skill-router` dispatch table referencing the chain name
6. If the chain supersedes an older route, mark the old one deprecated in `skills/v1/chains/`

## Chain registry

All chains live in `skills/v1/chains/`, one `<name>.chain.md` file per chain.
Add `autonomy:` (`low|medium|high`) and `checkpoints:` (`[slug, ...]`) fields — see
`skills/v1/chains/README.md` for the full format. Format:

```markdown
# Chain Registry

## feature-end-to-end

**Solves:** Introduce a new feature from spec to shipped PR  
**Entry condition:** "Add X", "Build X", "Implement X" with no existing spec  
**Skills:** scope-feature → challenge-spec → outline-plan → write-tests-first → execute-plan → request-review → finish-branch  
**Evidence:** All tests passing, PR merged, PROVEN BY: `npm test` exit 0  

---
```

## Promoting a chain into skill-router

Add the chain as a named route in `skill-router`:

```
chain: feature-end-to-end
  match: ("add"|"build"|"implement") AND no existing spec
  invoke: scope-feature → ...
```

`skill-router` resolves a chain name to its step list at invocation time. If the chain is updated, the router picks up the new steps automatically.

## Chain maintenance

Chains can go stale when a constituent skill is renamed, merged, or retired. `chain-lint.sh` scans `skills/v1/chains/` for references to non-existent skill slugs. Run it before a release.

When a chain is used and produces a better route, update the `skills:` list and `evidence:` field. Do not create a new chain for minor variations — update the existing one with a `notes:` entry.

## Failure modes

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| Chain fires on the wrong task | entry-condition is too broad | Tighten with a negative condition ("AND not a bug fix") |
| Chain breaks after a skill rename | Stale slug reference | Run `find-dangling-refs` after any rename |
| Chain has two competing versions | Duplicate promotion | Merge into one chain with `notes:` capturing the variant |
| Chain was promoted from a partial run | Evidence was incomplete | Re-run end-to-end before promoting; update evidence |

## Integration

- `skill-router` — reads `skills/v1/chains/` to resolve named routes
- `adaptive-skill-router` — uses chain usage data from telemetry to suggest promotions
- `find-dangling-refs` — validates chain slug references after skill renames
- `audit-dead-skills` — flags chains with zero invocations as retirement candidates
