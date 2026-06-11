# v5 → v2 Gap Promotions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Promote 7 skills from `v5/skills/` into `v2/skills/`, rewritten to v2 standards, filling the four gap areas in the approved spec (`docs/superpowers/specs/2026-06-10-v5-to-v2-gap-promotions-design.md`).

**Architecture:** Each promotion is an independent copy-rewrite-verify-delete cycle on one skill directory. The shared file `v2/README.md` is touched only in the final task to keep the 7 promotion tasks conflict-free. No git commits anywhere in this plan — the project is not a git repository (per spec, git is out of scope).

**Tech Stack:** Markdown skill files, bash/grep for verification, `skill-auditor` agent for per-skill audit.

---

## Global conventions (read before any task)

**Paths.** `V5=/Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v5/skills`, `V2=/Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v2/skills`. All commands below assume these absolute paths.

**v2 frontmatter pattern** (matches existing `v2/skills/red-team-spec/SKILL.md`): keep `name`, `description`, `author`, `type`; **add** `tier: v2` and `supports: [...]`; **drop** `track:` and `pairs-with:`; keep `chains-to:` only if its target is remapped to a v1 or v2 skill name.

**Forge-ism remap table.** Apply these replacements everywhere in body text (the per-task tables list every known occurrence by line number in the v5 source; also re-grep, don't trust line numbers alone):

| Forge term | Replace with |
|---|---|
| `verify-before-done` | v1 **verification-before-completion** |
| `proof-gate` | v1 **verification-before-completion** (its evidence-before-claims gate) |
| `PROVEN BY:` block | "evidence block (command + literal output, per v1 verification-before-completion)" |
| `request-review` | v1 **requesting-code-review** |
| `finish-branch` | v1 **finishing-a-development-branch** |
| `execute-plan` | v1 **executing-plans** |
| `find-root-cause` | v1 **systematic-debugging** |
| `worktree-pool` | v1 **using-git-worktrees** (one worktree per site) |
| `map-reduce-sweep` | reword: "a read-only parallel sweep via v1 dispatching-parallel-agents" |
| `exhaustive-audit` | cut the alternative; reword to "a full-codebase security sweep (out of scope for this skill)" |
| `keep-both-sides` | cut; fold the behavior into the skill's own output (see Task 4) |

**Allowed cross-references (do NOT remap):** `red-team-spec`, `devils-advocate`, `track-assumption`, `write-adr`, `session-handoff` — these are (or become, within this plan) v2 siblings. When referencing them, prefix with "v2" (e.g., "v2 **red-team-spec**").

**Per-skill verification command** (used in every task; substitute the skill dir):

```bash
grep -nE 'proof-gate|verify-before-done|PROVEN BY|keep-both-sides|find-root-cause|finish-branch|request-review|execute-plan|map-reduce-sweep|worktree-pool|exhaustive-audit|^track:|^pairs-with:' "$V2/<skill>/SKILL.md"
```

Expected: **no output** (exit code 1). Any hit is an unfinished remap.

**Frontmatter verification command:**

```bash
grep -nE '^tier: v2$|^supports: \[' "$V2/<skill>/SKILL.md"
```

Expected: exactly 2 lines (one `tier:`, one `supports:`).

**skill-auditor step (every task):** dispatch the `skill-auditor` agent with the prompt: "Audit the v2 skill at `v2/skills/<skill>/SKILL.md` against the v2 tier rules in CLAUDE.md: tier/supports frontmatter present, description states WHEN, no duplication of v1 content (reference instead), no references to Forge-only skills. Report findings only." Fix every blocking finding before marking the task done. The auditor is read-only; you make the fixes.

---

### Task 1: Promote `blast-radius`

**Files:**
- Create: `v2/skills/blast-radius/SKILL.md` (copied then rewritten)
- Delete: `v5/skills/blast-radius/` (final step)

- [ ] **Step 1: Copy the skill into v2**

```bash
cp -R "$V5/blast-radius" "$V2/blast-radius"
```

- [ ] **Step 2: Replace the frontmatter**

Replace the entire frontmatter block (lines 1–8 of the copy) with:

```yaml
---
name: blast-radius
description: Use before requesting review or merging — for a diff, trace every caller, dependent, and test that could break, then emit a blast-radius score and risk level (LOW/MED/HIGH/CRITICAL) so review depth and reviewer choice scale with actual impact.
author: Donal Moloney
tier: v2
supports: [requesting-code-review, verification-before-completion]
type: support
chains-to: requesting-code-review
---
```

- [ ] **Step 3: Remap body Forge-isms**

Known occurrences in the v5 source (re-grep after editing):

| ~Line | Old | New |
|---|---|---|
| 32 | "Preparing to invoke `request-review`" | "Preparing to invoke v1 **requesting-code-review**" |
| 33 | "Before `finish-branch`" | "Before v1 **finishing-a-development-branch**" |
| 41 | "proceed directly to `request-review`" | "proceed directly to v1 **requesting-code-review**" |
| 121 | "`PROVEN BY:` block. Hand off to `request-review`" | "evidence block (command + literal output, per v1 verification-before-completion). Hand off to v1 **requesting-code-review**" |
| 151 | "Hand off to `request-review`" | "Hand off to v1 **requesting-code-review**" |
| 174 | "invoke devils-advocate before request-review" | "invoke v2 **devils-advocate** before v1 **requesting-code-review**" |

- [ ] **Step 4: Run the verification greps**

Run both global verification commands against `$V2/blast-radius/SKILL.md`.
Expected: forbidden-token grep → no output; frontmatter grep → 2 lines.

- [ ] **Step 5: Run skill-auditor and fix findings**

Dispatch `skill-auditor` per the global convention. Fix blocking findings, re-run Step 4 after any edit.

- [ ] **Step 6: Delete the v5 source**

```bash
rm -rf "$V5/blast-radius" && ls "$V5" | grep -c blast-radius
```

Expected: `0`.

---

### Task 2: Promote `migrate-codebase`

**Files:**
- Create: `v2/skills/migrate-codebase/SKILL.md`
- Delete: `v5/skills/migrate-codebase/`

- [ ] **Step 1: Copy the skill into v2**

```bash
cp -R "$V5/migrate-codebase" "$V2/migrate-codebase"
```

- [ ] **Step 2: Replace the frontmatter**

```yaml
---
name: migrate-codebase
description: Use for large mechanical migrations (framework bump, API rename, dependency swap) — discover every call site, transform each in its own worktree, verify each independently with no barrier between stages. The codemod harness.
author: Donal Moloney
tier: v2
supports: [dispatching-parallel-agents, using-git-worktrees]
type: process
chains-to: finishing-a-development-branch
---
```

- [ ] **Step 3: Remap body Forge-isms**

| ~Line | Old | New |
|---|---|---|
| 12 | "use `execute-plan`" | "use v1 **executing-plans**" |
| 14 | "use `map-reduce-sweep` instead" | "use a read-only parallel sweep via v1 **dispatching-parallel-agents** instead" |
| 39 | "sequence the writes with `execute-plan`" | "sequence the writes with v1 **executing-plans**" |
| 46 | "→ merge-back → finish-branch" | "→ merge-back → v1 finishing-a-development-branch" |
| 78 | "short-lived worktree (`worktree-pool`)" | "short-lived worktree (v1 **using-git-worktrees**, one per site)" |
| 117 | "Pass the migration branch to `finish-branch`" | "Pass the migration branch to v1 **finishing-a-development-branch**" |
| 136 | "Hand the merged migration branch to `finish-branch`" | "Hand the merged migration branch to v1 **finishing-a-development-branch**" |

- [ ] **Step 4: Run the verification greps**

Both global commands against `$V2/migrate-codebase/SKILL.md`. Expected: no forbidden tokens; 2 frontmatter lines.

- [ ] **Step 5: Run skill-auditor and fix findings**

Per global convention.

- [ ] **Step 6: Delete the v5 source**

```bash
rm -rf "$V5/migrate-codebase" && ls "$V5" | grep -c migrate-codebase
```

Expected: `0`.

---

### Task 3: Promote `security-audit`

**Files:**
- Create: `v2/skills/security-audit/SKILL.md`
- Delete: `v5/skills/security-audit/`

This is the heaviest rewrite (269 lines, 15+ Forge references).

- [ ] **Step 1: Copy the skill into v2**

```bash
cp -R "$V5/security-audit" "$V2/security-audit"
```

- [ ] **Step 2: Replace the frontmatter** (description rewritten — old one named Forge skills)

```yaml
---
name: security-audit
description: Use when code changes touch auth, crypto, input validation, secrets, or permissions — runs OWASP-grounded checks across the diff, emits a structured findings block with severity and file:line references, and gates completion on v1 verification-before-completion.
author: Donal Moloney
tier: v2
supports: [requesting-code-review, verification-before-completion]
type: process
chains-to: verification-before-completion
---
```

- [ ] **Step 3: Remap body Forge-isms**

| ~Line | Old | New |
|---|---|---|
| 11 | "use `exhaustive-audit` instead; this skill focuses on…" | "that full-codebase sweep is out of scope for this skill, which focuses on targeted, diff-scoped checks" |
| 12 | "use `red-team-spec`" | "use v2 **red-team-spec**" |
| 13 | "use `find-root-cause`" | "use v1 **systematic-debugging**" |
| 14 | "skip this and proceed to `verify-before-done`" | "skip this and proceed to v1 **verification-before-completion**" |
| 22 | "An undisposed finding blocks `proof-gate`." | "An undisposed finding blocks v1 **verification-before-completion**." |
| 47 | "→ completeness critic → proof-gate" | "→ completeness critic → v1 verification-before-completion" |
| 160 | "blocks `proof-gate`" | "blocks v1 **verification-before-completion**" |
| 171 | heading "Hand off to verify-before-done and proof-gate" | "Hand off to v1 verification-before-completion" |
| 173 | "run `verify-before-done` … emit the `PROVEN BY:` block and hand off to `proof-gate`" | "run v1 **verification-before-completion** to confirm any remediation code compiles or passes its tests, capturing the evidence block (command + literal output)" |
| 228 | "→ verify-before-done: \<command run\> → \<key output line\>" | "→ verification: \<command run\> → \<key output line\>" |
| 233–234 | the two bullets defining `verify-before-done` / `proof-gate` integration | one bullet: "**v1 verification-before-completion** — mandatory before any FIXED disposition: the remediation's verification command and literal output are captured in the findings block; completion is blocked while any finding is undisposed." |
| 245 | "`verify-before-done` is mandatory before any FIXED disposition closes the gate" | "v1 **verification-before-completion** is mandatory before any FIXED disposition closes the gate" |
| 266 | "→ verify-before-done: \<command\> → \<output\>" | "→ verification: \<command\> → \<output\>" |
| 269 | "must still pass through `proof-gate` with the PROVEN BY block" | "must still carry an evidence block (per v1 verification-before-completion)" |
| 235 | bullet for `exhaustive-audit` | delete the bullet |
| 236 | bullet for `red-team-spec` | keep, but prefix "v2 **red-team-spec**" |

- [ ] **Step 4: Run the verification greps**

Both global commands against `$V2/security-audit/SKILL.md`. Expected: no forbidden tokens; 2 frontmatter lines.

- [ ] **Step 5: Run skill-auditor and fix findings**

Per global convention. Pay attention to duplication findings: if the auditor flags the verification-handoff section as restating v1 verification-before-completion content, cut it down to a one-line reference.

- [ ] **Step 6: Delete the v5 source**

```bash
rm -rf "$V5/security-audit" && ls "$V5" | grep -c security-audit
```

Expected: `0`.

---

### Task 4: Promote `devils-advocate`

**Files:**
- Create: `v2/skills/devils-advocate/SKILL.md`
- Delete: `v5/skills/devils-advocate/`

Special handling: Forge chains this to `keep-both-sides` (no equivalent here). Per the remap table, **cut** that skill and fold the behavior in: a claim that *survives* refutation gets its surviving counter-arguments recorded in the skill's own output block instead of being handed off.

- [ ] **Step 1: Copy the skill into v2**

```bash
cp -R "$V5/devils-advocate" "$V2/devils-advocate"
```

- [ ] **Step 2: Replace the frontmatter** (description rewritten — old one referenced proof-gate; `chains-to` dropped, target was Forge-only)

```yaml
---
name: devils-advocate
description: Use for any important claim that tests cannot mechanically prove — a design conclusion, research finding, or "this is the root cause" assertion — spin up N independent agents whose only job is to disprove it; if a quorum succeeds, the claim dies.
author: Donal Moloney
tier: v2
supports: [receiving-code-review, verification-before-completion]
type: process
---
```

- [ ] **Step 3: Remap body Forge-isms**

| ~Line | Old | New |
|---|---|---|
| 11 | "already mechanically proven (tests/`proof-gate`)" | "already mechanically proven by passing tests (v1 **verification-before-completion**)" |
| 19 | "which `proof-gate` cannot" | "which test-based verification (v1 verification-before-completion) cannot" |
| 39 | "run `proof-gate` instead" | "run the tests and capture evidence per v1 **verification-before-completion** instead" |
| 53 | "survived → keep-both-sides" | "survived → record surviving tensions" |
| 116 | "claim survives this round; proceed to `keep-both-sides`" | "claim survives this round; record the surviving counter-arguments in the refutation record" |
| 132 | "pass the record to `keep-both-sides` so the surviving tensions…" | "append the surviving tensions (the arguments the claim did not fully defeat) to the refutation record so they travel with the claim" |
| 144 | "Skipping `keep-both-sides` on survival … route through `keep-both-sides` to capture it" | "Discarding counter-arguments on survival \| Survivors still carry unresolved tension; record it in the refutation record" |
| 149 | "Hand off to `keep-both-sides` once the quorum decision is recorded." | "Done once the quorum decision and any surviving tensions are recorded." |
| 157 | "the unresolved tensions forwarded to `keep-both-sides`" | "the unresolved tensions recorded alongside the claim" |

- [ ] **Step 4: Run the verification greps**

Both global commands against `$V2/devils-advocate/SKILL.md`. Expected: no forbidden tokens; 2 frontmatter lines.

- [ ] **Step 5: Run skill-auditor and fix findings**

Per global convention.

- [ ] **Step 6: Delete the v5 source**

```bash
rm -rf "$V5/devils-advocate" && ls "$V5" | grep -c devils-advocate
```

Expected: `0`.

---

### Task 5: Promote `track-assumption`

**Files:**
- Create: `v2/skills/track-assumption/SKILL.md`
- Delete: `v5/skills/track-assumption/`

- [ ] **Step 1: Copy the skill into v2**

```bash
cp -R "$V5/track-assumption" "$V2/track-assumption"
```

- [ ] **Step 2: Replace the frontmatter** (description rewritten — old one said `finish-branch`)

```yaml
---
name: track-assumption
description: Use when you make a decision based on something unverified — registers the assumption with a test condition and expiry to ~/.claude/assumptions.jsonl so it cannot silently rot before v1 finishing-a-development-branch or deploy.
author: Donal Moloney
tier: v2
supports: [brainstorming, executing-plans, finishing-a-development-branch]
type: support
chains-to: verification-before-completion
---
```

- [ ] **Step 3: Remap body Forge-isms**

| ~Line | Old | New |
|---|---|---|
| 12 | "record it in `PROVEN BY:` instead" | "record it as an evidence block (per v1 verification-before-completion) instead" |
| 21 | "before any `finish-branch` or deploy" | "before any v1 **finishing-a-development-branch** or deploy" |
| 71 | heading "scan before finish-branch or deploy" | "scan before finishing-a-development-branch or deploy" |
| 73 | "Before `verify-before-done` or `finish-branch` runs" | "Before v1 **verification-before-completion** or v1 **finishing-a-development-branch** runs" |
| 150 | "Before finish-branch \| Run CHECK step" | "Before v1 finishing-a-development-branch \| Run CHECK step" |
| 153 | "Proceed to `verify-before-done`" | "Proceed to v1 **verification-before-completion**" |
| 163 | "Wire into the `verify-before-done` invocation" | "Wire into the v1 **verification-before-completion** invocation" |
| 169 | "- `verify-before-done` — runs CHECK step before any completion claim" | "- v1 **verification-before-completion** — runs CHECK step before any completion claim" |
| 170 | "- `proof-gate` — an uncleared past-expiry assumption blocks the `PROVEN BY:` tag" | "- an uncleared past-expiry assumption blocks the completion evidence block (v1 verification-before-completion)" |

- [ ] **Step 4: Run the verification greps**

Both global commands against `$V2/track-assumption/SKILL.md`. Expected: no forbidden tokens; 2 frontmatter lines.

- [ ] **Step 5: Run skill-auditor and fix findings**

Per global convention.

- [ ] **Step 6: Delete the v5 source**

```bash
rm -rf "$V5/track-assumption" && ls "$V5" | grep -c track-assumption
```

Expected: `0`.

---

### Task 6: Promote `write-adr`

**Files:**
- Create: `v2/skills/write-adr/SKILL.md`
- Delete: `v5/skills/write-adr/`

- [ ] **Step 1: Copy the skill into v2**

```bash
cp -R "$V5/write-adr" "$V2/write-adr"
```

- [ ] **Step 2: Replace the frontmatter** (`chains-to: track-assumption` kept — v2 sibling promoted in Task 5)

```yaml
---
name: write-adr
description: Use when a significant architectural choice is being made — library selection, pattern adoption, infra decision, API contract, or any decision whose rationale will not be obvious in three months — to produce a permanent record of context, options, decision, and consequences.
author: Donal Moloney
tier: v2
supports: [brainstorming, writing-plans]
type: support
chains-to: track-assumption
---
```

- [ ] **Step 3: Remap body Forge-isms**

| ~Line | Old | New |
|---|---|---|
| 100 | "link the ADR to a `track-assumption` entry" | "link the ADR to a v2 **track-assumption** entry" |
| 104 | "- `track-assumption` — register any unverified assumption…" | "- v2 **track-assumption** — register any unverified assumption embedded in the ADR (e.g. \"we assume traffic will not exceed X\")" |
| 107 | "- `proof-gate` — the ADR itself is evidence of a deliberate decision; cite it in `PROVEN BY:` when the decision is the claim" | "- v1 **verification-before-completion** — the ADR itself is evidence of a deliberate decision; cite it in the evidence block when the decision is the claim" |

- [ ] **Step 4: Run the verification greps**

Both global commands against `$V2/write-adr/SKILL.md`. Expected: no forbidden tokens; 2 frontmatter lines.

- [ ] **Step 5: Run skill-auditor and fix findings**

Per global convention.

- [ ] **Step 6: Delete the v5 source**

```bash
rm -rf "$V5/write-adr" && ls "$V5" | grep -c write-adr
```

Expected: `0`.

---

### Task 7: Promote `incident-postmortem`

**Files:**
- Create: `v2/skills/incident-postmortem/SKILL.md`
- Delete: `v5/skills/incident-postmortem/`

- [ ] **Step 1: Copy the skill into v2**

```bash
cp -R "$V5/incident-postmortem" "$V2/incident-postmortem"
```

- [ ] **Step 2: Replace the frontmatter** (`pairs-with: find-root-cause` dropped; relationship moves into `supports`)

```yaml
---
name: incident-postmortem
description: Use when an incident, outage, or significant failure has occurred and you need to produce a structured blameless postmortem: timeline, root cause, contributing factors, and prevention actions.
author: Donal Moloney
tier: v2
supports: [systematic-debugging]
type: analysis
chains-to: verification-before-completion
---
```

- [ ] **Step 3: Remap body Forge-isms**

| ~Line | Old | New |
|---|---|---|
| 13 | "use `find-root-cause` instead" | "use v1 **systematic-debugging** instead" |
| 34 | "use `find-root-cause` for that" | "use v1 **systematic-debugging** for that" |
| 120 | "Hand off to `verify-before-done` once the postmortem document is written." | "Hand off to v1 **verification-before-completion** once the postmortem document is written." |

(Line 86's `@oncall-eng` is a template placeholder inside the postmortem action-items example — leave it.)

- [ ] **Step 4: Run the verification greps**

Both global commands against `$V2/incident-postmortem/SKILL.md`. Expected: no forbidden tokens; 2 frontmatter lines.

- [ ] **Step 5: Run skill-auditor and fix findings**

Per global convention.

- [ ] **Step 6: Delete the v5 source**

```bash
rm -rf "$V5/incident-postmortem" && ls "$V5" | grep -c incident-postmortem
```

Expected: `0`.

---

### Task 8: Update `v2/README.md` and final sweep

**Files:**
- Modify: `v2/README.md` (Current skills table, lines 19–26)

This task runs **after** Tasks 1–7 (it is the single shared-file touchpoint).

- [ ] **Step 1: Add the 7 new rows to the Current skills table**

Insert into the existing table, keeping it alphabetically sorted (the existing rows already are):

```markdown
| `blast-radius` | requesting-code-review, verification-before-completion |
| `devils-advocate` | receiving-code-review, verification-before-completion |
| `incident-postmortem` | systematic-debugging |
| `migrate-codebase` | dispatching-parallel-agents, using-git-worktrees |
| `security-audit` | requesting-code-review, verification-before-completion |
| `track-assumption` | brainstorming, executing-plans, finishing-a-development-branch |
| `write-adr` | brainstorming, writing-plans |
```

Resulting table order: `blast-radius`, `devils-advocate`, `incident-postmortem`, `loop-until-green`, `merge-parallel-results`, `migrate-codebase`, `red-team-spec`, `security-audit`, `session-handoff`, `skill-lint`, `spike-in-worktree`, `track-assumption`, `write-adr`.

- [ ] **Step 2: Verify the table**

```bash
grep -c '^| `' /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v2/README.md
```

Expected: `13` (6 existing + 7 new).

- [ ] **Step 3: Final cross-tier sweep**

```bash
grep -rnE 'proof-gate|verify-before-done|PROVEN BY|keep-both-sides|find-root-cause|finish-branch|request-review|execute-plan|map-reduce-sweep|worktree-pool|exhaustive-audit' /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v2/skills/blast-radius /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v2/skills/migrate-codebase /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v2/skills/security-audit /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v2/skills/devils-advocate /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v2/skills/track-assumption /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v2/skills/write-adr /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v2/skills/incident-postmortem
```

Expected: no output.

- [ ] **Step 4: Confirm v5 sources are gone**

```bash
ls /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v5/skills | grep -E '^(blast-radius|migrate-codebase|security-audit|devils-advocate|track-assumption|write-adr|incident-postmortem)$' | wc -l
```

Expected: `0`.

---

## Failure handling

- **Redundancy rule (from spec):** if mid-rewrite a skill turns out ~90% redundant with an existing v1/v2 skill, stop that task, delete the `v2/skills/<skill>/` copy, leave the v5 source in place, and record "dropped: redundant with X" in the spec's slate table. Continue with remaining tasks; Task 8 then adds one fewer row.
- **skill-auditor blocking findings** must be fixed (and Step 4 greps re-run) before a task is complete.
- Never touch `/Users/donalmoloney/PycharmProjects/superpowers2` — the v5 copies inside this project are the only source.
