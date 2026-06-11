---
name: self-review-skill
description: Use after publishing a SKILL.md to run a structured quality pass on the skill itself and patch any weak sections without requiring a full rewrite.
author: Donal Moloney
track: D
type: process
chains-to: writing-skills
---

## Not this skill if
- You want to verify the skill fires correctly under realistic tasks — use `skill-test-harness` instead.
- The SKILL.md does not exist yet and you are writing from scratch — use `writing-skills` instead.
- You want to align formatting and house style across many skills at once — use `unify-skill-style` instead.

# self-review-skill — structured quality pass on a published skill

## Purpose

Load a SKILL.md, score it against a fixed quality rubric, identify the weakest sections, and produce targeted patches. Close quality gaps without discarding the existing structure. Leave strong sections untouched.

## Core rule

> **Rule:** Score every section before writing a single word of patch. Rewriting a section you have not scored wastes effort and risks breaking what was already working.

## Triggers

**Use when:**
- You published or merged a skill and suspect a section is incomplete after the fact
- A `skill-test-harness` verdict returns FAIL or PARTIAL and hands you a list of contract gaps to fix
- A peer review flags a section as vague, missing, or inconsistent with other skills
- You are doing a planned quality sweep across multiple skills and need a repeatable per-skill pass
- You are about to chain the skill into a larger workflow and discover it lacks a clear `PROVEN BY:` spec

**Don't use when:**
- The skill has never been drafted — start with `writing-skills`
- You only need to verify behavior, not prose — use `skill-test-harness`
- The skill scores 90+ on every rubric dimension and the only proposed change is stylistic preference

## The pattern

```
load(skill) → score_each_section → rank_gaps → patch_weak → verify_patches → emit_diff
```

1. **Load** — read the target SKILL.md in full before scoring anything.
2. **Score** — run the rubric (see Step 2) against every section; record a score and a one-line verdict per section.
3. **Rank** — sort scored sections by gap severity; identify the bottom 1–3 sections to patch.
4. **Patch** — rewrite only the flagged sections; leave passing sections as-is.
5. **Verify** — re-score the patched sections against the same rubric; confirm scores improved.
6. **Emit** — produce a diff block (old → new) for every changed section plus a final score summary.

## Steps

### Step 1 — Load the target skill

Read the SKILL.md at its file path. Do not rely on memory or a cached version of the skill — read it fresh. Confirm you have the complete file before continuing: check that frontmatter, all required sections, and the final `## Adapt from` or `## Proof` section are present. If any section is missing entirely, flag it as a structural gap before scoring begins.

### Step 2 — Score each section

Apply the following rubric. Score each dimension 1–5. Record the score, a one-line finding, and the specific line range that drove the verdict.

| Dimension | What to score |
|---|---|
| **Trigger accuracy** | Do the "Use when" bullets match the skill's actual purpose? Are any triggers too broad (over-fires) or too narrow (misses obvious cases)? |
| **Step completeness** | Does each step tell the agent exactly what to do? Are there implicit jumps — steps that assume knowledge not given in the preceding step? |
| **Integration** | Does the skill reference the correct upstream and downstream skills? Are `chains-to`, `pairs-with`, or escalation targets accurate and reachable? |
| **Pitfall coverage** | Does the mistakes table cover the failure modes a real agent is likely to hit? Are any common errors missing? Are any rows too generic to act on? |
| **PROVEN BY spec** | Does the verification section name specific, checkable output items — not vague phrases like "evidence of completion"? Can an agent mechanically verify each item? |
| **House style** | Is the prose imperative second person? No passive voice? No filler phrases ("Please note", "It is important to")? Consistent section order? |

Sum the six scores. A skill scoring 24–30 needs no immediate patches. A skill scoring below 18 needs at minimum two sections patched before it is used in production.

### Step 3 — Rank gaps

