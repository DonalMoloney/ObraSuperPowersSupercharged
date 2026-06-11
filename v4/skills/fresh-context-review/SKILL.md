---
name: fresh-context-review
description: Use when dispatching any reviewer subagent — strips the dispatch prompt down to the diff and the original requirements so the reviewer's context stays uncontaminated by the writer's assumptions
tier: v4
inspiration: "Cherny — multi-Claude review with fresh context (Claude Code: Best practices for agentic coding, Anthropic engineering blog, April 2025)"
---

# Fresh-Context Review

**Not this skill if:** you want multiple review PERSPECTIVES run in parallel → v2 `reviewer-lenses` (composable, not a rival: each lens reviewer should ALSO be dispatched fresh-context per this skill); you are processing review feedback you received → v1 `receiving-code-review`.

## The rule

A reviewer subagent receives **exactly two inputs**:

1. **The diff** — the actual change, obtained mechanically (`git diff`), not narrated.
2. **The original requirements** — the spec or task statement as the USER stated it, before the writer interpreted it.

Nothing else. If you are about to paste anything beyond these two things into the reviewer's prompt, stop and check the contamination list.

## Contamination checklist — what must NOT be passed, and why

| Forbidden input | Bias it causes |
|---|---|
| The writer's conversation (or a summary of it) | Anchors the reviewer on the writer's framing — it inherits the same blind spots that produced the bug |
| The writer's plan | Reviewer checks plan-conformance instead of correctness; a faithful implementation of a wrong plan passes |
| The writer's self-assessment ("tests pass", "this handles all edge cases") | Success claims suppress scrutiny — the reviewer rubber-stamps instead of re-deriving the verdict |
| The writer's commit messages beyond the diff | Narrative smoothing — the message tells the reviewer what to see in the code before it reads the code |

Litmus test: could the reviewer's prompt have been written by someone who never saw the implementation happen? If not, it is contaminated.

## Dispatch template

```text
Dispatch a subagent (fresh context, no prior conversation) with exactly this:

---
You are reviewing a code change. You have two inputs and nothing else.

INPUT 1 — original requirements (verbatim, as the user stated them):
<paste the user's task statement / spec — NOT the writer's restatement>

INPUT 2 — the diff:
<output of `git diff <base>...<head>` — the raw diff, no commentary>

Review the diff against the requirements. Report:
- Correctness: does the change do what the requirements ask? Cite lines.
- Defects: bugs, missed edge cases, broken invariants. Cite lines.
- Scope: anything changed that the requirements did not call for.

Do not assume tests were run. Do not assume the approach was agreed.
Judge only what you can see in the two inputs.
---
```

If the requirements only exist inside the writer's conversation (no spec file, no issue), extract the user's original wording verbatim — resist summarizing it, because your summary is the writer's framing.

## Composing with other review skills

- v2 `reviewer-lenses`: dispatch each lens as its own fresh-context reviewer using the template above, adding only the lens instruction. Lenses change WHAT each reviewer looks for; this skill governs WHAT EACH ONE IS ALLOWED TO SEE.
- After reviews come back, switch to v1 `receiving-code-review` to process the findings — that skill owns the response side.

## Provenance

- **Idea:** One Claude writes code; a separate Claude with fresh context reviews it. "A fresh context improves code review since Claude won't be biased toward code it just wrote" — and the reviewer should see "only the diff and the criteria you give it, not the reasoning that produced the change."
- **Where stated:** Boris Cherny, "Claude Code: Best practices for agentic coding," Anthropic engineering blog, April 2025. Web-verified 2026-06-10: the original URL (`anthropic.com/engineering/claude-code-best-practices`) returns an HTTP 308 permanent redirect to the maintained version at `code.claude.com/docs/en/best-practices`, which retains the Writer/Reviewer multi-session pattern ("A fresh context improves code review since Claude won't be biased toward code it just wrote") and the fresh-subagent adversarial review step quoted above, both verbatim; Cherny's authorship of the original post is confirmed by multiple secondary sources.
- **How this tool operationalizes it:** It turns "fresh context" from a vibe into an enforceable input contract — exactly two allowed inputs (diff + original requirements), a named-bias checklist for everything else, and a dispatch template that makes the uncontaminated prompt the default path.
