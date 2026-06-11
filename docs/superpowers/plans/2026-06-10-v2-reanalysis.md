# v2 Re-Analysis Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the 8-item v2 portfolio from `docs/superpowers/specs/2026-06-10-v2-reanalysis-design.md` — 4 items already exist on disk (built concurrently); this plan builds the remaining 4, validates the pre-built 4, and does the bookkeeping.

**Architecture:** Each skill is a single `v2/skills/<name>/SKILL.md` in the v2 house style (frontmatter with `tier: v2` + `supports:`, a `## Not this skill if` boundary block, numbered procedure, pitfalls table, `PROVEN BY:` block). Promotions (`delta-debugger`, `done-gate`) are rewritten from their v5 originals — not copied — and the v5 original is deleted after the v2 version validates. Validation replaces tests: every SKILL.md must pass the 7-point checklist in `v2/skills/skill-lint/SKILL.md` and a `skill-auditor` agent run.

**Tech Stack:** Markdown (SKILL.md), bash (verification commands only).

**Deviations from defaults (intentional):**
- **No git commits.** This project is deliberately not a git repository (per CLAUDE.md). Commit steps are replaced by lint/audit verification steps.

**⚠️ CONCURRENT-SESSION WARNING:** Another session has been modifying `v2/` and `v5/` during planning (it built 4 of this spec's 8 items and promoted ~10 other v5 skills not in this spec). Before EVERY task: re-check the file system state with `ls`. If a file this plan says to create already exists, do NOT overwrite it — diff it against the content in this plan, report differences, and validate it instead. If a v5 source this plan says to rewrite is already gone, check whether a `v2/skills/<same-name>/` version exists and validate that instead. Skills promoted by the other session that are not in this spec (e.g. `blast-radius`, `track-assumption`, `devils-advocate`, `write-adr`, `security-audit`) are out of this plan's scope — do not touch them, but referencing them from new skills is allowed where noted.

**skill-lint pass criteria (used in every skill task):** (1) frontmatter has `name`, `description`, `tier: v2`, `supports:` with real v1 skills; (2) description starts with `Use when`; (3) a `## Not this skill if` section exists; (4) a numbered or checkbox list with ≥2 steps exists; (5) `PROVEN BY` appears; (6) no TODO/TBD/placeholder strings; (7) every referenced skill resolves to a real directory (`v1/<name>/`, `v2/skills/<name>/`, `v5/skills/<name>/`).

---

### Task 1: dispatch-triage skill (net-new — build FIRST; the pre-built `compile-goal-to-contract` references it, so lint check 7 fails tier-wide until this exists)

**Files:**
- Create: `v2/skills/dispatch-triage/SKILL.md`

- [ ] **Step 1: Confirm it does not already exist**

Run: `ls v2/skills/ | grep dispatch-triage`
Expected: no output. If it exists, skip to Step 3 and validate the existing file instead of writing.

- [ ] **Step 2: Write the skill file**

Write `v2/skills/dispatch-triage/SKILL.md` with exactly this content:

````markdown
---
name: dispatch-triage
description: Use when choosing which model tier a subagent task needs, and ALWAYS when a subagent returns BLOCKED or produces a wrong result — provides the model-selection matrix and the four-question blocked-return diagnosis ladder, with a hard cap of 2 re-dispatches before escalating.
author: Donal Moloney
tier: v2
supports: [subagent-driven-development]
type: decision
pairs-with: compile-goal-to-contract
---

## Not this skill if

- No contract or spec exists yet for the task — compile one first with v2 **compile-goal-to-contract**; triage assumes the task is already well-specified.
- Subagent results need consolidating, not diagnosing — that is v2 **merge-parallel-results**.
- The task split itself is wrong — no model tier fixes a bad decomposition; re-plan via v1 **writing-plans**.

# Dispatch Triage

## Purpose

v1 **subagent-driven-development** gives two instructions without procedures. First: "use the least powerful model that can handle each role" — it lists complexity signals but no decision matrix mapping signals to a tier. Second: on a blocked return it offers four remediation paths (more context / more capable model / split the task / escalate) with no way to diagnose which one applies. This skill supplies both decision tables.

**Core rule:** every dispatch records its tier choice and one-line rationale; every BLOCKED or wrong return gets a ladder verdict before any re-dispatch. Maximum 2 re-dispatches per task, then escalate with the full trail.

## Model-selection matrix

Score the task on three axes. Take the HIGHEST tier any axis demands.

| Axis | Low tier (cheapest, e.g. Haiku-class) | Standard tier (e.g. Sonnet-class) | Top tier (frontier, e.g. Opus-class) |
|---|---|---|---|
| Spec completeness | Complete contract including a worked example | Complete contract, no worked example | Acceptance criteria testable but the approach is left to the agent |
| File scope | 1–2 named files | 3–5 files within one subsystem | Cross-subsystem, or the file set is unknown |
| Judgment required | Mechanical (rename, port, fill a given template) | Local design choices within an established pattern | Novel design or architecture choices |

Two overrides:
- Review and judgment roles (code reviewer, spec reviewer) never go to low tier — a reviewer weaker than the implementer rubber-stamps.
- If the contract has unresolved `open-decisions`, do not dispatch at all — back to v2 **compile-goal-to-contract**.

## BLOCKED-return diagnosis ladder

Ask the four questions in order against the subagent's return. First confident "yes" wins.

| # | Question | Verdict | Remediation |
|---|---|---|---|
| 1 | Does the return name (or clearly imply) a specific missing fact, file path, or contract element? | Context gap | Supply exactly that element; re-dispatch at the same tier |
| 2 | Did it grasp the goal but reason shallowly or wrongly (misapplied pattern, hand-waved steps, confident nonsense)? | Reasoning ceiling | Re-dispatch one tier up with the same prompt |
| 3 | Did it complete part of the work and stall, or describe several independent chunks of remaining work? | Oversized task | Split via v1 **writing-plans**; dispatch the pieces separately (the re-dispatch cap resets per piece) |
| 4 | Does the blocker contradict the contract or the plan itself? | Plan defect | STOP. Escalate to your human partner with the contradiction quoted |

If no question gets a confident "yes," treat it as #4 — an undiagnosable blocker is evidence the task framing is wrong, not a reason to retry blind.

## Procedure

1. Before dispatch: score the three matrix axes, record the chosen tier and a one-line rationale.
2. Dispatch per v1 **subagent-driven-development**.
3. On a BLOCKED or wrong return: run the ladder, record the verdict number and the evidence line from the return that triggered it.
4. Apply that verdict's remediation — and only that remediation.
5. Enforce the cap: after the 2nd failed re-dispatch on the same task, escalate to your human partner with the tier rationale, both ladder verdicts, and the returns.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Bumping the model tier as the default fix | Run the ladder — question 1 comes first because context is cheaper than capability |
| Re-dispatching with "be more careful" appended | Name the verdict; apply its specific remediation |
| Counting a reworded retry as a fresh task | The cap follows the task, not the prompt wording |
| Sending a review role to low tier to save cost | Reviewers never go to low tier; a weak reviewer is worse than none |
| Two identical ladder verdicts, third dispatch anyway | Two identical verdicts means the remediation isn't working — that is verdict #4 territory; escalate |

## After

Verify the loop closed: the final return satisfies the contract's done-when items, then proceed per the v1 **subagent-driven-development** review flow.

PROVEN BY: the per-dispatch triage line (three axis scores + chosen tier + rationale) and, for every BLOCKED or wrong return, the recorded ladder verdict with its evidence line. A re-dispatch without a recorded verdict is invalid under this skill.
````

- [ ] **Step 3: Run the skill-lint checklist**

Apply all 7 checks from `v2/skills/skill-lint/SKILL.md` to the file and emit the report table.
Expected: `Overall: PASS — all 7 structural checks green.` (Check 7 references: `subagent-driven-development`, `writing-plans` in `v1/`; `compile-goal-to-contract`, `merge-parallel-results` in `v2/skills/`.)

- [ ] **Step 4: Dispatch the skill-auditor agent**

Dispatch the project `skill-auditor` agent (read-only) with prompt: "Audit v2/skills/dispatch-triage/SKILL.md against the v2 tier rules in CLAUDE.md. Report pass/fail with evidence."
Expected: PASS. If findings, fix in the file and re-run Step 3.

---

### Task 2: Validate the 4 pre-built skills (built concurrently by another session)

**Files:**
- Verify (no modification expected): `v2/skills/compile-goal-to-contract/SKILL.md`, `v2/skills/decision-ledger/SKILL.md`, `v2/skills/reviewer-lenses/SKILL.md`, `v2/skills/scope-decomposition/SKILL.md`

- [ ] **Step 1: Run skill-lint on each of the four files**

Apply the 7-point checklist to each. Expected: PASS ×4. Note: `compile-goal-to-contract` check 7 requires `dispatch-triage` to exist — that is why Task 1 runs first. If any file fails a check, report the failure and fix ONLY the failing structural element (do not rewrite content another session authored).

- [ ] **Step 2: Bulk audit the four**

Dispatch the `skill-auditor` agent with prompt: "Audit these four v2 skills against the v2 tier rules in CLAUDE.md: compile-goal-to-contract, decision-ledger, reviewer-lenses, scope-decomposition (all under v2/skills/). Report per-skill pass/fail with evidence."
Expected: PASS ×4. Fix structural findings only; report content disagreements rather than editing.

---

### Task 3: delta-debugger skill (v5 promotion — rewrite, validate, delete original)

**Files:**
- Create: `v2/skills/delta-debugger/SKILL.md`
- Delete (after validation): `v5/skills/delta-debugger/`

- [ ] **Step 1: Confirm current state**

Run: `ls v2/skills/ | grep delta-debugger; ls v5/skills/ | grep delta-debugger`
Expected: absent from v2, present in v5. If already in v2 and gone from v5, skip to Step 3 and validate the existing file.

- [ ] **Step 2: Write the rewritten v2 skill file**

Write `v2/skills/delta-debugger/SKILL.md` with exactly this content (rewritten from the v5 original: Forge skill references remapped to v1/v2 skills, v2 frontmatter, v2 boundary block):

````markdown
---
name: delta-debugger
description: Use on a reproducible failure when the failing input is large or the introducing commit is unknown — mechanically shrinks the input to a minimal reproducer (ddmin) and localizes the bad commit (git bisect run), turning "poke at it" debugging into two solved procedures.
author: Donal Moloney
tier: v2
supports: [systematic-debugging, test-driven-development]
type: technique
pairs-with: loop-until-green
---

## Not this skill if

- The failure is not reproducible yet — establish a deterministic repro first via v1 **systematic-debugging** Phase 1; ddmin and bisect both require a stable pass/fail predicate.
- The input is already minimal and the introducing commit is known — go straight to v1 **test-driven-development** to pin it with a failing test.
- You have a tight repro and want to iterate on the *fix* — that is v2 **loop-until-green**; this skill minimizes and localizes, it never repairs.
- The project has no usable commit history — `git bisect` cannot run; minimize only (Steps 1–2) and skip localization.

# Delta Debugger

## Purpose

v1 **systematic-debugging** tells you to isolate the failure and find the root cause, but leaves the isolation mechanics to intuition. This skill mechanizes the two halves: **ddmin** (delta debugging) shrinks the failing input to a 1-minimal reproducer, and **`git bisect run`** binary-searches history for the first bad commit. Both run off one artifact — a predicate script with a clean pass/fail exit code.

**Core rule:** a minimization is only valid if the shrunk input *still fails*. Re-run it and attach the evidence.

## Background

- **ddmin** partitions the input into chunks of size N/2, N/4, N/8, … and removes chunks while the failure predicate stays true. It terminates when no single chunk can be removed without the predicate flipping — a 1-minimal input.
- **`git bisect run <script>`** calls your script per candidate commit: exit 0 = good, exit 1–124 = bad, exit 125 = skip (untestable). It isolates the first bad commit in O(log N) runs.

## Procedure

1. **Write the predicate script.** Wrap the failure as a self-contained shell script exiting 0 on pass, 1 on fail — no manual steps, no prompts. Run it against the full unminimized input: it MUST exit 1. If it exits 0, the repro isn't real — back to v1 **systematic-debugging**. Save to a stable path (e.g. `./scripts/is_broken.sh`); commit or stash working-tree changes so bisect can check out commits cleanly.
2. **Minimize with ddmin.** Use an existing ddmin implementation (e.g. `andrewchambers/ddmin-python`, importable, no deps) or write the partition loop directly. Run to completion — never stop early; a manually stopped run may not be 1-minimal. Then re-run the predicate on the minimized input and record the exit code. If it exits 0, the failure is order-dependent or stateful: split the input into ordered segments and re-run ddmin per segment. Record the reduction ratio (e.g. "4800 lines → 23").
3. **Localize with bisect.** `git bisect start`; `git bisect bad` on HEAD; `git bisect good <last-known-good-sha>`; then `git bisect run ./scripts/is_broken.sh`. Let it finish; `git bisect log` records every classification. Record the first bad commit SHA, author, and message. Then `git bisect reset`.
4. **Cross-validate.** Replay the minimized input at the bad commit's parent (predicate must exit 0) and at the bad commit (must exit 1). If the parent also fails, the true introducing commit is earlier — widen the range and repeat Step 3.
5. **Hand off.** Package the minimized input + bad commit SHA into a failing test via v1 **test-driven-development** (RED phase) — the permanent regression guard — then fix via v1 **systematic-debugging** Phase 4, iterating with v2 **loop-until-green** if needed.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Starting ddmin without verifying the predicate exits 1 on the original input | Run the predicate manually first; if it exits 0, re-establish the repro |
| Flaky predicate (sometimes passes, sometimes fails) | Add a retry loop inside the script and treat any single pass as "good"; flakiness breaks ddmin's monotonicity assumption |
| Not stashing working-tree changes before `git bisect run` | Bisect checks out commits and will clobber uncommitted files |
| Stopping ddmin early because "it's small enough" | Only ddmin's own termination guarantees 1-minimality |
| Accepting bisect output without the two-point check | Skipped commits can shift the boundary; always confirm parent-good / child-bad |
| Forgetting `git bisect reset` | Leaves the repo detached; later work lands on the wrong commit |

## After

Chain the minimized reproducer into v1 **test-driven-development** as the test seed before any fix is attempted.

PROVEN BY:
- ddmin run: `<original size> → <minimized size>`; predicate exits 1 on the minimized input (log attached)
- git bisect: first bad commit `<SHA>` — "`<commit message>`" by `<author>`
- Two-point check: parent `<parent-SHA>` exits 0, bad `<SHA>` exits 1
- Minimized test case handed to the RED phase at `<file path>`
````

- [ ] **Step 3: Run the skill-lint checklist**

Expected: `Overall: PASS — all 7 structural checks green.` (Check 7: `systematic-debugging`, `test-driven-development` in `v1/`; `loop-until-green` in `v2/skills/`.)

- [ ] **Step 4: Dispatch the skill-auditor agent**

Prompt: "Audit v2/skills/delta-debugger/SKILL.md against the v2 tier rules in CLAUDE.md. It is a promotion of v5/skills/delta-debugger — also confirm it has been rewritten for v2 (references resolve to v1/v2 skills, no Forge slugs like find-root-cause/write-tests-first/diagnose-bug/self-repair-loop remain). Report pass/fail with evidence."
Expected: PASS. Fix findings, re-run Step 3.

- [ ] **Step 5: Delete the v5 original and verify**

Run: `rm -rf v5/skills/delta-debugger && ls v5/skills/ | grep -c delta-debugger`
Expected output: `0`
Then run: `grep -rl "delta-debugger" v5/skills/ || echo "no dangling refs"`
Expected: `no dangling refs` (if other v5 skills reference it, list them in the task report — do NOT edit v5 content; v5 is import-only).

---

### Task 4: done-gate skill (v5 promotion — rewrite, validate, delete original)

**Files:**
- Create: `v2/skills/done-gate/SKILL.md`
- Delete (after validation): `v5/skills/done-gate/`

- [ ] **Step 1: Confirm current state**

Run: `ls v2/skills/ | grep done-gate; ls v5/skills/ | grep done-gate`
Expected: absent from v2, present in v5. If already in v2 and gone from v5, skip to Step 3 and validate the existing file.

- [ ] **Step 2: Write the rewritten v2 skill file**

Note for the implementer: the v5 original references Forge-only skills (`proof-gate`, `expiring-assumptions`, `request-review`, agent names). The rewrite below remaps: proof-gate → inline PROVEN-BY evidence check; expiring-assumptions → v2 **track-assumption** (exists in v2, promoted by the concurrent session) with fail-soft; blast-radius → v2 **blast-radius** (same) with manual fallback; routing targets → v1 **requesting-code-review** and v2 **reviewer-lenses**. Before writing, verify those two concurrent-session skills still exist (`ls v2/skills/ | grep -E 'blast-radius|track-assumption'`); if either is missing, use only the manual fallback wording already present in the content below (it degrades cleanly).

Write `v2/skills/done-gate/SKILL.md` with exactly this content:

````markdown
---
name: done-gate
description: Use before any "done", "ready", or "complete" claim, and before requesting review or opening a PR — runs the full completion battery (tests, lint, PROVEN-BY evidence, assumption check), risk-scores the change, and routes it to the right review depth instead of relying on memory.
author: Donal Moloney
tier: v2
supports: [verification-before-completion, requesting-code-review]
type: decision
chains-to: reviewer-lenses
---

## Not this skill if

- Mid-task progress check — gates fire at the "done" boundary only; for iterating a failing suite to green, that is v2 **loop-until-green**.
- Re-verifying after a one-line fix to a previously failed gate — re-run only the failing check, not the full battery.
- You are a subagent whose parent will run the gate — defer to the parent's gate.
- Documentation-only change with zero code delta — lint + evidence check suffice; skip the full battery explicitly.

# Done Gate

## Purpose

v1 **verification-before-completion** demands evidence before claims but leaves two things to memory: *which* checks make up the full battery, and *how much review* the change deserves afterward. This gate bundles the battery into one call and makes review depth a function of measured risk, not mood — fast-path for trivial changes, multi-lens review for risky ones.

**Core rule:** no "done" without a green battery and an attached `PROVEN BY:`. The battery runs to completion — never short-circuit on the first failure; the full picture is the point.

## Procedure

1. **Run the full battery** (all four, regardless of failures):
   - **Tests** — full suite. Record total/pass/fail/skipped. A skipped test is not a pass — flag it explicitly.
   - **Lint** — zero new warnings. A suppression introduced by this change is a flag, not a pass.
   - **Evidence check** — the task has a real `PROVEN BY:` trail per v1 **verification-before-completion**: commands were run, output was read, claims trace to output. An empty or templated evidence block is a hard fail.
   - **Assumption check** — if the project tracks assumptions (v2 **track-assumption** ledger), scan for entries this change touches whose expiry passed or whose condition is now testable. Stale assumptions attached to this change fail the battery; stale assumptions elsewhere are a warning. Fail-soft: no ledger → record "no assumption ledger" and move on.
2. **If any check failed:** the gate result is FAIL. Report per-check results and stop — no risk score, no routing, no "done".
3. **Score the blast radius.** Use v2 **blast-radius** if available; otherwise count distinct modules that import or call the changed symbols and use that count as the score. Low (0–2): isolated, no shared-state spillover. Medium (3–5): crosses a defined interface or shared utility. High (6+): public API, shared schema, global config, or critical path.
4. **Route by risk and change shape** (apply every matching row):

   | Risk / shape | Review route |
   |---|---|
   | Low — any shape | Fast path: single reviewer via v1 **requesting-code-review** |
   | Medium — any shape | v1 **requesting-code-review** with the gate result attached |
   | High — any shape | v2 **reviewer-lenses**, minimum three lenses |
   | Any — new/changed types or interfaces | Ensure the architecture lens is among the dispatched lenses |
   | Any — new error paths or swallowed exceptions | Ensure the correctness lens explicitly covers error handling |
   | Any — auth, permissions, secrets, or input handling touched | Security lens is mandatory, whatever the risk score |

5. **Emit the gate result** as one block: per-check battery lines, risk score + label + one-line rationale, the routed review depth, and the `PROVEN BY:` block. Then hand off to the routed review.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Short-circuiting the battery on the first failure | Run all four; report the full picture |
| Treating a skipped test as a pass | Skipped is flagged, never green |
| Accepting a placeholder PROVEN BY | Real, traceable evidence or hard fail |
| Routing before the battery is green | A FAIL gate emits no routing — there is nothing to review yet |
| Collapsing multiple matching shape rows into one | Every matching row applies; lenses are additive |
| Using the gate as a progress check | Boundary event only; mid-task iteration belongs to v2 **loop-until-green** |

## After

Hand the gate result to the routed review (v1 **requesting-code-review** or v2 **reviewer-lenses**). Process findings via v1 **receiving-code-review**.

PROVEN BY: the emitted gate block — four battery lines (tests N/N, lint clean, evidence check PASS, assumption scan result), risk score with rationale, and the routed review depth. A "done" claim without this block, or a routing produced from a failed battery, is invalid under this skill.
````

- [ ] **Step 3: Run the skill-lint checklist**

Expected: `Overall: PASS — all 7 structural checks green.` (Check 7: `verification-before-completion`, `requesting-code-review`, `receiving-code-review` in `v1/`; `reviewer-lenses`, `loop-until-green`, `track-assumption`, `blast-radius` in `v2/skills/`. If `track-assumption` or `blast-radius` were removed by the concurrent session, replace those references with the inline fallback wording and re-run.)

- [ ] **Step 4: Dispatch the skill-auditor agent**

Prompt: "Audit v2/skills/done-gate/SKILL.md against the v2 tier rules in CLAUDE.md. It is a promotion of v5/skills/done-gate — also confirm the rewrite removed Forge-only references (proof-gate, expiring-assumptions, request-review, devils-advocate-as-reviewer-name). Report pass/fail with evidence."
Expected: PASS. Fix findings, re-run Step 3.

- [ ] **Step 5: Delete the v5 original and verify**

Run: `rm -rf v5/skills/done-gate && ls v5/skills/ | grep -c done-gate`
Expected output: `0`
Then run: `grep -rl "done-gate" v5/skills/ || echo "no dangling refs"`
Expected: `no dangling refs` (if other v5 skills reference it, list them in the report — do not edit v5 content).

---

### Task 5: post-merge-retro skill (net-new)

**Files:**
- Create: `v2/skills/post-merge-retro/SKILL.md`

- [ ] **Step 1: Confirm it does not already exist**

Run: `ls v2/skills/ | grep post-merge-retro`
Expected: no output. If it exists, skip to Step 3 and validate.

- [ ] **Step 2: Write the skill file**

Write `v2/skills/post-merge-retro/SKILL.md` with exactly this content:

````markdown
---
name: post-merge-retro
description: Use after a branch is merged (or a PR is opened and handed off) at the end of v1 finishing-a-development-branch — runs the ship checklist (changelog, release step, smoke check) and a structured retro that routes durable learnings into CLAUDE.md, skills, or the decision ledger instead of losing them.
author: Donal Moloney
tier: v2
supports: [finishing-a-development-branch]
type: process
pairs-with: decision-ledger
---

## Not this skill if

- The merge/PR decision has not been made yet — that is v1 **finishing-a-development-branch**; this skill starts where it ends.
- You are verifying the work itself is complete — that already happened at v2 **done-gate** / v1 **verification-before-completion**, before the merge.
- Something went wrong in production or during the work — that is v2 **incident-postmortem** (failure analysis); the retro is the routine learning loop for work that went fine.

# Post-Merge Retro

## Purpose

The core superpowers lifecycle ends at the merge/PR decision — nothing ships the change onward, and nothing captures what the feature taught. Deploy steps get forgotten, changelogs drift, and the same estimation mistake or codebase surprise repeats next feature because the learning lived only in a dead session. This skill is the explicit final beat: ship it properly, then harvest the learnings into places future sessions actually read.

**Core rule:** every checklist item ends in exactly one of two states — done with evidence, or skipped with a one-line reason. Silent skips are the failure mode this skill exists to kill.

## Procedure

**Ship checklist (run immediately after merge):**

1. **Changelog / release notes** — if the project keeps one, add the entry now. No changelog → skip explicitly ("no changelog in this project").
2. **Release step** — if a deploy/release/publish pipeline exists, run or trigger the project's documented step. No pipeline → skip explicitly.
3. **Post-merge smoke check** — run the project's verification command once on the merged main branch (not your feature branch — the merge itself can break things a green branch didn't show). Record the output.
4. **Cleanup confirmation** — confirm the worktree/branch cleanup from v1 **finishing-a-development-branch** actually completed: the feature branch and worktree are gone (unless the chosen option keeps them — then say so).

