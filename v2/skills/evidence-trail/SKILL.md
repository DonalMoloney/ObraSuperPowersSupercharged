---
name: evidence-trail
description: Use across a multi-claim task when several "done and verified" claims accumulate — keeps an append-only, hash-chained log of every claim so editing an earlier one visibly breaks the chain, lets later claims reuse earlier proof safely, and renders the PR body / finish receipt straight from real evidence.
author: Donal Moloney
tier: v2
supports: [verification-before-completion, finishing-a-development-branch]
type: process
pairs-with: done-gate
---

## Not this skill if

- A single claim with one inline evidence block is enough — v1 **verification-before-completion** owns that single block; this skill is only worth it once several claims accumulate and you want them tamper-evident and reusable.
- You need a pass/fail decision at the "done" boundary — that is v2 **done-gate** (a completion GATE that runs the battery and routes review). This skill is the durable LOG the gate and the finish step read from, not a gate itself.
- The task has produced no verified claims yet — there is nothing to chain.

# Evidence Trail

## Purpose

v1 **verification-before-completion** proves one claim with one evidence block. Across a long task those blocks scatter: an earlier claim gets quietly edited to match a later one, a stale proof gets reused after the code under it changed, and at finish time the PR body is transcribed from memory. The evidence trail is one append-only, hash-chained log of every verified claim — each entry hashes the entry before it, so altering any past claim breaks every later hash and the tampering is visible at a glance. The same log renders the PR body / finish receipt and feeds v2 **done-gate**'s evidence check.

**Core rule:** append-only and chained. A claim is never edited in place; a superseding entry is appended, and every entry carries the hash of the one before it.

## Trail location and entry format

The trail lives at `docs/superpowers/EVIDENCE-TRAIL.json` in the project (create on the first verified claim). It is a single ordered array. Each entry:

```json
{
  "id": <N>,
  "claim": "<the assertion, verbatim — e.g. 'login redirects to dashboard after auth'>",
  "command": "<exact invocation: flags, env, paths — reproducible as written>",
  "output_hash": "<sha256 of captured stdout+stderr>",
  "code_hash": "<sha256 of the file(s) under test at run time>",
  "prev_hash": "<sha256 of the previous entry's JSON; null for id 0>",
  "timestamp": "<ISO-8601 UTC>",
  "status": "VALID | STALE | TAMPERED | SUPERSEDED",
  "superseded_by": <id or omitted>
}
```

Capture output with `command 2>&1` and hash both streams — silent failures often appear only on stderr. For a multi-file claim, set `code_hash` to the sha256 of each file's sha256 concatenated in alphabetical path order.

## Procedure

**Append (on each verified claim during the task):**
1. Run the proving command per v1 **verification-before-completion** — same evidence discipline, do not duplicate it here. Then append one entry. Set `prev_hash` to the sha256 of the previous entry's JSON (`null` for `id` 0). Increment `id`. Never insert, reorder, or overwrite existing entries.
2. To correct a claim that was wrong, append a fresh entry and mark the old one `SUPERSEDED` with a `superseded_by` pointer — never edit it.

**Reuse (before citing any earlier entry as proof):**
3. **Walk the chain** from `id` 0 to the target: recompute each `prev_hash` and compare to the next entry's `prev_hash`. On the first mismatch, mark that entry and every later one `TAMPERED` and stop — do not silently skip it.
4. **Stale check:** re-hash the file(s) under test in the current tree against the stored `code_hash`. On mismatch, mark the entry `STALE` and re-run the command, appending a fresh entry — a stale proof is not proof.

**Render (at finish / PR time):**
5. Filter to `VALID` entries and emit the evidence section for v1 **finishing-a-development-branch**'s PR body (or its local-merge receipt). Copy each `claim` verbatim; include `command`, `output_hash` (first 8 chars), and entry `id`. When v2 **done-gate** runs, point its evidence check at this trail rather than re-collecting proof.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Editing an old entry to "fix" a claim | Append a superseding entry; the old one stays with `status: SUPERSEDED` |
| Skipping the stale check because "nothing changed" | Always re-hash before reuse — mtimes lie and the check is cheap |
| Recording a command without its flags | Write the exact invocation so a re-run reproduces the evidence |
| Citing a TAMPERED entry in a PR | Walk the chain before finishing; stop and investigate at the first mismatch |
| Starting a trail for a one-claim task | Use v1 **verification-before-completion**'s single block instead — the trail earns its cost only across many claims |
| Letting the trail grow unbounded | Archive entries from prior branches to `EVIDENCE-TRAIL-archive.json`; keep the active file lean |

## After

Before closing a task that used this trail, run a final chain walk (step 3) and a stale check (step 4) on every entry you cite. Hand the rendered `VALID` evidence section to v1 **finishing-a-development-branch**, and let v2 **done-gate** read the trail for its evidence check.

PROVEN BY: the trail summary at task end — total entries with the VALID / STALE / TAMPERED / SUPERSEDED counts, "chain walk: no mismatches from id 0 to id <N>", and the rendered evidence lines (claim verbatim, command, `output_hash` first 8 chars, id) for each cited entry. An edited-in-place entry, or a cited entry that is not VALID, is invalid under this skill.
