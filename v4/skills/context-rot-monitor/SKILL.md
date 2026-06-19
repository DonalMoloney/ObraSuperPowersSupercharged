---
name: context-rot-monitor
description: Use during any long-running session — watch for context-pressure signals (length, staleness, dead context, rising confusion) and call a deliberate /compact or /clear at task boundaries before bloated context degrades output
tier: v4
inspiration: "Karpathy — LLM-as-OS / context window is RAM, paged deliberately (Software Is Changing (Again), YC AI Startup School keynote, June 2025) + Cherny — /clear between tasks (Best practices for Claude Code, Anthropic engineering blog, April 2025)"
---

# Context Rot Monitor

**Not this skill if:** you are budgeting *reads before you explore* → that is K3 `context-paging` (deferred idea, not yet built — keep read budgets ad hoc for now); you want to *compress* a kept context after the fact → v5 `salience-compressor` owns lossy compression; you are choosing *what to load in* at the start → v4 `selective-priming` owns priming. This skill governs one thing only: **when to clear or compact the running session.**

Context is RAM, not an archive. A session accumulates dead pages — finished subgoals, abandoned approaches, stale file contents you have since edited — and the model keeps paying attention tax on all of it. "Context rot" is the slow quality decay that follows: the agent re-reads files it already read, re-litigates settled decisions, and contradicts itself. The fix is not a bigger window; it is paging deliberately at the right boundary.

## Pressure signals (the rot ladder)

Watch for these. They stack — the more lit at once, the higher the pressure.

| Signal | What it looks like | Why it rots output |
|--------|--------------------|--------------------|
| **Length** | Conversation is long relative to the task — many turns, large pasted files, full test logs left in scrollback. | Attention spreads thin; early instructions get diluted by later noise. |
| **Staleness** | File contents in context no longer match disk (you have edited them since reading). | Model reasons against a version that no longer exists. |
| **Dead context** | A finished subgoal, an abandoned approach, or a resolved error still occupies the window. | Pages that can never matter again still cost attention and money. |
| **Re-reading** | Agent re-opens a file or re-runs a command it already saw this session. | Signal that the relevant fact has been pushed out of effective RAM. |
| **Topic switch** | The next task is unrelated to everything above it (new feature, new file tree, new bug). | Old context is now pure interference for the new goal. |
| **Rising confusion** | Contradicting earlier statements, mixing up two files, asking for info already given. | The terminal symptom — rot has already reached the output. |

## Decision table: continue / compact / clear

Read the dominant condition, take the action.

| Condition | Action | Why |
|-----------|--------|-----|
| Mid-task, signals quiet, context still relevant | **Continue** | Paging now would evict pages you are about to use. |
| Subgoal done, more of the *same* task remains; length or dead-context lit but the thread still matters | **`/compact`** | Keep the task's gist, shed the finished detail — page out without pulling the plug. |
| Length high *and* staleness lit *and* you are about to keep going on the same task | **`/compact`, then re-read** the now-stale files fresh | Compaction summarizes; it does not refresh disk state. Reload what changed. |
| Task fully complete, next task is unrelated (topic switch lit) | **`/clear`** | Unrelated context is interference. Start the new task on clean RAM. |
| Rising confusion with no clean boundary in sight | **`/clear`** and restate the goal | Rot has reached output; a summary may preserve the bad pages. Hard reset. |

## How to act on it

1. **Name the boundary out loud.** A clear/compact belongs *between* units of work — after a subgoal completes, before a fresh unrelated task — never mid-edit. Say which one: `Subgoal done; compacting before the next file.`
2. **Compact preserves the thread; clear severs it.** Choose by whether the *next* step needs the *current* thread. Same task → compact. New task → clear.
3. **After compacting, re-read what you have since changed.** Compaction is lossy and frozen at summary time — stale file pages stay stale until reloaded.
4. **Default to acting at the boundary, not at the limit.** Page deliberately when a subgoal closes; do not wait for the window to fill and force an eviction you did not choose.

## Provenance

- **Idea (Karpathy):** The LLM is the new operating system — the model is the CPU, model weights are ROM, and the context window is RAM: finite, volatile, and the only thing the model can actually "see" right now. Everything else (history, files, prior approaches) is disk that must be explicitly paged in, and stale or finished pages should be paged out rather than left to consume the limited window. **Idea (Cherny):** Manage the session deliberately — use `/clear` to reset context between tasks (and `/compact` to summarize when continuing) so a long, polluted session does not degrade Claude's performance.
- **Where stated:** Karpathy — "Software Is Changing (Again)", keynote at Y Combinator's AI Startup School, San Francisco, June 2025, building on his earlier "LLM OS" framing (verified via web search, June 2026). Cherny — "Best practices for Claude Code" (a.k.a. "Claude Code: Best practices for agentic coding"), Anthropic engineering blog, April 2025, which recommends clearing context between tasks and compacting long sessions (verified via web search, June 2026).
- **How this tool operationalizes it:** It turns the RAM analogy into a running monitor — a six-rung pressure ladder (length, staleness, dead context, re-reading, topic switch, rising confusion) that detects rot before it reaches output, and a decision table that maps the dominant signal to Karpathy's "page deliberately" stance via Cherny's concrete operations: continue, `/compact` (page out, keep the thread), or `/clear` (pull the plug at a task boundary), with a re-read step because compaction does not refresh stale disk state.