**Retro (three questions, answered in writing):**

5. **What did this feature teach?** Codebase surprises, wrong estimates, tooling friction, process snags — one line each, concrete.
6. **Which learnings are durable, and where do they live?** Route each one: project facts an agent needs every session → CLAUDE.md; a repeatable workflow rule → a skill (new or an edit proposal); a ratified choice with rejected alternatives → v2 **decision-ledger**. A learning with no route is noted as not-durable and dropped consciously.
7. **What was deferred?** List review items or follow-ups explicitly deferred during the work, each with where it is now recorded. "Nothing deferred" is a valid answer; an unrecorded deferral is not.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Skipping the smoke check because the branch was green | The merge is a new state; run the check on merged main |
| Writing the retro in the conversation and nowhere else | Learnings route to CLAUDE.md, a skill, or the ledger — the conversation dies, those don't |
| "Lessons learned" essays | One line per learning, each with a routing destination |
| Treating an empty retro as failure | A clean feature with no surprises is a fine outcome — record "no durable learnings" and close |
| Running the retro days later | Run it in the same session as the merge while the friction is still fresh |

## After

Verify every routed learning actually landed (the CLAUDE.md edit made, the ledger entry appended, the skill proposal recorded), then close out the session normally.

PROVEN BY: the pasted ship checklist (4 items, each done-with-evidence or skipped-with-reason) and the written three-question retro with a routing destination per durable learning. A closed-out feature with a silent skip or an unrouted learning is invalid under this skill.
````

