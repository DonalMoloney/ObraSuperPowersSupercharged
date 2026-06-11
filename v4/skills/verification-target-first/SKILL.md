---
name: verification-target-first
description: Use when about to implement any change, before writing implementation — blocks implementation until a verification target is named in the conversation, or an explicit waiver is recorded in its place
tier: v4
inspiration: "Cherny — give Claude a verification target to iterate against: tests written and confirmed failing first, or a visual mock to match (Claude Code: Best practices for agentic coding, Anthropic engineering blog, April 2025)"
---

# Verification Target First

**Not this skill if:**

- The target is a failing TEST and you are doing red-green-refactor → `v1/test-driven-development` owns that branch. This skill only gets you to "a failing test exists and is named"; the red-green-refactor loop itself is defined there, not here.
- You are picking WHICH verifier command to run (test runner vs build vs lint, fastest signal) → `v4/fast-verify-loop` (v4).
- The work is done and you are checking it before claiming success → `v1/verification-before-completion`. This skill is the gate BEFORE implementation; that one is the gate after.

## The gate

No implementation code, edits, or config changes until a **target artifact exists
and is NAMED in the conversation**. "Named" means you can point at it: a file path,
a pasted image, a command whose current output is recorded, or a written waiver.

Procedure:

1. Classify the change using the table below.
2. Create or locate the target artifact. Run/record it so its pre-change state is in the conversation (failing test output, baseline screenshot, current config value).
3. State the target in one line: `TARGET: <artifact> — done when <pass condition>`.
4. Only then implement. After implementing, check against the named target — not against "looks done".

If you notice you have started implementing without a named target: stop, name one,
then resume.

## Target taxonomy by change type

| Change type | Required target | Named as |
|---|---|---|
| Logic change (new behavior, bug fix) | A failing test that passes only when the change is correct | Test file/case + the failure output, confirmed failing before implementation |
| Data / transform change (parsers, migrations, formatters) | A golden input/output pair | Input fixture + expected output, both written down before the change |
| UI change | A screenshot or mock image to match | Image path or pasted image; done when a fresh screenshot matches it |
| Refactor (behavior preserved) | The existing suite, green before AND after — the suite IS the target | The suite command + its green output captured before touching code |
| Config / infra change | An observable expected state, written before the change | One line: the command to observe it + the expected value after the change |

A target must produce a signal Claude can read in the conversation (exit code, diff,
test output, screenshot). "I'll be careful" and "the user will check" are not targets.

## Waiver path

Some changes have no feasible target (e.g., a comment fix, an exploratory spike, an
environment you cannot observe). Then the waiver is itself the named artifact. It must
be explicit, in this form, before implementation:

```
WAIVER: no target available because <X>.
Will check instead: <what will be inspected and how>.
```

A waiver without both lines does not satisfy the gate. If you find yourself writing
waivers for logic changes, that is a smell — a failing test was almost certainly
feasible.

## Provenance

- **Idea:** Cherny: Claude performs best when given a concrete target to iterate against, established before the implementation exists — tests written from expected input/output pairs and confirmed failing before any implementation code ("Write tests, commit; code, iterate, commit"), or a visual mock to match via screenshots ("Write code, screenshot result, iterate": "you can provide Claude with visual targets... iterate until its result matches the mock").
- **Where stated:** "Claude Code: Best practices for agentic coding", Anthropic engineering blog, April 2025 (originally anthropic.com/engineering/claude-code-best-practices, since folded into the Claude Code docs as "Give Claude a way to verify its work"). Boris Cherny, Claude Code's creator, authored and announced the guide ("Just published our 'Claude Code: Best practices for agentic coding' guide", Threads, April 2025); it was compiled with the Claude Code team. Verified against an archived copy of the original post, "Try common workflows" subsections b ("Write tests, commit; code, iterate, commit") and c ("Write code, screenshot result, iterate").
- **How this tool operationalizes it:** It converts the post's advisory workflows into a pre-implementation gate: every change type maps to a required target artifact that must be named in the conversation before implementation starts, with an explicit written waiver as the only escape hatch.
