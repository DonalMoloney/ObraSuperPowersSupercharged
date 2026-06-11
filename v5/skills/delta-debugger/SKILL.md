---
name: delta-debugger
description: Use on a reproducible failure — automatically shrinks the failing input to a minimal reproducer (ddmin) and localizes the introducing commit (git bisect). Mechanizes the manual repro-minimization in diagnose-bug.
author: Donal Moloney
track: B
type: implementation
chains-to: write-tests-first
---

## Not this skill if
- The failure isn't reproducible yet — establish a repro first (`find-root-cause`)
- The input is already minimal and the commit is known
- You already have a minimal failing test and now want the *fix* — hand off to `self-repair-loop` to race competing fixes against that referee. Deciding factor: this skill **minimizes and localizes** (shrink the input, find the bad commit); `self-repair-loop` **repairs** once the repro is tight.

# delta-debugger — mechanical minimization + localization

## Purpose

Turn the "write hypothesis, poke at it" loop into two solved procedures: shrink the failing input to the smallest form that still triggers the bug, then binary-search the commit history to find exactly which change introduced it.

## Triggers

**Use when:**
- "Minimize this repro" or "shrink the failing input"
- "Which commit broke it?" or "find the bad commit"
- Inside the reproduce phase of `diagnose-bug` when the raw input is large and unwieldy
- A CI failure has been open for more than one investigation pass and the repro is still noisy
- You need a clean, small test case to hand off to `write-tests-first`

**Don't use when:**
- The failure is not yet reproducible — run `find-root-cause` first
- The input is already minimal and the introducing commit is already known — skip ahead to `write-tests-first`
- The codebase has no commit history (brand-new or history-wiped repo) — `git bisect` cannot run
- The failure is flaky (non-deterministic) — ddmin and bisect both require a stable pass/fail predicate

## Core rule

> **Rule:** A minimization is only valid if the shrunk input *still fails*. Re-run it and attach the evidence.

## Algorithm

**ddmin (delta debugging)** partitions the input into chunks of size N/2, N/4, N/8, … and removes chunks while the failure predicate remains true. The loop terminates when no single chunk can be removed without making the predicate false — yielding a 1-minimal input.

**`git bisect run <script>`** binary-searches the commit graph. It calls your test script for each candidate commit; exit 0 means good (no failure), exit 1–124 means bad (failure present), exit 125 means skip (untestable commit). Git isolates the first bad commit in O(log N) test runs.

Both procedures require one artifact: a predicate script that exits with a clear pass/fail code.

## Steps

### 1. Write the predicate script

Wrap the failure as a shell script that exits 0 on pass and 1 on fail. The script must be self-contained — no manual steps, no interactive prompts. Test the script against the full, unminimized input before proceeding: confirm it exits 1. If it exits 0, the failure isn't actually reproducible and this skill cannot proceed.

Save the script to a stable path (e.g., `./scripts/is_broken.sh`). Commit or stash any working-tree changes so `git bisect` can check out commits cleanly.

### 2. Minimize the input with ddmin

Import `delta_debug` from `andrewchambers/ddmin-python` (no external deps) or implement the two-line ddmin loop directly. Pass the full failing input and the predicate. Let the algorithm run to completion — do not interrupt early.

After ddmin finishes, run the predicate manually against the minimized input and record the exit code. If the predicate exits 0 on the minimized input, ddmin has produced a false minimal — this means the failure is input-order-dependent or stateful. In that case, split the input into ordered segments and re-run ddmin on each segment independently.

Keep both the original input and the minimized input. Record the ratio (e.g., "reduced from 4 800 lines to 23 lines").

### 3. Localize the introducing commit with git bisect

Run `git bisect start`. Mark the current HEAD as bad: `git bisect bad`. Mark the last known-good commit: `git bisect good <sha>`. Then hand control to the script: `git bisect run ./scripts/is_broken.sh`.

Let bisect run to completion. When it terminates, `git bisect log` records every tested commit and its classification. Record the final output — it names the first bad commit SHA and the author.

Run `git bisect reset` to restore the working tree to HEAD.

### 4. Cross-validate

Replay the minimized input against the identified bad commit's parent (the last good commit) and confirm the predicate exits 0 there. Replay the same input against the bad commit itself and confirm the predicate exits 1. This two-point check closes the localization loop: the minimized input fails at the bad commit and passes at its parent.

If the two-point check fails — e.g., the minimized input also fails at the parent — the introducing commit is earlier than bisect found. Widen the bisect range and repeat from step 3.

### 5. Hand off to write-tests-first

Package the minimized input and the bad commit SHA into a failing test. The test is now the single smallest proof of the regression. Hand the test file to `write-tests-first` to formalize it as a permanent regression guard before any fix is attempted.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Starting ddmin without verifying the predicate exits 1 on the original input | Run the predicate manually before invoking ddmin; if it exits 0, re-establish the repro first |
| Using a flaky predicate (sometimes passes, sometimes fails) | Add a retry loop inside the predicate script and treat any single pass as "good"; flaky tests invalidate ddmin's monotonicity assumption |
| Not stashing working-tree changes before `git bisect run` | Bisect checks out commits and will clobber uncommitted files; always commit or stash first |
| Stopping ddmin early because "it's small enough" | Only stop when ddmin itself terminates; a manually stopped run may not be 1-minimal, giving a noisier test case |
| Accepting bisect output without the two-point cross-validation | Bisect names the first bad commit but boundary errors are possible if early commits were skipped; always confirm parent-good / child-bad |
| Forgetting `git bisect reset` after localization | Leaves the repo in detached-HEAD state; all subsequent work happens on the wrong commit |

## Verification / Proof

Before closing this skill, confirm all three items are in hand:

1. The minimized input text (or file path) and the reduction ratio (original size → minimized size).
2. The bad commit SHA, author, and commit message from `git bisect log`.
3. The two-point cross-validation result: predicate exit code at parent commit (must be 0) and at bad commit (must be 1).

Then chain to `write-tests-first` with the minimized input as the test seed.

```
PROVEN BY:
  - ddmin run: <original size> → <minimized size>; predicate exits 1 on minimized input (attached log)
  - git bisect: first bad commit <SHA> — "<commit message>" by <author>
  - Two-point check: parent <parent-SHA> exits 0, bad <SHA> exits 1
  - Minimized test case handed to write-tests-first at <file path>
```

## Adapt from
- **`andrewchambers/ddmin-python`** (importable `delta_debug`, no deps) · The Debugging Book's
  `DeltaDebugger` (Zeller reference) · `git bisect run` (built-in).
  <https://github.com/andrewchambers/ddmin-python>
