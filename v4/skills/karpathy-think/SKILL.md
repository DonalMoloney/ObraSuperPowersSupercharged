---
name: karpathy-think
description: Use before the first edit of any non-trivial change — emit a fixed think-before-coding block that surfaces your interpretation, the alternatives you weighed, and any open questions, and pins the in-scope file set so edits stay surgical
tier: v4
inspiration: "Karpathy — think before coding; no silent assumptions / spec is the source of truth (Software 3.0 talk, YC AI Startup School, June 2025; 'keep AI on a tight leash')"
pairs-with: [autonomy-slider]
---

# Karpathy Think

**Not this skill if:**

- You are designing an open-ended *feature* that is not yet a concrete change → **v1 brainstorming** owns the heavier design ritual. This skill is the light, per-task check that fires on every coding task once the change is concrete.
- You are choosing *how much autonomy* the work gets → **v4 autonomy-slider**. That skill picks the leash length (L0–L3) and downgrades it on surprise; this one runs *before* the first edit at any level to make the interpretation explicit. They stack: think first, then declare the autonomy level against the interpretation you just wrote.
- You need to name the *verification target* (what "correct" means) before coding → **v4 verification-target-first**. That gate produces a target artifact; this gate produces a shared understanding. Run this one first — you cannot name a good target for a spec you have silently misread.

This is a rigid ritual, not an adaptive guideline. Complete every item before the first `Edit`/`Write`. Skip only for one-line, unambiguous edits (typo fixes, version bumps, mechanical renames).

## The gate

No implementation edits until the think block is emitted in the conversation. Emit exactly this, filled in:

```
Interpretation: <one-sentence restatement of what is being asked, in your words>
Alternatives considered: <the options you weighed and the one-line reason you picked one>
Open questions: <every ambiguity — if this line is non-empty, STOP and ask before editing>
In-scope files: <the files/dirs this change legitimately needs to touch>
```

If `Open questions` is non-empty, you do not edit — you ask. A silent assumption is the failure this skill exists to prevent; surfacing it costs one line, debugging the wrong implementation costs an hour.

## No-silent-assumptions table

The three thoughts that skip the ritual, and what to do with each:

| The thought | Why it is the trap | What to do |
|---|---|---|
| "This is obvious" | Obvious-to-you and asked-for can differ; that gap is invisible until the wrong diff lands | Write the Interpretation line anyway — if it is truly obvious it costs one sentence |
| "There's only one way" | There is rarely one way; "only one" usually means you stopped looking | Name the one way *and* the alternative you rejected and why |
| "No ambiguity here" | Unstated ambiguity is the kind that bites; absence of felt doubt is not absence of doubt | Confirm "none" explicitly in Open questions — make the claim, don't assume it |

## Pin the scope

The `In-scope files` line is not decoration — it is the leash. List only the files and directories the task legitimately needs. Once pinned:

- Treat any edit landing **outside** the pinned set as a stop-and-justify event: either the interpretation was incomplete (re-emit the block with the new file and why) or the change is sprawling (a sign to narrow it).
- This is the precondition for surgical edits and for **v4 autonomy-slider**'s downgrade trigger "an edit lands outside the predicted file set" — that trigger needs a predicted set to compare against, and this line is it.

If you cannot yet name the in-scope files, you are not ready to edit — you are still exploring. Finish exploring, then emit the block.

## Provenance

- **Idea:** Karpathy frames LLM coding as Software 3.0 where the prompt/spec is the program, and repeatedly warns to keep the AI "on a tight leash" rather than handing it a vague ask and accepting whatever it generates — small, verifiable increments against an explicit, agreed understanding, never a silent leap from an under-specified request to a sprawling diff. The spec being the source of truth means the agent's *interpretation* of the spec must be made visible and agreed before code, because a misread spec produces confidently-wrong code.
- **Where stated:** Andrej Karpathy, "Software Is Changing (Again)" / Software 3.0 keynote, Y Combinator AI Startup School, June 2025 (the "keep it on a leash" and "spec is the program" framings; recording on YC's channel) and his surrounding Software 1.0/2.0/3.0 writing; verified via web search, June 2026. The "no silent assumptions" formulation is the operational restatement of the leash discipline.
- **How this tool operationalizes it:** It converts "think before coding, on a leash" from advice into a hard pre-edit gate — a fixed four-line block (interpretation, alternatives, open questions, in-scope files) that must appear before the first edit, a table that defuses the three thoughts agents use to skip thinking, and a pinned file set that makes "surgical" enforceable and feeds the autonomy-slider's out-of-scope downgrade trigger.
