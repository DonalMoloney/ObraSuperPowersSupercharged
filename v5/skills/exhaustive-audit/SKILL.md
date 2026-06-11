---
name: exhaustive-audit
description: Use to audit anything thoroughly — multi-modal finders each search a different way (by-file, by-pattern, by-data-flow, by-entrypoint), dedup, adversarially verify, loop until two dry rounds, then a completeness critic asks what's still missing.
author: Donal Moloney
track: proof
type: process
chains-to: proof-gate
---

## Not this skill if
- You need one focused search, not exhaustive coverage — use `Explore` / a single grep
- The target is a spec, not an implementation/dataset — use `red-team-spec`
- The sweep is a uniform per-file transform, not a multi-modal discovery pass — use `map-reduce-sweep`
- N < 10 candidate sites and a single grep covers the search space — run it inline

# exhaustive-audit — the "find everything" engine

## Purpose

A reusable harness for any audit where one search angle misses things: security review, dead-skill sweep, data-quality pass. Combines diverse finders, dedup, adversarial verify, and a loop that knows when to stop.

## Triggers

**Use when:**
- Running a security audit across a codebase and you cannot afford false negatives
- Executing `audit-dead-skills` to find unreferenced or stale skill files
- Performing a data-quality pass where findings may surface from multiple entry points
- Answering "did we catch everything?" after a previous targeted search
- Any domain where a single search modality demonstrably under-reports (e.g., a grep misses dynamic calls; a static scan misses data-flow paths)

**Don't use when:**
- You already know the exact query and one grep covers it
- The search space is bounded and small (< 10 sites) — inline search is faster
- The target is a written specification rather than live code or data — `red-team-spec` fits better
- You need a uniform per-file transform rather than discovery — `map-reduce-sweep` fits better

## Core rule

> **Rule:** Dedup against everything seen (not just confirmed), and don't stop on the first empty round — require K consecutive dry rounds. Log any coverage you cap; silent truncation lies.

## The pattern

```
parallel finders → merge seen-set → adversarial verify → loop-until-dry(K=2) → completeness critic → proof-gate
```

1. **Scope** — define the audit target and the contract for a valid "finding" before any finder runs.
2. **Multi-modal sweep (parallel)** — dispatch N finders, each searching a different way.
3. **Dedup** — collapse all findings against the full seen-set.
4. **Adversarial verify** — attempt to refute each finding; discard refuted ones.
5. **Loop** — repeat steps 2–4 until K=2 consecutive rounds add zero new findings.
6. **Completeness critic** — ask what modality didn't run and what claim is still unverified.
7. **Gate** — pass the confirmed output through `proof-gate`.

## Steps

### 1. Scope the audit

Define three things before running any finder:
- **Target** — what corpus is in scope (directory tree, dataset, file glob, skill registry).
- **Finding contract** — the exact condition that makes something a valid finding (e.g., "unreachable function with no inbound references in any `.md` file"; "SQL string built by concatenation without parameterisation").
- **Coverage ceiling** — if you must cap (time, token budget), state the cap and reason now. Do not discover the cap mid-run and silently truncate.

### 2. Run the multi-modal finder fleet (parallel)

Dispatch at minimum four finder agents, each blind to the others' results:

- **By-file** — enumerate files matching a glob or type filter; flag each against the finding contract.
- **By-pattern** — run semgrep or regex-pattern search; each pattern targets one distinct failure mode.
- **By-data-flow** — trace call chains or data provenance; surface findings reachable only through indirect paths.
- **By-entrypoint** — start from public entrypoints (exported functions, CLI flags, API routes) and follow inward.

Each finder must return a list of `{ site, modality, raw_evidence }` records. A site may appear in multiple finders' outputs — that is expected and handled in the next step.

Cap concurrent finders at 6 for raw agent dispatch; use `Workflow` if you need more than 6 in parallel.

### 3. Dedup against the full seen-set

Merge all finder outputs into one seen-set keyed by `site`. A site is "seen" from the moment any finder reports it, regardless of verification status. Dedup must run against the seen-set, not just the confirmed-set — this prevents re-reporting a site that was already examined and refuted.

Produce a deduped candidate list: `{ site, modalities_that_reported_it, raw_evidence[] }`.

### 4. Adversarial verify

For each candidate, attempt to construct a counterargument that proves it is not a real finding. Examples:
- For a dead-skill candidate: check whether a dynamic alias or plugin registry references it.
- For a security candidate: check whether the call site is guarded by a permission check the static scanner missed.
- For a data-quality candidate: check whether the anomaly is intentional and documented.

Keep only candidates that survive scrutiny. Mark refuted candidates as `status: refuted` and retain them in the output log — do not silently drop them.

### 5. Loop until K consecutive dry rounds

After the first verify pass, run another finder sweep scoped to anything the completeness critic flags (step 6). A round is "dry" when it adds zero new entries to the seen-set and zero new confirmations to the confirmed list. Require K=2 consecutive dry rounds before stopping. This protects against finders that surface new leads only after an adjacent finding is confirmed.

Track round number and new-findings count per round. Log both.

### 6. Run the completeness critic

Before closing, ask explicitly:
- Which modality did not run or ran with reduced scope?
- Which confirmed finding has no direct evidence trace — only inference?
- Is there a class of finding the contract definition might have excluded by accident?

If the critic identifies a gap, spawn one more targeted finder for that gap and run one more verify pass. If the round is still dry after that, stop.

### 7. Emit findings and gate

Produce the final output (see Output section below) and pass the completion claim through `proof-gate`. Do not self-certify.

## Output

- **Confirmed findings** — `{ site, modality, evidence, status: confirmed }` for each survivor.
- **Refuted candidates** — `{ site, modality, refutation_reason, status: refuted }` retained for audit trail.
- **Coverage statement** — modalities run, rounds executed, items capped with reason, any explicitly excluded scope.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Dedup against confirmed-set only | Dedup against the full seen-set; a refuted site should never re-enter the pipeline |
| Stop after the first dry round | Require K=2 consecutive dry rounds; one dry round can be a coincidence |
| Silent coverage cap | State the cap and reason before the pipeline starts; log dropped items with count |
| Drop refuted candidates from output | Keep them with `status: refuted`; they are evidence the modality ran and the site was examined |
| Run all finders sequentially | Dispatch finders in parallel; sequential dispatch defeats the multi-modal diversity goal |
| Skip the completeness critic | Always run it after the loop; it is the only step that catches modality gaps the finders themselves cannot report |
| One finder failure aborts the whole pass | Catch per-finder errors; record `status: error` for that modality and continue with survivors |

## Proof

Hand off to `proof-gate` once the completeness critic confirms no open gaps.

The `PROVEN BY:` block must contain:
- List of modalities run with round count and new-findings count per round
- Total confirmed findings count vs. total candidates examined
- Total refuted candidates count
- Coverage ceiling (cap applied, or "no cap")
- Completeness critic verdict (gaps found or "none identified")
- Reference to the confirmed-findings log (file path or inline table)

> Example: `PROVEN BY: 4 modalities × 3 rounds (rounds 2–3 dry); 7 confirmed / 11 candidates; 4 refuted; no cap; critic: no gaps; findings log: audit-output.md`

## Adapt from
- **`semgrep/semgrep`** — multi-pattern static-audit engine (the by-pattern finder).
  <https://github.com/semgrep/semgrep>
- **`muratcankoylan/agent-skills-for-context-engineering`** — multi-modal sweep framing.
  <https://github.com/muratcankoylan/agent-skills-for-context-engineering>
