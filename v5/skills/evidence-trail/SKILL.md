---
name: evidence-trail
description: Use across a task — every "done and tested" claim is appended to one hash-chained list so editing an old claim visibly breaks the chain, and PR notes write themselves from real evidence. Flags stale proof when code changed after the test ran.
author: Donal Moloney
track: proof
type: support
chains-to: write-pr-notes
---

## Not this skill if
- A one-off claim with inline `PROVEN BY:` is enough — no trail needed
- You are auditing files in bulk rather than recording evidence for discrete claims — use `map-reduce-sweep` instead
- The session has no completion claims yet — nothing to trail

# evidence-trail — one tamper-evident proof spine

## Purpose

Give `proof-gate`, `decision-ledger`, and `write-pr-notes` a shared, append-only evidence record that
can't be silently edited and that feeds PR notes automatically.

Each verified claim produces one entry in an ordered list. Every entry carries a pointer to the one
before it. Altering any past entry invalidates every entry after it, making tampering visible at a
glance. At PR time the same list renders directly into `write-pr-notes` `PROVEN BY:` blocks — no
manual transcription, no missing evidence.

## Core rule

> **Rule:** Proof is only valid if the code under test is unchanged since the run. If the file's mtime
> (or hash) changed after the recorded run, mark the proof STALE and require a re-run.

## Triggers

**Use when:**
- You are about to write "done" or "verified" for any subtask — append before you move on
- You are reusing a prior proof block from an earlier session or earlier in the same session
- You are opening a PR and need to populate `PROVEN BY:` blocks
- `proof-gate` fires and asks for an evidence reference — point it at this trail
- `decision-ledger` records a decision — attach the matching trail entry so the decision is grounded

**Don't use when:**
- The task has a single claim and inline `PROVEN BY:` is sufficient — avoid trail overhead for trivial cases
- You have no command output to record — an empty entry adds noise, not signal

## Algorithm

**Hash chain:** each entry stores `{claim, command, output_hash, code_hash, prev_hash}`:
- `claim` — the human-readable assertion ("login redirects to dashboard after auth")
- `command` — the exact shell command or test invocation that produced evidence
- `output_hash` — SHA-256 of the captured command output (stdout + stderr)
- `code_hash` — SHA-256 of the file(s) under test at the moment the command ran
- `prev_hash` — SHA-256 of the previous entry's canonical JSON; `null` for entry 0

**Stale check:** compare the recorded `code_hash` against `sha256sum <file>` on the current working tree.
Any mismatch marks the entry `status: STALE`.

## Steps

### 1. Initialise the trail (first claim in a session)

Create a file `evidence-trail.json` in the repo root or in `.claude/` if the project uses that
directory. Write a single-element array containing entry 0:

```json
[
  {
    "id": 0,
    "claim": "<human-readable assertion>",
    "command": "<exact command run>",
    "output_hash": "<sha256 of stdout+stderr>",
    "code_hash": "<sha256 of file(s) under test>",
    "prev_hash": null,
    "timestamp": "<ISO-8601>",
    "status": "VALID"
  }
]
```

Capture command output to a temp file, hash it with `sha256sum`, then discard the temp file. Record
the command verbatim — if you ran `npm test -- --testPathPattern=auth`, write exactly that.

### 2. Append on each new verified claim

For every subsequent completion claim, read the last entry from the array. Compute:

```
prev_hash = sha256( JSON.stringify(last_entry, null, 2) )
```

Append a new entry with that `prev_hash`. Increment `id` by 1. Do not overwrite, insert, or reorder
existing entries — append only.

If the claim covers multiple files, compute `code_hash` as `sha256( sha256(file1) + sha256(file2) + ... )`
concatenated in alphabetical path order.

### 3. Recompute the chain before reusing any proof

Before citing an existing trail entry as evidence, walk the chain from entry 0 to the target entry:

- Recompute each `prev_hash` from the stored entry JSON.
- Compare against the `prev_hash` field of the next entry.
- If any comparison fails, mark every entry from the failure point onward `status: TAMPERED`.

Stop at the first failure. Do not silently skip it.

### 4. Run the stale check before reusing proof

For each entry you plan to cite:

1. Run `sha256sum <file(s) under test>` on the current working tree.
2. Compare to the stored `code_hash`.
3. If they differ, set `status: STALE` on that entry and refuse to cite it as valid proof.
4. Re-run the original command, capture fresh output, and append a new entry replacing the stale one — do not mutate the old entry.

### 5. Render into `write-pr-notes` at PR time

Filter the trail to entries with `status: VALID`. For each, emit one `PROVEN BY:` block:

```
PROVEN BY: <command> — output_hash <first 8 chars> — entry <id>
```

Group by feature area if the trail has more than five entries. Pass the rendered block list to
`write-pr-notes` as the evidence section. Do not paraphrase claims — copy them verbatim from the
`claim` field.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Mutating an old entry to "fix" a claim | Append a new entry; leave the old one with `status: SUPERSEDED` and a `superseded_by` pointer |
| Skipping the stale check because "nothing changed" | Always re-hash; file mtimes can be wrong; the check is fast |
| Recording the command without its flags | Write the exact invocation — flags, env vars, file paths — so re-runs are reproducible |
| Citing a TAMPERED entry in a PR | Walk the chain before PR creation; stop at the first failure and investigate before merging |
| Letting the trail grow unbounded across many sessions | Archive entries older than the current branch to `evidence-trail-archive.json`; keep the active file under 200 entries |
| Hashing stdout only and missing stderr | Capture both with `command 2>&1 | sha256sum`; silent test failures often appear only in stderr |

## Verification / Proof

The trail is self-verifying. Before closing any task that used this skill, run a final chain walk
(Step 3) and a stale check on every cited entry (Step 4). Hand off to `write-pr-notes` once all
cited entries read `status: VALID`.

The `PROVEN BY:` block for a session that used this skill must contain:

- Total entry count and count of VALID / STALE / TAMPERED entries
- The rendered `PROVEN BY:` line for each VALID entry cited in the PR
- The `output_hash` (first 8 chars) and `code_hash` (first 8 chars) for each cited entry
- Confirmation that the chain walk found no hash mismatches

```
PROVEN BY:
  - Trail entries: <N total> (<V> VALID, <S> STALE, <T> TAMPERED)
  - Chain walk: no mismatches from entry 0 to entry <N-1>
  - Cited entries: [<id>: <command> — out:<hash8> code:<hash8>], ...
  - Rendered into write-pr-notes: yes
```

## Adapt from
- **`moonrunnerkc/swarm-orchestrator`** — verifies every claim against evidence and gates merges.
  <https://github.com/moonrunnerkc/swarm-orchestrator>
