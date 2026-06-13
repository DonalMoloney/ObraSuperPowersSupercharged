---
name: database-migration-planner
description: Use when a schema change or migration is in scope (Alembic, Flyway, Prisma migrate, Liquibase, Rails db:migrate, raw DDL) — adds migration-specific risk assessment (destructive ops, lock/downtime, data backfill, step ordering) and a per-step rollback plan that feeds v1 writing-plans before any migrate command runs.
author: Donal Moloney
tier: v2
supports: [writing-plans, systematic-debugging]
type: process
pairs-with: blast-radius
---

## Not this skill if

- The change is generic multi-step work with no schema or migration file — write it with v1 **writing-plans** directly; this skill only adds the migration-risk layer on top.
- A migration already ran and is misbehaving — investigate with v1 **systematic-debugging** (root cause first), then come back here to plan the fix-forward or rollback.
- The schema design itself is not settled yet — settle it first; this skill plans how to ship a decided change safely, not what to change.

# database-migration-planner

## Purpose

Database migrations are the highest-risk changes in most production systems: a poorly ordered one locks tables, corrupts data, or forces downtime. v1 **writing-plans** produces a strong generic plan but does not reason about destructive DDL, table locks, backfill cost, or step reversibility. This skill is the migration-specific risk pass that runs *before* writing-plans turns the work into tasks: it classifies each operation, sequences it safely (expand → migrate → contract), and attaches an explicit rollback to every step.

**Core rule:** No `migrate` command is planned without a written rollback for each step and a confirmed backward-compatibility window. A migration with no rollback is a one-way door — name it as such.

## Inputs to gather first

Before classifying anything, collect (ask if unknown for a production target):

- **Migration tool + version** — Alembic / Flyway / Prisma migrate / Liquibase / Rails / raw SQL.
- **Target environment** — dev, staging, production. The plan differs sharply between them.
- **Per-table row counts and peak write rate** — this is what determines lock and backfill risk.
- **Consumers** — every app, service, and read replica querying the affected tables. A change safe for one consumer can break another.

## Procedure

### 1. Classify each operation

Assign every schema operation a risk tier. Record the tier in the plan.

| Tier | Operations | Stance |
|---|---|---|
| **Additive (low)** | Add nullable column, add index concurrently, add non-enforced constraint | Single step is acceptable; state that it is single-step |
| **Locking (medium)** | Add NOT NULL column with default, add enforced FK, rename column, create table | Requires expand→migrate→contract sequencing |
| **Destructive (high)** | Drop column/table, change column type, add NOT NULL to an existing column, large backfill | Requires explicit rollback DDL and a downtime/maintenance-window assessment |
| **Critical** | Any of the above on a large or high-write table | Phased plan + replica-lag check + explicit human sign-off before running |

If any operation is high or critical, surface it to the user before continuing.

### 2. Sequence safely (expand → migrate → contract)

For every medium-or-above operation, write the backward-compatible ordering so old and new code coexist:

- **Expand** — add the new structure non-breaking (new nullable column, new table).
- **Migrate** — dual-write from the app, then backfill existing rows in batches to avoid lock escalation.
- **Contract** — only after the new code is fully deployed, drop the old structure in a *separate* migration.

Renames, NOT NULL additions, and drops are never single-step on a populated table — split them across deploys. For additive operations, a single step is fine; say so explicitly.

### 3. Write a rollback per step

For every step, write the exact inverse, runnable without reading the forward migration:

```
Forward:  <SQL or CLI command>
Rollback: <exact inverse>
Data risk: none | recoverable | IRREVERSIBLE
```

Mark a step `recoverable` when its rollback needs data recovery (deleting a backfill, reversing a coercion), and `IRREVERSIBLE` when it destroys data with no mechanical inverse. Any `IRREVERSIBLE` step stops the plan until the user confirms a verified, restorable backup exists.

### 4. Call out backfill and downtime risk

State, per affected table: estimated migration runtime, whether the operation takes a lock (and of what kind), the acceptable lock-wait / replica-lag threshold, and whether a backfill runs hot (batched, throttled) or all-at-once. An unbounded backfill on a large table is a downtime event even when every individual DDL step looks "low".

### 5. Run blast-radius on the application side

The schema is half the change; the code that reads/writes those columns is the other half. Run v2 **blast-radius** on the application diff that goes with the migration to score how many callers depend on the affected columns/queries. A destructive schema step with a HIGH application blast radius needs the contract phase deferred until those callers are confirmed migrated.

### 6. Hand the sequence to writing-plans

Pass the classified, sequenced, rollback-annotated steps into v1 **writing-plans** as the task list. writing-plans owns task decomposition, file mapping, and commit cadence; this skill supplies the migration-safe ordering and the per-step rollback that writing-plans would not otherwise produce. Application-deploy steps and schema steps go into the *same* plan — they are one coupled system.

## Output

A migration plan block fed into v1 writing-plans, containing:

1. **Change summary + risk tier** — what changes, which tables, the highest tier present.
2. **Expand→migrate→contract sequence** — numbered, with app-deploy steps interleaved.
3. **Rollback table** — Forward / Rollback / Data-risk per step, IRREVERSIBLE steps flagged.
4. **Backfill + downtime notes** — runtime, lock kind, lag/wait thresholds per table.
5. **Open blockers** — unknown consumer, missing backup confirmation, or an unresolved IRREVERSIBLE step. The plan is not complete while this list is non-empty.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Treating "nullable column" as always safe | On a large table the engine may rewrite it — check the operation's lock behavior |
| Marking a DROP low because the table is small | Data destruction is at least high regardless of size |
| Writing the rollback after the forward step | The rollback must exist before the step is planned; no rollback means the step cannot run |
| Assuming rollback is the literal SQL inverse | Type coercions and constraint additions are often not mechanically reversible — verify each |
| Planning the schema change without the app deploy | They are coupled; one plan covers both, ordered so old and new code coexist |
| Running an unbounded backfill | Batch and throttle it; an all-at-once backfill is a downtime event |

## Proof

PROVEN BY: the forward migration applied cleanly on a staging environment with production-size data, the per-step rollback replayed cleanly on the same environment, and the open-blockers list empty — quoted as the migration-status command output before the plan is handed off.
