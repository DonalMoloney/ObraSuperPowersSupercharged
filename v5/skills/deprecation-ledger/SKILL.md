---
name: deprecation-ledger
description: Micro-skill. Records every deprecation — function, module, API, flag, or dead-code removal — as a structured ledger entry covering what, why, who is affected, when it goes, and the migration path. Pairs with decision-ledger; if no decision entry exists for the removal, create one first.
author: Donal Moloney
track: A
type: support
chains-to: ~
---

## Not this skill if
- You are only marking code with a `@deprecated` comment but have no removal date or migration plan — that is annotation, not deprecation
- The removal is already complete and callers are already migrated — use `write-pr-notes` to document what shipped
- You need to decide whether to deprecate something — use `decision-ledger` (or `challenge-spec`) first, then return here

# Deprecation Ledger

> **Micro-skill.** Called by `finish-branch` (removal step), `scope-feature` (API clean-up tasks), and any session that removes a function, module, API surface, flag, or dead-code path. Use directly whenever a deprecation decision has been made and needs to be recorded, communicated, and tracked.

## When to Use

- Removing a public function, class, module, CLI flag, or API endpoint
- Marking an internal helper deprecated ahead of a planned removal sprint
- Cleaning up dead-code paths after a feature flag is retired
- Any situation where callers or consumers exist and need a migration window

## Steps

### 1. Resolve the decision-ledger entry

Before writing the ledger, confirm that the decision to deprecate has been recorded.

- Search for an existing `decision-ledger` entry covering this removal.
- If one exists, copy the entry reference (file path + entry number) into the `Decision ref` field below.
- **If no entry exists:** invoke `decision-ledger` now. Record the question ("Should we remove X?"), the reasoning, and the verdict (DECIDED). Return here with the entry reference.

> Skipping this step is allowed only for clearly dead code with zero callers. In that case, write `Decision ref: N/A — zero-caller dead code confirmed by <grep/LSP evidence>`.

### 2. Identify callers and consumers

Run a concrete search before writing anything:

```bash
# callers inside the repo
grep -rn "<symbol>" --include="*.py" .   # adjust extension as needed

# or use LSP find-references if available
```

List every call site, import, and external consumer (downstream repos, public API users, docs). If the count is zero, confirm with a second search method before proceeding.

### 3. Write the ledger entry

Append the entry to `deprecation-ledger.md` at the repo root (create the file if it does not exist). One entry per deprecated symbol.

```markdown
### Deprecation — <YYYY-MM-DD>

| Field            | Value |
|------------------|-------|
| **Symbol**       | `fully.qualified.Name` |
| **Kind**         | function / class / module / CLI flag / API endpoint / config key |
| **Location**     | `path/to/file.py:line` |
| **Decision ref** | `decision-ledger` entry N, `diagnose/hypothesis-ledger.md` (or `N/A — <reason>`) |
| **Why**          | One sentence. What made this removable. |
| **Callers**      | N internal (`grep` count) + list external consumers if any |
| **Deprecated on**| YYYY-MM-DD |
| **Removal date** | YYYY-MM-DD (or sprint / release tag) |
| **Migration**    | See Migration Path section below |
| **Status**       | DEPRECATED / REMOVED |

#### Migration Path

<!-- For each caller or consumer, state exactly what they must change. -->
<!-- Use bullet points, one per call site or consumer group. -->
<!-- If a codemod or script is available, link it here. -->

- `src/foo.py:42` — replace `OldClass(x)` with `NewClass(x, mode="compat")`
- External API consumers — use `/v2/endpoint` with the same payload shape; `/v1/endpoint` returns HTTP 410 after `<removal date>`

#### Caller Notification

<!-- Record how callers were notified. Check all that apply. -->

- [ ] In-code warning added (`DeprecationWarning` / `console.warn` / log at startup)
- [ ] PR / commit description links this ledger entry
- [ ] Downstream repo issues opened: <!-- list issue URLs -->
- [ ] Public changelog / release notes updated (see `write-pr-notes`)
- [ ] Docs PR opened: <!-- link -->
```

### 4. Add the in-code deprecation marker

Place the marker at the declaration site, referencing the ledger entry and the removal date:

```python
# Python example
import warnings

def old_function(x):
    warnings.warn(
        "old_function is deprecated as of YYYY-MM-DD and will be removed on YYYY-MM-DD. "
        "Use new_function(x) instead. See deprecation-ledger.md entry YYYY-MM-DD.",
        DeprecationWarning,
        stacklevel=2,
    )
    return new_function(x)
```

```typescript
// TypeScript / JavaScript example
/** @deprecated Since YYYY-MM-DD. Use `newFunction` instead. Removed YYYY-MM-DD. See deprecation-ledger.md. */
export function oldFunction(x: string): void { ... }
```

Adapt the marker syntax to the language and framework in use.

### 5. Migrate or schedule callers

For each internal caller identified in Step 2, choose one:

- **Migrate now** — update the call site in this PR; confirm with tests.
- **Schedule** — open a tracked issue with the removal date as the deadline; link the issue in the ledger's `Caller Notification` section.

Do not leave internal callers unmigrated past the removal date without an explicit extension decision recorded in `decision-ledger`.

### 6. Confirm and close the entry

When the symbol is physically removed (not just marked), update the `Status` field in the ledger entry from `DEPRECATED` to `REMOVED` and append:

```markdown
**Removed on:** YYYY-MM-DD
**Confirmed by:** `grep -rn "<symbol>" .` returned zero results
```

## Output

A filled deprecation ledger entry in `deprecation-ledger.md`, an in-code deprecation marker at the declaration site, and a completed caller notification checklist. The entry stays in the file permanently — never delete it, even after removal, so future sessions can verify the removal was intentional.

## Integrates with

- **`decision-ledger`** — mandatory precondition; the deprecation decision must be recorded there before this skill writes anything.
- **`finish-branch`** — call this skill as part of the removal step before opening the PR; link the ledger entry in the PR body.
- **`write-pr-notes`** — after the branch merges, `write-pr-notes` pulls the ledger entry into the changelog under `### Deprecated` or `### Removed`.
- **`scope-feature`** — when a feature scope includes API clean-up, `scope-feature` should list a `deprecation-ledger` task per symbol being retired.
- **`proof-gate`** — a removal PR should carry `PROVEN BY: grep -rn "<symbol>" . → 0 results` as its evidence block; this skill produces the grep command to run.

## Rules

1. One ledger entry per symbol. Do not batch unrelated removals into a single entry — traceability requires one-to-one mapping.
2. The `Decision ref` field is mandatory unless zero-caller dead code is confirmed. A deprecation with no recorded decision is a silent breakage risk.
3. Never remove the physical symbol in the same commit that adds the deprecation marker, unless callers are zero. Callers need at least one release window.
4. The removal date must be a specific date or a named release tag — "soon" or "TBD" is not acceptable.
5. Do not delete ledger entries after removal. The file is a permanent record.

## Anti-Patterns

- **Ghost deprecation** — in-code `@deprecated` comment with no ledger entry, no removal date, and no migration guidance; callers never know what to do.
- **Immediate removal** — deprecated and removed in the same PR without checking callers.
- **Missing external consumers** — internal callers migrated but public API users hit a 500 because no changelog entry or notification was written.
- **Status never updated** — entry stays `DEPRECATED` indefinitely; removal is silently deferred and the marker rots.

---

**PROVEN BY:** Ledger entry written to `deprecation-ledger.md`, `Status: DEPRECATED` confirmed in the entry, in-code marker present at `<symbol>` declaration, and all internal callers either migrated or tracked in open issues linked from the `Caller Notification` section.
