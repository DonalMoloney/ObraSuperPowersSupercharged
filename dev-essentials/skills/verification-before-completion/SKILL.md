---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

When the project has a verification manifest (below), steps 1–3 collapse into one
command.

## The Verification Manifest

The gate fails most often at the moment it matters most: end of task, tired, N
commands to remember. Make the gate one command instead.

Keep a `verify.yaml` at the project root mapping claim types to the commands that
prove them — flat `claim-type: command` pairs, one per line:

```yaml
tests-pass: pytest -q
build-succeeds: npm run build
lint-clean: ruff check .
```

Run the runner shipped with this skill (`scripts/verify-claims.sh`, path relative
to this SKILL.md):

```bash
scripts/verify-claims.sh                      # run every manifest entry fresh
scripts/verify-claims.sh tests-pass           # run only the named claim type(s)
scripts/verify-claims.sh --init               # scaffold a starter verify.yaml
```

The runner executes each entry fresh and prints one timestamped evidence block per
claim — claim type, command, exit code, UTC timestamp, output tail — and exits
non-zero if anything failed. Paste the blocks into the completion message, so the
claim and the evidence proving it travel together:

```
### Evidence: tests-pass
- command: pytest -q
- exit code: 0
- timestamp (UTC): 2026-06-11T14:02:31Z
- output (last 10 lines; full log: /tmp/verify-claims.x7Kp2q/tests-pass.log):
    34 passed in 2.41s
```

**Manifest rules:**

- No manifest yet? Run `--init` once and fill in this project's real commands.
  Setup is one-time per project; every completion afterward is one command.
- The gate's IDENTIFY step still applies. Confirm the manifest command actually
  proves the claim you're making — a stale manifest verifies the wrong thing,
  which is worse than no manifest. Project changed its test runner? Update
  `verify.yaml` first.
- A claim type with no manifest entry does NOT get a pass. Add the entry, or run
  the proving command manually and quote its output.
- Evidence expires. If any relevant file changed after the run, the blocks are
  stale — run again.

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
✅ A captured RED+GREEN evidence block from test-driven-development's
   evidence trail (failure was already proven before the fix existed)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
