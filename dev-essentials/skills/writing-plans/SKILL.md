---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the using-git-worktrees skill at execution time.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Implement this plan task-by-task — dispatch a fresh subagent per task (recommended) or execute inline in this session with review checkpoints between tasks. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

The plan linter (`scripts/lint-plan.py`, next to this file) flags every one of these mechanically — see Self-Review.

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan: run the linter, fix, rerun — then check the things a linter can't. This is a loop you run yourself, not a subagent dispatch.

**1. Run the plan linter:**

```bash
python3 scripts/lint-plan.py docs/superpowers/plans/<filename>.md
```

(The script lives at `scripts/lint-plan.py` next to this skill file — use the absolute path from this skill's directory.) It mechanically checks the format rules above: required plan header, checkbox syntax, per-task **Files:** blocks with exact non-template paths, every placeholder phrase from "No Placeholders", code blocks present in code steps, run steps with a command and expected output, and cross-task identifier drift (a function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug — the linter flags the near-miss).

Fix every ERROR. Read every WARN and either fix it or consciously decide it's fine. Rerun until exit 0. `--strict` treats warnings as errors.

**2. Spec coverage (judgment — the linter can't see the spec):** Skim each section/requirement in the spec. Can you point to a task that implements it? If a requirement has no task, add the task.

**3. Code correctness (judgment — lexical checks can't tell whether the code in a step is *right*):** Re-read each code block with fresh eyes against the spec. Does the test actually test the requirement? Does the implementation match the signatures and types defined in earlier tasks in *meaning*, not just spelling?

If you find issues, fix them inline and rerun the linter. No need to re-review — just fix and move on.

## Execution Handoff

After saving the plan and getting a clean lint (Self-Review step 1), offer execution choice:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- Dispatch a fresh subagent per task; check off each task only after a two-stage review (the work, then the review)
- Keep shared state out of the subagents — each task should be independently executable

**If Inline Execution chosen:**
- Work through the checkboxes in this session, committing at each verified step
- Batch a few tasks between review checkpoints rather than pausing after every line
