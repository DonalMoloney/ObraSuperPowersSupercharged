---
name: post-merge-retro
description: Use when a branch has just been merged (or a PR opened and handed off) at the end of v1 finishing-a-development-branch — runs the ship checklist (changelog, release step, smoke check) and a structured retro that routes durable learnings into CLAUDE.md, skills, or the decision ledger instead of losing them.
author: Donal Moloney
tier: v2
supports: [finishing-a-development-branch]
type: process
pairs-with: decision-ledger
---

## Not this skill if

- The merge/PR decision has not been made yet — that is v1 **finishing-a-development-branch**; this skill starts where it ends.
- You are verifying the work itself is complete — that already happened at v2 **done-gate** / v1 **verification-before-completion**, before the merge.
- Something went wrong in production or during the work — that is v2 **incident-postmortem** (failure analysis); the retro is the routine learning loop for work that went fine.

# Post-Merge Retro

## Purpose

The core superpowers lifecycle ends at the merge/PR decision — nothing ships the change onward, and nothing captures what the feature taught. Deploy steps get forgotten, changelogs drift, and the same estimation mistake or codebase surprise repeats next feature because the learning lived only in a dead session. This skill is the explicit final beat: ship it properly, then harvest the learnings into places future sessions actually read.

**Core rule:** every checklist item ends in exactly one of two states — done with evidence, or skipped with a one-line reason. Silent skips are the failure mode this skill exists to kill.

## Procedure

**Ship checklist (run immediately after merge):**

1. **Changelog / release notes** — if the project keeps one, add the entry now. No changelog → skip explicitly ("no changelog in this project").
2. **Release step** — if a deploy/release/publish pipeline exists, run or trigger the project's documented step. No pipeline → skip explicitly.
3. **Post-merge smoke check** — run the project's verification command once on the merged main branch (not your feature branch — the merge itself can break things a green branch didn't show). Record the output.
4. **Cleanup confirmation** — confirm the worktree/branch cleanup from v1 **finishing-a-development-branch** actually completed: the feature branch and worktree are gone (unless the chosen option keeps them — then say so).

**Retro (three questions, answered in writing):**

5. **What did this feature teach?** Codebase surprises, wrong estimates, tooling friction, process snags — one line each, concrete.
6. **Which learnings are durable, and where do they live?** Route each one: project facts an agent needs every session → CLAUDE.md; a repeatable workflow rule → a skill (new or an edit proposal); a ratified choice with rejected alternatives → v2 **decision-ledger**. A learning with no route is noted as not-durable and dropped consciously.
7. **What was deferred?** List review items or follow-ups explicitly deferred during the work, each with where it is now recorded. "Nothing deferred" is a valid answer; an unrecorded deferral is not.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Skipping the smoke check because the branch was green | The merge is a new state; run the check on merged main |
| Writing the retro in the conversation and nowhere else | Learnings route to CLAUDE.md, a skill, or the ledger — the conversation dies, those don't |
| "Lessons learned" essays | One line per learning, each with a routing destination |
| Treating an empty retro as failure | A clean feature with no surprises is a fine outcome — record "no durable learnings" and close |
| Running the retro days later | Run it in the same session as the merge while the friction is still fresh |

## After

Verify every routed learning actually landed (the CLAUDE.md edit made, the ledger entry appended, the skill proposal recorded), then close out the session normally.

PROVEN BY: the pasted ship checklist (4 items, each done-with-evidence or skipped-with-reason) and the written three-question retro with a routing destination per durable learning. A closed-out feature with a silent skip or an unrouted learning is invalid under this skill.
