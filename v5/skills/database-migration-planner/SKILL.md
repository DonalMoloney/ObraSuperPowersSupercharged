---
name: database-migration-planner
description: Use when schema changes, new migrations, or migration tool commands (Alembic, Flyway, Prisma migrate) are in scope — produces a risk-assessed plan with a rollback path, zero-downtime steps, and a verified test checklist before any migration runs.
author: Donal Moloney
track: A
type: process
chains-to: verify-before-done
---

## Not this skill if
- The change is purely application code with no schema or migration file involved — use `execute-plan` instead.
- You are reviewing a migration that already ran — use `find-root-cause` to investigate instead.
- You have not yet decided what the schema should look like — use `brainstorming` or `challenge-spec` first to settle the design.
- The migration is a single trivial rename with no production data in the table — a plan is still recommended but you can skip to the verification checklist directly.

# database-migration-planner — plan before you migrate

## Purpose

Database migrations are the highest-risk changes in most production systems. A poorly ordered migration can lock tables, corrupt data, or require hours of downtime. This skill forces the planning work first: risk level, rollback path, zero-downtime ordering, and a verification checklist — before any `migrate` command runs.

## Core rule

> **Rule:** Never run a migration command until the rollback plan exists in writing and the backward-compatibility window is confirmed. A migration with no rollback plan is a one-way door.

## When to use

- Any `alembic upgrade`, `flyway migrate`, `prisma migrate deploy`, `rails db:migrate`, or equivalent command is about to run.
- A schema change file (`.sql`, `.xml`, migration Python/TypeScript) is being added or modified.
- The user mentions "migration", "schema change", "adding a column", "dropping a table", "rename", "index", or "foreign key" in a production-database context.
- The migration affects a table that already holds live data.
- Multiple applications or services share the schema being changed.

## Steps

### 1. Gather migration context

Before producing any plan, collect:

- **Migration tool** — Alembic / Flyway / Prisma / Liquibase / Rails / raw SQL. Note the exact version if relevant.
- **Target environment** — local dev, staging, production. The plan changes significantly between them.
- **Table sizes and traffic** — approximate row counts and peak read/write rate for every affected table. This determines lock risk.
- **Consumers** — list every application, service, or read replica that queries the affected tables. A change safe for one consumer may break another.
- **Existing migration history** — read the current migration state (`alembic current`, `flyway info`, `prisma migrate status`) so the plan starts from an accurate baseline.

Do not produce a plan with unknown consumers or unknown table sizes for a production migration. Ask before proceeding.

### 2. Classify the change

Assign each schema operation to a risk tier:

| Tier | Operations | Default stance |
|---|---|---|
| **Low** | Add nullable column, add index (concurrent), add non-enforced constraint | Safe to run; document and verify |
| **Medium** | Add non-nullable column with default, rename column (two-phase), add enforced foreign key, create table | Requires zero-downtime sequencing |
| **High** | Drop column, drop table, change column type, remove default, add NOT NULL to existing column, large backfill | Requires explicit rollback SQL and a maintenance-window assessment |
| **Critical** | Any of the above on a table > 10 M rows or under active high-write traffic | Requires a phased plan, replica lag check, and human sign-off before running |

Record the tier in the plan output. If any operation is High or Critical, escalate to the user before continuing.

### 3. Write the zero-downtime strategy

For every operation rated Medium or above, describe the backward-compatible ordering. Common patterns:

**Column rename (two-phase):**
1. Add the new column (nullable).
2. Dual-write: application writes both old and new column.
3. Backfill existing rows.
4. Switch application reads to the new column.
5. Remove the old column in a separate migration after the application is fully deployed.

**Add NOT NULL column:**
1. Add the column as nullable.
2. Backfill a default for all existing rows (batched to avoid lock escalation).
3. Add a NOT NULL constraint with a default in a separate migration.
4. Remove the default if it should not persist.

**Drop column or table:**
1. Remove all application references in a prior deployment.
2. Confirm no queries reference the column/table (check logs, slow-query log, ORM layer).
3. Run the drop migration only after the application is confirmed clean.

For Low-tier operations, a single-step migration is acceptable. Document that it is single-step explicitly.

### 4. Write the rollback plan

For every migration step, write the exact inverse. The rollback plan must be runnable without referencing the forward migration source.

Format each step as:

```
Forward:  <SQL or CLI command>
Rollback: <exact inverse SQL or CLI command>
Data risk: none | recoverable | IRREVERSIBLE
```

Mark any step whose rollback requires data recovery (backfill deletion, type coercion reversal) as `recoverable`. Mark any step that destroys data with no mechanical inverse as `IRREVERSIBLE` — these require a pre-migration backup confirmation.

If any step is `IRREVERSIBLE`, stop here and require explicit confirmation from the user that a backup exists and is verified restorable before continuing.

### 5. Write the test checklist

Produce a numbered checklist that must be completed in order. The checklist covers three phases:

