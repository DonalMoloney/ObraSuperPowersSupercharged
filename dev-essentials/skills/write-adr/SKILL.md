---
name: write-adr
description: Use when a significant architectural choice is being made — library selection, pattern adoption, infra decision, API contract, or any decision whose rationale will not be obvious in three months — to produce a permanent record of context, options, decision, and consequences.
---

## Not this skill if
- The decision is reversible with low cost and leaves no lasting constraint — use a code comment instead
- You are *reviewing* an existing ADR — open the file directly and edit it
- The decision is already recorded in an existing ADR at sufficient detail — check there first

# write-adr — Architecture Decision Record author

## Purpose

Decisions made under time pressure are forgotten. The reasons for a library choice, a pattern adoption, or an infra call are obvious today and invisible six months later. An ADR captures the moment the decision was made: what was known, what was considered, what was chosen, and what that choice costs.

One ADR per decision. Decisions that feel like "just using X" are the most important ones to record — those are load-bearing beliefs masquerading as defaults.

## Core rule

> **Rule:** No architectural decision ships without an ADR. A decision without a record is a debt with no ledger entry.

## Process

1. **Name the decision** — one sentence, present tense, declarative. "Use PostgreSQL as the primary datastore." Not "database decision" — name the actual choice.

2. **State the context** — what forces, constraints, or conditions made this decision necessary right now? Include: current scale, existing stack, team constraints, and any time pressure. Two to five sentences.

3. **List the options considered** — at least two alternatives. For each option state: what it is, why it was considered, and one key advantage and one key disadvantage. Use the options table in the template below.

4. **State the decision** — one sentence. Imperative. "Use PostgreSQL." Not "we have decided to use…".

5. **State the consequences** — positive and negative in separate lists. Positive: what the decision enables or simplifies. Negative: what it costs, locks in, or makes harder. Be honest about the negatives — a one-sided ADR is a marketing document.

6. **State the status** — `Proposed`, `Accepted`, or `Superseded by ADR-YYYY-MM-DD-<slug>`.

7. **Save the file** to `docs/decisions/YYYY-MM-DD-<slug>.md` where `<slug>` is a short kebab-case identifier matching the decision title. Create `docs/decisions/` if it does not exist.

8. **Emit confirmation:**
```
ADR saved: docs/decisions/<filename>
Decision: <one-sentence decision>
Status: <status>
```

## ADR template

Copy this block, fill every field, delete no sections:

```markdown
# ADR — <Decision title, present tense>

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Superseded by ADR-YYYY-MM-DD-<slug>
**Deciders:** <names or roles — at minimum "agent" if no human named>

## Context

<2–5 sentences. What situation, constraint, or requirement makes this decision necessary? What would happen if no decision were made?>

## Options considered

| Option | Advantage | Disadvantage |
|--------|-----------|--------------|
| <Option A> | <key advantage> | <key disadvantage> |
| <Option B> | <key advantage> | <key disadvantage> |
| <Option C — if applicable> | <key advantage> | <key disadvantage> |

## Decision

<One sentence. Imperative. State the option chosen and the primary reason.>

## Consequences

**Positive:**
- <What this enables or simplifies>
- <What constraint is lifted>

**Negative:**
- <What is now harder or locked in>
- <What future option is closed>

## Supersedes

<Link to any ADR this replaces, or "none">
```

## Failure modes

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| ADR written after the fact to justify an already-implemented choice | Author reconstructing context from memory | Write the ADR at the moment of decision, not after implementation |
| Only one option listed | Author rationalising a preference | List at least two real alternatives, even if one was rejected quickly |
| Consequences section lists only positives | Author avoiding accountability | Negatives are mandatory; a decision with no negatives was not a real trade-off |
| ADR never referenced again | Not linked from the relevant code or CLAUDE.md | Add a comment in the affected file: `# See docs/decisions/<slug>.md` |
| Status never updated | No review trigger | Set a review date, or register the riskiest consequence as a tracked assumption to revisit |

## Integration

- Register any unverified assumption embedded in the ADR (e.g. "we assume traffic will not exceed X") somewhere you will revisit it
- The ADR directory (`docs/decisions/`) — ADRs are the canonical record; the directory itself is the index
- The **writing-plans** skill — open architectural decisions should be resolved before the implementation plan is finalised; write the ADR first
- The **verification-before-completion** skill — the ADR itself is evidence of a deliberate decision; cite it in the evidence block when the decision is the claim
