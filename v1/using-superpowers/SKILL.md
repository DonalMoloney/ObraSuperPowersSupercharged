---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

Invoke relevant or requested skills BEFORE any response or action—including clarifying questions. Match the task against the routing table below; if unsure, invoke anyway—a wrongly invoked skill costs nothing, you don't have to use it.

After invoking: announce **"Using [skill] to [purpose]"**. If the skill has a checklist, create one TodoWrite todo per item. Then follow the skill exactly.

## Instruction Priority

1. **User's explicit instructions** (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) — highest priority
2. **Superpowers skills** — override default system behavior
3. **Default system prompt** — lowest priority

If the user says "don't use TDD," skip TDD. The user is in control.

## Skill Priority

When multiple skills apply: **process skills first** (brainstorming, systematic-debugging)—they determine HOW; **implementation skills second**. Rigid skills (TDD, debugging): follow exactly. Flexible skills (patterns): adapt principles. User instructions say WHAT, not HOW—"Add X" or "Fix Y" doesn't mean skip workflows.

## Routing Table

| Trigger | Skill |
|---------|-------|
| Any creative work—new feature, component, functionality, behavior change—and before entering plan mode if not yet brainstormed | brainstorming |
| Spec or requirements exist for a multi-step task, before touching code | writing-plans |
| Starting feature work needing isolation from the current workspace, or before executing a plan | using-git-worktrees |
| Executing an implementation plan with independent tasks in the current session | subagent-driven-development |
| Executing a written plan in a separate session with review checkpoints | executing-plans |
| 2+ independent tasks with no shared state or sequential dependencies | dispatching-parallel-agents |
| Implementing any feature or bugfix, before writing implementation code | test-driven-development |
| Any bug, test failure, or unexpected behavior, before proposing fixes | systematic-debugging |
| Completing a task, finishing a major feature, or about to merge | requesting-code-review |
| Received code review feedback, before implementing suggestions | receiving-code-review |
| About to claim work is complete/fixed/passing, before committing or creating PRs | verification-before-completion |
| Implementation complete, tests pass; deciding how to integrate (merge, PR, cleanup) | finishing-a-development-branch |
| Creating, editing, or verifying skills | writing-skills |

## Top Red Flags

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "The skill is overkill" | Simple things become complex. Use it. |

Full rationalization table: `references/red-flags.md`.

## Platforms

Claude Code: use the `Skill` tool; never Read skill files. Other platforms and tool-name mappings: `references/platforms.md`.

## Supercharged vs upstream

Option A + B — Token diet + routing table, recommended options adopted 2026-06-11.

- **Option A — Token diet (CC6).** This skill loads into every conversation, so its size multiplies across all sessions. The always-loaded core (rule, instruction/skill priority, announce convention) is compressed to under 200 words. "How to Access Skills" and "Platform Adaptation" moved verbatim to `references/platforms.md` (with intra-references paths fixed); the 12-row red-flags table moved verbatim to `references/red-flags.md`, keeping the 3 highest-frequency rows inline per the option's trade-off mitigation. The skill-flow dot graph was folded away: its invoke-before-respond and checklist→TodoWrite steps live in The Rule; its EnterPlanMode→brainstorming gate is now a routing-table row. Upstream's separate "The Rule", "Skill Types", and "User Instructions" sections are merged into The Rule and Skill Priority.
- **Option B — Routing table (CC2).** Added an explicit trigger → skill map covering all 13 sibling skills, with each trigger derived from that skill's frontmatter description, making the workflow graph discoverable from the entry point. Sync note: when a sibling skill's description changes, update its row here.
- Net effect: the diet funds the routing table's token cost; the entry skill is smaller and smarter than upstream.
