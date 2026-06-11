---
name: write-adr
description: Author or update architecture decision records (ADRs) under docs/adr/ as NNN-kebab-case.md with Nygard-style Context, Decision, Consequences, and Status.
when_to_use: whenever recording a new decision, superseding an old one, capturing a rejected option, or editing anything under docs/adr/
version: 1.1.0
---

# Write ADR

## When to use

- A chat or design exploration reached a **conclusion** worth keeping (yes, no, defer, or "use X instead of Y").
- You need to **supersede** an older ADR without rewriting history.
- A **rejected** option should stay visible so the team does not revisit the same dead end.

Not every brainstorm needs an ADR — only decisions you want **git history and agents** to reuse.

## File location and naming

- Path: **`docs/adr/NNN-short-slug.md`** — three-digit zero-padded index, kebab-case slug (e.g. `001-managed-postgres.md`).
- Pick the **next** unused number. Never renumber published ADRs; add a new ADR that **supersedes** instead.

## Document structure (Nygard-style)

Use markdown with these sections (order flexible):

### Context

Problem, forces, constraints, what question was being answered.

### Decision

Clear statement of what was chosen (including "we will not implement X").

### Consequences

Positive and negative effects, follow-up work, coupling introduced.

### Alternatives considered (optional)

Brief bullets: what was considered and why it was not chosen.

## Status and supersession

Record status near the top:

| Status | Meaning |
|--------|---------|
| `Proposed` | Draft; not yet agreed. |
| `Accepted` | This is the active record (including "rejected feature" outcomes). |
| `Superseded by NNN-other-slug` | Replaced; link to the new ADR by filename. |
| `Deprecated` | No longer applies; one line why. |

When superseding:

1. Add new ADR with higher number; **Context** should cite the old ADR.
2. Update old ADR's status line to `Superseded by NNN-new-slug`.
3. Do not delete old ADRs — they're the record of what was considered.

## Example skeleton

```markdown
# ADR 008: Adopt managed Postgres for primary datastore

**Status:** Accepted

## Context

We need durable transactional storage for user and billing data. Running our
own Postgres adds oncall burden that doesn't match current team size.

## Decision

Use a managed Postgres offering (initial target: the cloud provider already
hosting the app). Review annually or when egress costs cross $X/month.

## Consequences

- + Backups, failover, and point-in-time recovery handled by the provider.
- + One less service to include in the oncall rotation.
- - Vendor lock-in on specific extension availability; portability audit required.

## Alternatives considered

- **Self-hosted on VMs** — lower monthly cost but higher operational load.
- **Serverless Postgres (e.g. Neon)** — attractive pricing but connection pooling didn't fit long-lived workers.
```

## Rejected decision example

Title can state the outcome:

> `# ADR 009: Do not introduce a separate event bus (for now)`

**Decision:** Keep using direct service-to-service calls. Revisit when a second consumer of any given event emerges, or when queue durability becomes a hard requirement.

This kind of ADR is valuable even though nothing ships from it — the next time someone proposes "let's add Kafka", the record explains why it was deferred and what would change the answer.

## Conventions

- Prefer **short** ADRs (roughly one screen); split only if appendices are huge.
- Link to roadmap ids or story ids when it clarifies scope.
- If your project uses conventional commits, `docs(adr):` scope is fine for ADR-only commits.
