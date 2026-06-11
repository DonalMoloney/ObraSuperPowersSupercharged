---
name: reviewer-lenses
description: Use when requesting code review of significant or high-risk work and a single general-purpose reviewer would blur distinct concerns — dispatches parallel reviewers each locked to ONE lens (correctness, architecture, security, test quality, product/UX) and merges their findings.
author: Donal Moloney
tier: v2
supports: [requesting-code-review, dispatching-parallel-agents]
type: technique
chains-to: merge-parallel-results
---

## Not this skill if

- The change is small or routine — a single reviewer via v1 **requesting-code-review** is cheaper and sufficient.
- The artifact under attack is a spec or design doc — that is v2 **red-team-spec** (pre-implementation); lenses review code (post-implementation).

# Reviewer Lenses

## Purpose

A single reviewer asked to check "everything" anchors on whatever they notice first, and the other concerns get a skim. Lenses fix this by dispatching one reviewer per concern, each with a deliberately narrow prompt, in parallel per v1 **dispatching-parallel-agents** — then merging via v2 **merge-parallel-results**.

**Core rule:** each lens reviews ONLY its concern. A security reviewer who reports style nits has been prompted wrong.

## The five lenses

| Lens | Sole question | Reports |
|---|---|---|
| Correctness | Does the code do what the requirements say, including edge cases? | Logic errors, unhandled cases, off-by-ones, wrong behavior |
| Architecture | Do boundaries, dependencies, and ownership make sense? | Coupling, leaky abstractions, wrong-layer logic, god objects |
| Security | What can an adversary do with this change? | OWASP-style checks: injection (including prompt injection via tool output), authz/authn gaps, secrets handling, unsafe input paths |
| Test quality | Would these tests catch the bugs that matter? | Untested branches, assertion-free tests, mock-heavy tests, missing failure cases |
| Product/UX | Does this serve the user's actual goal? | Confusing flows, surprising defaults, error messages a user can't act on |

## Procedure

1. Decide significance: multi-file change, new subsystem, security-adjacent surface, or anything heading to production review. If not significant, use v1 **requesting-code-review** alone.
2. Pick lenses. Default: correctness + architecture + test quality. Add security when input handling, authn/authz, or secrets are touched; add product/UX when user-facing behavior changed. Drop a lens only with a stated reason.
3. Dispatch one reviewer subagent per lens, in parallel, per v1 **dispatching-parallel-agents**. Each prompt contains: the diff or file list, the requirements, the lens's sole question from the table, and the instruction "report ONLY findings under this lens; if none, say none."
4. Collect all returns and merge via v2 **merge-parallel-results** — dedupe overlap, keep per-lens provenance on every finding.
5. Process the merged report via v1 **receiving-code-review** (unclear items go through v2 **review-clarification-gate** before implementation).

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| One agent given all five lenses "to save dispatches" | That's the anchoring problem again with extra steps — one lens per agent |
| All five lenses on every change | Lens count scales with risk; three is the default, five is for genuinely risky work |
| Discarding the lens label when merging | Provenance tells you who to re-ask and how to weigh conflicts |
| Treating "none" from a lens as a wasted dispatch | A clean security pass on an auth change is the most valuable line in the report |

## After

Verify lens discipline held: every merged finding carries its lens label, and any lens that found nothing said "none" explicitly. Then chain to v2 **merge-parallel-results** output handling and v1 **receiving-code-review**.

PROVEN BY: the merged report with per-lens provenance and an explicit entry (findings or "none") for every dispatched lens. A missing lens entry means a dispatch silently failed — re-dispatch it.