Sort the scored sections from lowest to highest. Select the bottom 1–3 sections for patching. If two sections score equally low, prefer patching the one that is most likely to cause a behavioral failure (trigger accuracy and step completeness carry more weight than house style).

Write a gap summary before writing any patch:
- Section name
- Current score
- One-sentence diagnosis of the root cause
- Proposed fix approach (add bullets / rewrite steps / strengthen PROVEN BY items / etc.)

Do not skip the gap summary. It forces you to commit to a fix approach before editing and prevents patch drift.

### Step 4 — Patch weak sections

Rewrite each flagged section. Constraints:
- Keep the section header unchanged unless the header itself is the problem (e.g., wrong section name).
- Do not reduce word count below the minimum needed to make the section actionable.
- Do not expand passing sections to compensate for weak ones — targeted patches only.
- For `PROVEN BY:` repairs specifically: replace any vague item (e.g., "proof of work") with a concrete, checkable item (e.g., "Per-section score table with dimension | score | finding for all six rubric dimensions").
- For trigger accuracy repairs: add a "Don't use when" bullet for every over-fire risk you found; tighten "Use when" bullets if they are currently matched by tasks the skill cannot handle.
- For step completeness repairs: add sub-steps for any implicit jump; spell out inputs, outputs, and the decision rule for each step that previously assumed context.

### Step 5 — Verify patches

Re-score each patched section using the same rubric. The patched score must exceed the pre-patch score. If a patched section scores the same or lower, diagnose why and revise before moving on. Do not declare the review complete until every patched section shows improvement.

### Step 6 — Emit the diff and score summary

Produce the review output in three parts:

1. **Score table** — pre-patch and post-patch scores side by side for every section.
2. **Diff block** — for each patched section, show the old text and the replacement text as a labeled before/after block.
3. **PROVEN BY block** — the final evidence record (see Verification below).

Hand the diff to `writing-skills` if the review reveals that the skill needs a full structural rethink rather than targeted patches. Surface this hand-off explicitly rather than attempting a full rewrite inline.

## Common mistakes

| ❌ Mistake | ✅ Fix |
|---|---|
| Scoring from memory instead of reading the file fresh | Always read the SKILL.md at the file path before scoring; cached mental models miss recent edits |
| Patching sections that scored well to hit a word count | Touch only the sections flagged in the gap ranking; leave passing sections exactly as-is |
| Writing a vague `PROVEN BY:` fix (e.g., "evidence provided") | Replace each vague item with a named, checkable artifact — score table, diff block, or specific line reference |
| Conflating house-style fixes with behavioral fixes | Score them separately; fix behavioral gaps (trigger, steps, integration) before cosmetic ones (style, phrasing) |
| Declaring the review done after patching without re-scoring | Re-run the rubric on patched sections; a patch that does not raise the score has not fixed the problem |
| Expanding every section instead of patching targeted gaps | Over-expansion creates noise and makes the skill harder to follow; targeted patches preserve the sections that already work |

## Verification

Hand off to `writing-skills` if the review surfaces structural debt that patches cannot resolve.

The output must contain:

- Pre-patch score table: dimension | score | one-line finding for all six rubric dimensions
- Gap ranking: bottom 1–3 sections with diagnosis and proposed fix approach recorded before any patching
- Post-patch score table: same six dimensions with updated scores
- Diff block: labeled before/after for every patched section (unchanged sections omitted)
- Confirmation that each patched section's post-patch score exceeds its pre-patch score
- `PROVEN BY:` block listing — section patched | pre-patch score | post-patch score | summary of change made

## Adapt from

General self-critique and structured review concepts:
- **Structured critique / red-team review** — the practice of applying a fixed rubric before generating any fix, drawn from code review and technical writing disciplines. No single canonical upstream; the pattern appears in adversarial ML evaluation, document quality audits, and multi-pass editing workflows.
- **Rubric-based assessment** — scoring against named dimensions before ranking gaps is standard in instructional design and writing pedagogy. The six-dimension rubric here is original to this repo.