**Pre-migration (on staging or a production replica first):**
- [ ] `<migration status command>` confirms the baseline state before running.
- [ ] Migration runs cleanly on a staging environment with production-size data (or a sampled subset).
- [ ] Rollback runs cleanly on the same environment after the forward migration.
- [ ] Application smoke tests pass against the migrated staging schema.
- [ ] No lock waits exceed the acceptable threshold (check `pg_stat_activity`, `SHOW PROCESSLIST`, or equivalent).

**During migration (production):**
- [ ] Pre-migration backup confirmed and restore tested.
- [ ] Replica lag monitored throughout (target: < N seconds, where N is agreed before the window).
- [ ] Migration runtime recorded for comparison against staging estimate.
- [ ] Alert thresholds adjusted if the migration is expected to spike error rates temporarily.

**Post-migration (production):**
- [ ] `<migration status command>` confirms the migration is recorded as complete.
- [ ] Application health checks green within N minutes of migration completion.
- [ ] No unexpected errors in application logs referencing the migrated tables.
- [ ] Index sizes and query plans verified for any new or modified indexes.
- [ ] Rollback window: keep the rollback plan active for N hours before treating the migration as irreversibly committed.

### 6. Record the decision

Call `decision-ledger` to record the migration decision before running anything:

```markdown
### Entry — <date>

**Question / Hypothesis:** Is this schema change safe to run in production without downtime?

**Prediction / Options:**
- Option A: Run as a single migration step
- Option B: Run as a phased zero-downtime sequence (see plan)

**Action / Instrumentation:** Reviewed table sizes, consumer list, and operation tier.

**Observation:** <fill in after plan review>

**Verdict:** DECIDED — <chosen option>

**Carry-forward:** <one sentence: what future sessions need to know about this decision>
```

### 7. Produce the migration plan document

Assemble the outputs from steps 1–6 into a single migration plan block. Format:

```
## Migration Plan: <migration name or ticket>

**Date:**
**Target environment:**
**Migration tool + version:**
**Risk tier:** Low / Medium / High / Critical

### Change summary
<One paragraph. What changes, which tables, why.>

### Zero-downtime sequence
<Numbered steps from Step 3. Include application deployment steps where relevant.>

### Rollback plan
<Forward/Rollback/Data-risk table from Step 4. Mark any IRREVERSIBLE steps.>

### Test checklist
<Full checklist from Step 5.>

### Open questions / approvals needed
<Any unresolved items before the migration can be run. Empty if none.>
```

Save to `migrations/plans/<migration-name>-plan.md` or return inline if no migrations directory exists.

### 8. Verify before claiming the plan is complete

Run `verify-before-done` before stating the plan is ready. The plan is not complete until:
- Every affected table has a known row count and traffic estimate (or an explicit note that it is new/empty).
- Every operation has a rollback entry.
- The test checklist covers all three phases.
- Any IRREVERSIBLE step has a backup confirmation or an explicit blocker note.

Pass the completed plan to `proof-gate` before handing off to the team.

## Output

The skill produces:

1. **Migration plan document** (`migrations/plans/<name>-plan.md` or inline) — change summary, risk tier, zero-downtime sequence, rollback plan, test checklist.
2. **Decision ledger entry** — the chosen approach recorded for future sessions.
3. **Open blockers list** — any unresolved items (missing backup confirmation, unknown consumer, IRREVERSIBLE step without sign-off) that must be cleared before the migration runs.

```
PROVEN BY: <migration status command on staging> → migration applied cleanly, rollback verified → plan confirmed safe to hand off.
```

## Integrates with

| Skill | When |
|---|---|
| `verify-before-done` | Before claiming the plan is complete or the migration has been verified |
| `proof-gate` | Attaches the `PROVEN BY:` tag to the staging run confirmation |
| `decision-ledger` | Records the migration approach decision for resumable context |
| `execute-plan` | If the migration requires coordinated application + schema deployment steps |
| `finish-branch` | After the migration branch passes staging verification and is ready to merge |
| `find-root-cause` | If the migration causes an unexpected production incident |

## Pitfalls

| Mistake | Fix |
|---|---|
| Running the migration on production before staging | Always run and verify on a staging environment with production-size data first |
| Writing the rollback plan after the migration runs | The rollback plan must exist before any forward step is taken; a missing rollback plan means the migration cannot run |
| Treating "nullable column" as always safe | A nullable column on a very large table can still take a long time if the ORM sends a table rewrite — check the engine behaviour |
| Omitting application deployment steps from the plan | Schema changes and application code deployments are a coupled system; plan them together |
| Marking a DROP as Low risk because the table is small | Data destruction is always at least Medium regardless of size |
| Assuming the rollback is the exact SQL inverse | Type coercions and constraint additions may not be mechanically reversible — check each step |
| Skipping the decision-ledger entry for simple migrations | Simple migrations become complex incidents; the ledger entry costs thirty seconds and saves hours |
