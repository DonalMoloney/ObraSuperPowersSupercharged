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
