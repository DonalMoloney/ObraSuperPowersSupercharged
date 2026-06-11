---
name: delta-debugger
description: Use when a failure is reproducible but the failing input is large or the introducing commit is unknown — mechanically shrinks the input to a minimal reproducer (ddmin) and localizes the bad commit (git bisect run), turning "poke at it" debugging into two solved procedures.
author: Donal Moloney
tier: v2
supports: [systematic-debugging, test-driven-development]
type: technique
pairs-with: loop-until-green
---

## Not this skill if

- The fix is already known or obvious — just fix it and prove it with v1 **verification-before-completion**; localization machinery adds nothing.
- The failure is not reproducible yet — establish a deterministic repro first via v1 **systematic-debugging** Phase 1; ddmin and bisect both require a stable pass/fail predicate.
- The input is already minimal and the introducing commit is known — go straight to v1 **test-driven-development** to pin it with a failing test.
- You are iterating fix → verify until a suite goes green — that is v2 **loop-until-green**; this skill finds *where* the fault is before any fix is attempted, it never repairs.
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

Localization claims without `PROVEN BY:` are invalid under this skill.