- [ ] **Step 3: Run the skill-lint checklist**

Expected: `Overall: PASS — all 7 structural checks green.` (Check 7: `finishing-a-development-branch`, `verification-before-completion` in `v1/`; `done-gate`, `decision-ledger`, `incident-postmortem` in `v2/skills/` — done-gate exists after Task 4; incident-postmortem was promoted by the concurrent session, verify with `ls v2/skills/ | grep incident-postmortem` and if it is gone, change that boundary line to reference v1 **systematic-debugging** for failure analysis instead.)

- [ ] **Step 4: Dispatch the skill-auditor agent**

Prompt: "Audit v2/skills/post-merge-retro/SKILL.md against the v2 tier rules in CLAUDE.md. Report pass/fail with evidence."
Expected: PASS. Fix findings, re-run Step 3.

---

### Task 6: v2 README — register all 8 spec items

**Files:**
- Modify: `v2/README.md` (the "Current skills" table)

- [ ] **Step 1: Re-read the current table**

The concurrent session is also editing this file. Read `v2/README.md` fresh and check which of the 8 spec items already have rows. Add ONLY the missing ones; never remove or reorder rows the other session added.

- [ ] **Step 2: Add the missing rows**

Insert these rows (alphabetical position within the existing table; skip any that already exist):

