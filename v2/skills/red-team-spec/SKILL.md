---
name: red-team-spec
description: Use when a spec or design doc is at "ready for review" and has not yet been attacked adversarially — spawn N independent adversarial agents to find edge cases, invalid assumptions, security holes, and fatal ambiguities before the spec is locked.
author: Donal Moloney
tier: v2
supports: [brainstorming, writing-plans, dispatching-parallel-agents]
type: process
chains-to: writing-plans
---

## Not this skill if
- You need one agent to ask probing questions about the idea itself — that is v1 **brainstorming**; red-teaming is a multi-agent parallel attack, not a dialogue.
- The spec is a rough one-pager not yet ready for structured criticism — run v1 **brainstorming** first to solidify the shape, then come back here.
- The spec is already in implementation and the question is whether the code matches it — use v1 **verification-before-completion** instead.

# red-team-spec — adversarial parallel spec attack

## Purpose

A spec that survives one reviewer's questions can still carry a fatal flaw the reviewer didn't think of. This skill spawns multiple independent adversarial agents, each attacking from a different angle — security, edge cases, assumptions, ambiguity — simultaneously. No agent coordinates with another before reporting. You then consolidate all findings, demand a written response to every one, and block finalisation until every finding is either fixed or explicitly risk-accepted. The result is a spec with a documented attack surface, not a spec that "looks fine."

