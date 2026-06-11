---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Bundle the evidence and classify risk:**

```bash
bash scripts/bundle-review-context.sh --tests "npm test" --plan docs/plan.md > /tmp/review-bundle.md
```

The script (at `requesting-code-review/scripts/bundle-review-context.sh`) resolves
BASE/HEAD SHAs (merge-base with origin/main by default; override with `--base`/`--head`),
captures a size-capped diff stat, runs the test command and records its exit code plus
output tail, excerpts the plan file, and emits a `Risk:` classification with a
recommended review depth. Thresholds and the risky-path pattern are env-overridable
(`REVIEW_*` variables) for per-project tuning.

If the script can't run (no git repo, no usable base), fall back to manual SHAs:

```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Scale review depth to the bundle's `Risk:` line:**

| Risk | Default signals | Review depth |
|------|-----------------|--------------|
| LOW | ≤100 lines, ≤4 files, no risky paths | One reviewer, quick pass: plan alignment + obvious bugs only |
| MEDIUM | between LOW and HIGH | One reviewer, full `code-reviewer.md` template |
| HIGH | ≥500 lines, or ≥12 files, or risky paths touched (auth, migrations, schema, payments, secrets, CI/deploy) | Three parallel reviewers: spec-compliance, code-quality, silent-failure |

The classification is a heuristic, not a verdict. You may move the tier in either
direction when you know the blast radius better — but state the reasoning in the
review request.

**3. Dispatch code reviewer subagent(s):**

Use Task tool with `general-purpose` type, fill template at `code-reviewer.md`,
and paste the evidence bundle into the prompt so the reviewer starts from captured
facts, not your summary.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do (the bundle's plan excerpt covers this)
- `{BASE_SHA}` - Starting commit (from the bundle header)
- `{HEAD_SHA}` - Ending commit (from the bundle header)

**Depth adjustments:**
- **LOW:** append to the prompt: "Quick pass: check plan alignment and obvious bugs
  only; skip the Architecture and Production-readiness sections."
- **HIGH:** dispatch three reviewers in parallel from the same template + bundle,
  each with one added focus line:
  - Spec-compliance: "Optimize for Plan alignment; treat other sections as secondary."
  - Code-quality: "Optimize for Code quality and Architecture."
  - Silent-failure: "Optimize for failure modes: swallowed errors, empty catch blocks,
    unchecked return values, tests that can't fail."

  Merge their findings before acting; when reviewers duplicate an issue, keep the
  highest severity assigned.

**4. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

bash scripts/bundle-review-context.sh --tests "npm test" > /tmp/review-bundle.md

[Bundle reports]:
  Risk: MEDIUM
  Signals: 6 files, 210 lines changed (lockfiles excluded)
  Risky paths: none
  Recommended depth: one reviewer, full code-reviewer.md template

[Dispatch one code reviewer subagent, bundle pasted into prompt]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Executing Plans:**
- Review after each task or at natural checkpoints
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Downgrade the bundle's risk tier without stating technical reasoning
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: requesting-code-review/code-reviewer.md
Bundler script at: requesting-code-review/scripts/bundle-review-context.sh

## Supercharged vs upstream

Baseline: obra/superpowers 5.1.0 `requesting-code-review`, otherwise verbatim. Change applied: **Option A — Risk-scaled depth (via C bundler)**, recommended option adopted 2026-06-11 (v1/SUPERCHARGING-OPTIONS.md; Option C's evidence bundler is the mechanism, per CC3 + CC5).

What changed and why:

- **Shipped `scripts/bundle-review-context.sh`** (CC3): assembles the reviewer's context mechanically — BASE/HEAD SHAs, lockfile-excluded diff stat, test command exit code + output tail, plan excerpt — in a fixed evidence-bundle format (CC5). Why: reviewer quality is mostly context quality; upstream had the requester assemble all of this by hand from memory. Option C's "over-include" trade-off is handled with hard size caps (diff stat 80 lines, test tail 40, plan head 120, all env-overridable).
- **Risk classification + depth table** ("How to Request" step 2): the script classifies the change LOW / MEDIUM / HIGH from diff size, files touched, and blast-radius path hits (auth, migrations, schema, payments, secrets, CI/deploy); the skill maps each tier to a review depth — quick single pass, full single template, or three parallel reviewers (spec-compliance, code-quality, silent-failure). Why: upstream applied one review depth to every change, over-reviewing trivia and under-reviewing risk. Option A's heuristics-tuning trade-off is handled by making every threshold and the risky-path pattern `REVIEW_*` env-overridable, plus an explicit judgment-override rule (either direction, reasoning required).
- **Dispatch step rewritten** (step 3): the bundle is pasted into the reviewer prompt; LOW gets a scope-narrowing line, HIGH gets three parallel dispatches from the same template with one focus line each and a merge rule (dedupe, highest severity wins). Why: this is how the depth tiers actually execute against the unchanged `code-reviewer.md` template.
- **Manual-SHA fallback kept** (step 1): upstream's hand-set SHAs remain the documented fallback when the script can't run. Why: the script must not become a hard dependency for review.
- **Example updated** to show the bundler invocation and a MEDIUM classification instead of grepping SHAs from `git log`. **Red Flags** gained one item: never downgrade the risk tier without stated technical reasoning — the failure mode Option A introduces.

Unchanged: when-to-review rules, the `code-reviewer.md` template itself, feedback-handling rules, workflow integration, and the rest of Red Flags.