```markdown
| `compile-goal-to-contract` | subagent-driven-development, writing-plans |
| `decision-ledger` | brainstorming, writing-plans, executing-plans |
| `delta-debugger` | systematic-debugging, test-driven-development |
| `dispatch-triage` | subagent-driven-development |
| `done-gate` | verification-before-completion, requesting-code-review |
| `post-merge-retro` | finishing-a-development-branch |
| `reviewer-lenses` | requesting-code-review, dispatching-parallel-agents |
| `scope-decomposition` | brainstorming, writing-plans |
```

- [ ] **Step 3: Verify every table row resolves**

Run: `grep -o '`[a-z-]*`' v2/README.md | tr -d '\`' | sort -u | while read s; do [ -d "v2/skills/$s" ] || [ -d "v2/plugins/$s" ] || echo "MISSING: $s"; done`
Expected: no `MISSING:` lines for the 8 spec items. (Rows added by the concurrent session that don't resolve: report, don't fix.)

---

### Task 7: Append the four v1-supercharging work orders

**Files:**
- Modify: `v1/SUPERCHARGING-OPTIONS.md` (append a new section at the end of the file, after the renaming note)

- [ ] **Step 1: Append exactly this section to the end of the file**

```markdown

---

## Work orders from the 2026-06-10 v2 re-analysis

Four procedure gaps found in the fresh v1 re-read are in-place improvements to
existing v1 skills, not v2 skills (spec:
`docs/superpowers/specs/2026-06-10-v2-reanalysis-design.md`, "Rejected and
re-routed"). Fold each into its skill's next supercharging pass:

- **brainstorming — spec self-review rubric.** The self-review step lists four
  dimensions (placeholders, consistency, scope, ambiguity) with no pass/fail
  criteria per dimension. Add a concrete rubric with one example failure each.
- **test-driven-development — RED-phase validation checklist.** "Verify the test
  fails correctly" names symptoms but no procedure. Add a checklist
  distinguishing assertion-failure from error, expected-message match, and
  fails-for-the-right-reason confirmation.
- **systematic-debugging — instrumentation recipes.** "Add diagnostic
  instrumentation at component boundaries" has no how. Add a short recipe table
  per context (app code, test harness, CI pipeline, external service boundary).
- **writing-plans — task-granularity heuristic.** The 2–5-minute step rule has
  no estimation procedure. Add the three-question check: one sentence to
  describe? one observable outcome? no hidden sub-decisions?
```