Supports v1 **brainstorming** (hardens the design that skill produced), v1 **writing-plans** (the locked spec is the plan's input), and applies v1 **dispatching-parallel-agents** for the attack fan-out.

## Core rule

> **Rule:** No finding can be silently dropped. Every adversarial finding must receive a written disposition — `FIXED`, `ACCEPTED (risk:` … `)`, or `REJECTED (reason:` … `)` — before the spec is marked final.

## Triggers

**Use when:**
- A spec or design doc is at "ready for review" but has not yet been attacked adversarially
- The feature touches security, auth, data integrity, or concurrency — areas where a single reviewer's blind spots can be catastrophic
- The team has already read the spec and is optimistic about it — optimism is the right time to attack, not after implementation starts
- Post-**brainstorming**, when the surviving design should be hardened before v1 **writing-plans** locks the plan

**Don't use when:**
- The spec has fewer than three non-trivial decisions — the overhead of spawning agents outweighs a quick manual review
- The document is a changelog, release note, or internal housekeeping doc with no system behaviour described
- You are mid-implementation and want to evaluate the running code, not the spec

## The pattern

### Step 1 — Extract the attack surface

Read the full spec. Pull out every explicit decision, every implicit assumption, every stated constraint, and every behaviour the spec does not address. Record these as the **attack surface list** before spawning any agent. Do not filter; include items that seem obvious. This list is the shared seed for all adversarial agents.

Sub-steps:
- List every input boundary: data types, size limits, encoding, source trust level.
- List every state transition: what triggers it, what guards it, what happens if the guard is bypassed.
- List every external dependency: third-party APIs, databases, clocks, queues, user-supplied data.
- List every constraint described as "should" or "typically" rather than "must" — these are weak guarantees and prime attack targets.

### Step 2 — Assign attack roles and spawn agents in parallel

Assign each agent a single adversarial role. Roles must not overlap — each agent attacks from exactly one angle. Default role set:

| Role | Focus |
|---|---|
| Security attacker | Auth bypass, injection, privilege escalation, data leakage, trust boundary violations |
| Edge-case hunter | Empty inputs, boundary values, concurrent requests, partial failures, retry storms |
| Assumption auditor | Statements the spec treats as given but never verifies — timing, ordering, availability, user behaviour |
| Ambiguity extractor | Terms used inconsistently, behaviours left undefined, success conditions that cannot be measured |
| Integration skeptic | Contracts with external systems — what happens when the external system violates its stated contract |

Spawn all agents in parallel via v1 **dispatching-parallel-agents**. Each agent receives: the full spec text, the attack surface list from Step 1, its assigned role, and this instruction: "Return a numbered finding list. Each finding: one sentence stating what is wrong, one sentence stating the worst-case consequence, one sentence stating what a fix or mitigation would look like. Do not coordinate with other agents. Do not self-censor findings because they seem unlikely."

Scale the agent count to spec complexity: for specs under 500 words, three roles are sufficient (security, edge-case, ambiguity). For specs over 2000 words or touching distributed systems, add the integration skeptic and consider splitting the security role into authentication and data integrity sub-agents.

### Step 3 — Collect and deduplicate findings

After all agents return, consolidate their finding lists into a single numbered master list (the v2 `merge-parallel-results` skill is the general-purpose form of this step). Merge findings that describe the same flaw from different angles — keep the sharper of the two descriptions and note which agents both flagged it (overlapping findings signal higher-confidence vulnerabilities). Do not discard any finding at this stage, even ones that seem far-fetched. Assign each finding a severity:

- **CRITICAL** — could cause data loss, security breach, or complete feature failure at runtime
- **HIGH** — would require a design change to fix; cannot be patched with a one-line guard
- **MEDIUM** — requires a code-level fix but no design change
- **LOW** — a clarification or tightening of language that prevents future misreading

### Step 4 — Present findings to the spec author and demand dispositions

Send the consolidated master list to the spec author (or, in an automated pipeline, treat the invoking agent as the author). For each finding, require a written disposition using one of these exact forms:

- `FIXED — <one sentence describing what changed in the spec>`
- `ACCEPTED (risk: <one sentence describing what you are accepting and why it is tolerable>)`
- `REJECTED (reason: <one sentence explaining why the finding is invalid or already handled>)`

Do not accept "will fix later" or "good point" as dispositions. A finding without a disposition blocks Step 5.

### Step 5 — Re-attack ACCEPTED findings

For every finding marked `ACCEPTED`, spawn a single follow-up agent whose only job is to verify that the risk acceptance statement is coherent and that the accepted risk does not interact with any other accepted risk to produce a combined failure mode. If the follow-up agent finds an interaction, escalate that finding to CRITICAL and return to Step 4 for those items only.

### Step 6 — Emit the final attack report and lock the spec

Produce the attack report (see Verification section) and attach it to the spec as an appendix or linked document. The spec is not final until the attack report exists and every finding in it carries a disposition. Hand off to v1 **writing-plans** when the spec is ready to become a work breakdown.

## Common mistakes

| ❌ Mistake | ✅ Fix |
|---|---|
| Spawning agents before extracting the attack surface | Build the shared attack surface list first; agents without a seed produce shallow, overlapping findings |
| Letting agents read each other's output before reporting | Enforce no-coordination; cross-contamination collapses N independent perspectives into one |
| Accepting "we'll handle it in implementation" as a disposition | Require `FIXED`, `ACCEPTED`, or `REJECTED` with explicit text; deferred dispositions are invisible risk |
| Treating a CRITICAL finding as low priority because it seems unlikely | Severity is about consequence, not probability; a low-probability catastrophic failure is still CRITICAL |
| Skipping the Step 5 re-attack on ACCEPTED findings | Accepted risks can interact; two tolerable individual risks can combine into an intolerable compound failure |
| Marking the spec final before the attack report is attached | The attack report is the proof; a spec without one has no documented evidence that adversarial review happened |
| Using fewer than three roles for a complex spec | Under-staffing the attack leaves entire dimensions uninspected; match role count to spec surface area |

## Verification

The `PROVEN BY:` block must contain:

- The attack surface list produced in Step 1 (or a link to it if it is long)
- The list of adversarial roles assigned and the agent count spawned
- The total finding count per role and per severity tier (CRITICAL / HIGH / MEDIUM / LOW)
- The full consolidated finding list with finding text and final disposition for every item
- For any finding marked `ACCEPTED`: the risk acceptance statement and the result of the Step 5 re-attack (clean or escalated)
- The name of the spec version or document hash the attack was run against (so the report cannot be silently applied to a revised spec)

Example skeleton (replace with real run output):

```
PROVEN BY:
  spec: auth-redesign-v3.md (sha256: a3f1...)
  attack surface: 14 items extracted (see attached list)
  agents spawned: 5 (security, edge-case, assumption, ambiguity, integration)
  findings: CRITICAL 2 | HIGH 4 | MEDIUM 5 | LOW 3
  dispositions: 9 FIXED | 3 ACCEPTED | 2 REJECTED
  ACCEPTED re-attack: 3 accepted risks reviewed — no compound failure found
  spec locked: 2026-05-30
```

## Related

- v5 `devils-advocate` — single-agent counterargument generation; this skill extends the idea to N parallel agents with role specialisation.
