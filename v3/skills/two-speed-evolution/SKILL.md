---
name: two-speed-evolution
description: Use to run learning at two cadences — a free in-session observer that captures friction signals to a scratch queue with no gate, and a separate overnight pass that drains the queue, turns candidates into harness edits, and only commits what survives the eval suite and ledger gate.
tier: v3
status: experimental
---

# two-speed-evolution

Most self-improvement loops have one speed, and it is always the wrong one.
Run capture *and* gating in the live session and you burn main-thread tokens
on bookkeeping and let unverified "learnings" leak straight into the committed
harness. Run them only overnight and you lose the friction signals — the
"ugh, that broke again" moments — because they were never written down while
they were fresh.

This skill splits the loop into two cadences that never share a gate:

**FAST (in-session, ~free, no gate).** A background **Haiku** subagent watches
the session for friction signals — a command re-run after a failure, a hand
correction of Claude's output, a `# note`-style grumble, a test that flapped,
a tool call that was retried with different args. It writes each signal as one
append-only line to a **scratch queue** (described, not built — e.g.
`agent-memory/friction-queue.jsonl`). It never edits `CLAUDE.md`, never touches
a skill file, never proposes a fix. It only collects. Because it runs in its
own context window, deep observation does not pollute or consume the main
conversation's tokens — the same isolation trick that makes background
auto-memory affordable.

**SLOW (overnight, gated).** A separate `/loop` pass — not the live session —
drains the queue. It clusters the raw friction lines into candidate edits,
hands each candidate to the slow gated path (v3 `eval-gated-evolution-loop`):
apply on a branch, re-run the eval suite, keep only if the score rose,
otherwise revert and archive. Every kept edit is recorded against the ledger
(v3 `belief-ledger`-style prediction → outcome). Only this path is ever allowed
to change the committed harness.

```
LIVE SESSION                          OVERNIGHT /loop
  main thread does the work             drains friction-queue.jsonl
        │ friction happens              cluster lines → candidate edits
        ▼                               for each candidate:
  Haiku observer (own context)             apply on branch
        │ one line, no gate                run eval suite
        ▼                                  ledger: keep if score rose, else revert
  friction-queue.jsonl  ───────────────▶   commit survivors
        (cheap capture)                    (expensive gate)
```

## The load-bearing rule

**Capture is cheap and ungated; commits are expensive and gated, and the two
never touch the same write.** The fast path has *no* fitness signal on purpose
— it is collection only, write-anywhere-as-long-as-it-is-the-queue. The slow
path has the *only* fitness signal: the eval suite plus the ledger gate. A
friction line is a hypothesis, not a decision; nothing in the queue is ever
trusted until the slow path measures it against the suite. This is the wall
that keeps real-time noise out of the verified harness.

## Fitness signals (explicit)

| Path | Cadence | Fitness signal | May change committed harness? |
|------|---------|----------------|-------------------------------|
| FAST | in-session | **none** — collection only | **no** (queue file only) |
| SLOW | overnight `/loop` | eval suite score rose + ledger prediction confirmed | **yes** |

If the fast path ever acquires a gate, it has stopped being the fast path. If
the slow path ever skips the suite, it has stopped being the gate.

## Boundary with neighbours

- **v3 `eval-gated-evolution-loop`** is the *engine* of the slow path: mine →
  diagnose → propose → gate → revert/keep. This skill is the *cadence
  architecture* that feeds it a pre-collected queue instead of making it
  re-discover friction from cold traces. Two-speed is the clock; eval-gated is
  the motor.
- **v3 `inherited-instincts`** is the *learned genome* — the durable
  pattern→emotion reflexes that have already survived selection. This skill is
  not a genome; it is the *pipeline* by which a raw friction line might, after
  surviving the overnight gate, eventually earn its way into being an instinct.
  Instincts are the output of many gated cycles; the friction queue is the raw
  intake before any gate.
- **v2 `session-handoff`** carries *state* across a session boundary for the
  same human to resume work. This skill carries *friction signals* across the
  session→overnight boundary for the machine to evolve the harness. Handoff is
  "where was I"; the friction queue is "what kept hurting." They can coexist —
  a handoff block can note "N friction signals queued for tonight's loop."

## Why this might be crazy enough to work

Single-speed loops fail at opposite ends: a live gate is too expensive to run
on every grumble, and an overnight-only loop has already forgotten the grumble
by the time it runs. Decoupling the cadences lets capture be as cheap as a log
append (so you can afford to capture *everything*) while keeping the commit
path as expensive and honest as it needs to be (so nothing unverified ever
ships). The Haiku observer is affordable precisely because it has no
responsibility beyond writing one line, and the eval-gated `/loop` is trustworthy
precisely because it does not have to also be fast. The wall between them — a
plain append-only queue file that one side only writes and the other side only
reads-then-clears — is the entire mechanism, and it is boringly robust.

## Known risks / open questions

- **Queue noise.** With no gate on capture, the queue fills with junk — every
  retry, every typo, every transient flake becomes a line. The overnight
  clustering step has to do real work to separate signal from noise, and a
  badly-clustered queue could waste the whole gated budget on non-issues.
  *Open: dedup/decay on the queue, or a cheap relevance filter at drain time?*
- **Observer cost and intrusiveness.** "Free" is optimistic — a Haiku subagent
  watching every turn is cheap, not free, and a chatty observer could still add
  latency or its own tokens. *Open: sample turns instead of watching all of
  them? Trigger only on detectable friction events (retries, corrections)?*
- **Drift between fast capture and slow gate.** A friction line captured Tuesday
  may be stale by Friday's `/loop` — the code it complained about may already be
  gone, or the context that made it friction may have changed. The slow path can
  gate against the *current* suite and silently "fix" something that no longer
  exists. *Open: timestamp + staleness expiry on queue lines; re-validate the
  friction still reproduces before spending a gate on it.*
- **Two-clock confusion.** If a human edits the harness between the capture and
  the overnight run, the slow path may propose an edit that conflicts with
  manual work. *Open: does the loop rebase its candidates onto the latest
  harness before gating?*
- **Silent observer failure.** If the Haiku observer dies mid-session, capture
  stops with no error on the main thread — the loop just quietly learns nothing
  that night. *Open: a heartbeat / "queue grew today?" check.*

## Likely graduation criteria (v3 → v2)

Promote to v2 when:

1. The fast path demonstrably costs near-zero on the main thread (measured token
   delta) and the queue captures friction that a human agrees was real friction.
2. The overnight `/loop` drains the queue and produces edits that the gate keeps
   at a rate clearly above what a from-cold-traces loop produces — i.e. the
   pre-collected queue measurably improves the slow path's hit rate.
3. The staleness and noise problems above have concrete, tested answers (decay
   policy + re-validation step), not just open questions.
4. At least one kept edit can be traced end-to-end: friction line → cluster →
   candidate → suite-confirmed → ledger CONFIRMED → commit. Once that audit
   trail is real and the wall between cadences has held under use, this is a
   supporting-architecture skill, which is a v2 identity, not a v3 experiment.
