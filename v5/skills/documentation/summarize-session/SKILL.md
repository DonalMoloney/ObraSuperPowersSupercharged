---
name: summarize-session
description: After a design, research, or prioritisation thread, evaluate whether the conversation produced durable insight worth capturing in docs/, then propose only the artifacts that are clearly justified.
when_to_use: when the user says "wrap this session", "propose docs artifacts", "what should we capture", "summarize this into docs", or similar close-out phrasing
version: 1.1.0
---

# Summarize Session

## When to use

- The conversation reached a **conclusion** worth capturing (architecture, research synthesis, business decision, story scope, backlog update)
- The user invokes this skill or asks to **wrap this session** / **propose docs artifacts** / **what should we capture** / **summarize this discussion into docs**
- Typical triggers: architecture or product discussion concluded (or deferred with rationale), research synthesis, or reprioritisation

**Default:** propose artifacts **only if necessary**. Do not invent work to document.

## Gate checklist

Answer each question only from the visible thread. If the answer is "no" for all → say so in one sentence and stop.

1. **ADR** — Did the thread reach an **architecture / process / stack** conclusion worth git history? (Includes "we will not do X".)
2. **Research** — Is there **durable synthesis** (comparisons, constraints, citations) that is **not** a single sharp decision?
3. **Reference** — Is there **operational or eval** depth better as a living doc than an ADR or a story?
4. **Story** — Is there a **bounded deliverable** with testable acceptance criteria not already covered?
5. **Backlog / queue** — Did priorities or **P-tier status** change in a way that belongs in the tables?

## Output format

1. **Summary** — One short paragraph: what (if anything) is worth capturing.

2. **Proposals table** (omit rows with no proposal):

   | Artifact | Proposed path | Why (one line) | Follow |
   |----------|---------------|----------------|--------|
   | ADR / Research / Reference / Story / Backlog | e.g. `docs/adr/004-foo.md` | … | link to relevant skill or docs overview |

3. **Do not write files** unless the user explicitly asks to create or update them in the same turn. Offer drafts only.

4. If proposing an ADR, use `write-adr` skill.

5. If proposing a story, consider updating `docs/backlog.md` status and `docs/queue.md` pick-next order.

## Exit (nothing to capture)

If no row in the proposals table applies, respond with **one or two sentences** only, e.g. *"No durable decisions or synthesis in this thread; nothing to add to `docs/`."* — then **stop**.

## Docs map (where things go)

| Kind | Path | Use for |
|------|------|---------|
| **ADR** | `docs/adr/NNN-slug.md` | A **decision** to freeze (chosen option, deferral, or rejected approach). |
| **Research** | `docs/research/<topic>.md` | **Exploration / comparison / notes** without a single "we decided X". |
| **Reference** | `docs/reference/<topic>.md` | **Engineering** notes (runbooks, eval harnesses) not framed as an ADR. |
| **Story** | `docs/stories/<slug>.md` | **Trackable scope** with acceptance criteria. |
| **Backlog / queue** | `docs/backlog.md`, `docs/queue.md` | P-tier rows, status, ordered "pick next". |
