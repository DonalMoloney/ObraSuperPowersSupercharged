---
name: decision-ledger
description: Use when a design decision is approved or reversed during brainstorming, planning, or execution, and when resuming multi-session work — maintains an append-only DECISIONS.md so settled decisions survive across sessions instead of being re-derived or silently re-litigated.
author: Donal Moloney
tier: v2
supports: [brainstorming, writing-plans, executing-plans]
type: process
pairs-with: session-handoff
---

## Not this skill if

- You are transferring live working state to the very next session — that is v2 **session-handoff** (one-shot transfer); the ledger is durable memory across many sessions.
- The "decision" is an implementation detail nobody approved — code and specs record those; the ledger holds decisions a human ratified.

# Decision Ledger

## Purpose

Specs say what was decided; nothing records what was decided *against*, or why. Across sessions this rots: a fresh session re-proposes the rejected alternative, or quietly drifts from a settled choice. The ledger is an append-only log of ratified decisions — each with its rejected alternatives — read at resume time so settled questions stay settled.

**Core rule:** append-only. A reversed decision gets a new entry pointing at the old one; the old entry is never edited or deleted.

## Ledger location and entry format

The ledger lives at `docs/superpowers/DECISIONS.md` in the project (create on first entry). Each entry:

```markdown
## D-<NNN>: <decision in one line> — <YYYY-MM-DD>
- **Why:** <the reason in 1–2 sentences>
- **Rejected:** <alternative A> (<one-line reason>); <alternative B> (<one-line reason>)
- **Supersedes:** D-<MMM> (only when reversing a prior entry)
```

## Procedure

**Writing (during v1 brainstorming / writing-plans / executing-plans):**
1. When the user approves a design, a plan, or a mid-execution pivot, append one entry per ratified decision — including at least one rejected alternative each (a decision with no rejected alternative is usually a description, not a decision).
2. When a decision is reversed, append a new entry with `Supersedes:` — never edit the old one.

**Reading (at resume):**
3. On resuming work in a project that has a ledger, read it BEFORE proposing approaches.
4. If a new proposal contradicts a ledger entry, surface it explicitly: "This conflicts with D-<NNN> (<decision>). Reverse it?" — never silently re-litigate.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Logging every choice you make while coding | Only human-ratified decisions; the ledger is for what would otherwise be re-argued |
| Editing an entry that turned out wrong | Append a superseding entry; history is the point |
| Writing "Rejected: none" | Then it isn't a decision — drop the entry or find the alternative that was actually on the table |
| Reading the ledger only when confused | Read at every resume; confusion means it's already been re-litigated |

## After

Verify the ledger reflects this session: every user-ratified decision from the session has an entry, and no entry was edited in place.

PROVEN BY: the appended entries (with IDs) quoted at session end, and — on resume — the line "ledger read: D-001..D-<NNN>" before the first proposal. Proposing a rejected alternative without citing its entry is invalid under this skill.