- [ ] **Step 2: Verify the append**

Run: `tail -5 v1/SUPERCHARGING-OPTIONS.md`
Expected: the last lines are the writing-plans work-order bullet. Confirm the decision-tracker table above the new section is untouched.

---

### Task 8: Tier-wide verification

**Files:**
- Verify only — no modifications.

- [ ] **Step 1: Spec coverage check**

Confirm each of the 8 spec items exists and passed validation: `compile-goal-to-contract`, `decision-ledger`, `delta-debugger`, `dispatch-triage`, `done-gate`, `post-merge-retro`, `reviewer-lenses`, `scope-decomposition` — all under `v2/skills/`. Run: `for s in compile-goal-to-contract decision-ledger delta-debugger dispatch-triage done-gate post-merge-retro reviewer-lenses scope-decomposition; do [ -f "v2/skills/$s/SKILL.md" ] && echo "OK $s" || echo "MISSING $s"; done`
Expected: 8 × `OK`.

- [ ] **Step 2: Promotion hygiene check**

Run: `for s in delta-debugger done-gate; do [ -d "v5/skills/$s" ] && echo "STILL IN V5: $s" || echo "v5 clean: $s"; done; comm -12 <(ls v2/skills) <(ls v5/skills)`
Expected: `v5 clean` ×2 and no duplicate names between v2 and v5.

- [ ] **Step 3: supports: integrity sweep**

Run: `grep -h "^supports:" v2/skills/*/SKILL.md | tr -d 'supports:[]' | tr ',' '\n' | tr -d ' ' | sort -u | while read s; do [ -d "v1/$s" ] || echo "BAD SUPPORTS: $s"; done`
Expected: no `BAD SUPPORTS:` lines. (Failures in skills the concurrent session added: report per-file, fix only files this plan created.)

- [ ] **Step 4: Confirm done against the spec**

Re-read `docs/superpowers/specs/2026-06-10-v2-reanalysis-design.md` section by section. Per v1 **verification-before-completion**: paste the evidence (lint reports, audit results, the verification command outputs from Steps 1–3) before claiming the plan complete. Note in the final report: the spec's "left in v5" dispositions for `blast-radius`, `track-assumption`, `devils-advocate`, `write-adr`, `security-audit`, `incident-postmortem`, `migrate-codebase` were overtaken by the concurrent session's promotions — flag for the user, do not revert.
