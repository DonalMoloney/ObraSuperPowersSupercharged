---
name: autonomy-slider
description: Use at the start of any task, and again at any mid-task surprise — declare how much autonomy the work gets before a human verifies it, and downgrade the level out loud when a trigger fires
tier: v4
inspiration: "Karpathy — autonomy slider / partial autonomy (Software Is Changing (Again), YC AI Startup School keynote, June 2025)"
---

# Autonomy Slider

**Not this skill if:** you need plan-structure checkpoints (per-phase review gates inside a written plan) → v1 `executing-plans` owns that; you need diff-size discipline *within* a level — that is K2 short-leash-increments territory (deferred idea, not yet built — no current skill; keep diffs small ad hoc).

Autonomy is a dial, not a default. Pick the level deliberately, say it, and let evidence move it — only ever downward mid-task.

## The four levels

| Level | Name | What Claude may do | When the human verifies |
|-------|------|--------------------|-------------------------|
| **L0** | Suggest-only | Propose changes as text/diff blocks in conversation. Never edit a file. | Before anything touches disk — the human applies (or rejects) each suggestion. |
| **L1** | Single-file diffs | Edit one file at a time; present each file's diff and stop. | After every file, before the next edit starts. |
| **L2** | Checkpointed multi-file | Edit multiple files, but pause after each logical unit (one function + its test, one renamed concept, one config + consumer) with a short summary and the verifier result. | At each checkpoint. |
| **L3** | Full task | Complete the whole task — edits, tests, fixes — without pausing. | Once, at the end, against the named verification target. |

## Selecting the level at task start

Score each row; the lowest row's answer wins (any single high-risk answer caps the level).

| Criterion | Question | Pushes toward |
|-----------|----------|---------------|
| Stakes | Prod-facing? Data-destructive (deletes, migrations, irreversible writes)? | L0–L1 if yes; L3 only if no |
| Reversibility | Is the worktree git-clean so everything is one `git checkout` away? Does the change include a migration or external side effect? | Dirty tree or migration → drop one level |
| Test coverage | Does the touched area have tests that would catch a plausible mistake? | Good coverage → L2–L3; none → L0–L1 |
| Recent wrongness | Was Claude corrected in this area earlier this session? | Any correction here → at most L1 in that area |

**Declaration rule:** state the chosen level in one line at task start, before the first edit. Example: `Autonomy: L2 — multi-file with checkpoints (covered by tests, git-clean, not prod-facing).` If the user sets a level explicitly, theirs wins.

## Downgrade triggers (mid-task)

Any one of these fires → drop exactly one level immediately and say so out loud (e.g. `Downgrading L3 → L2: test_parser failed unexpectedly.`):

- A surprise test failure — a test failed that the current change was not expected to touch.
- An edit lands outside the predicted file set declared or implied at task start.
- The user corrects Claude on anything in this task.
- The work enters an unfamiliar subsystem not examined before this task.

Triggers stack: two triggers means two levels down. Never upgrade mid-task; finishing at the lower level and re-declaring on the *next* task is the only way back up.

## Provenance

- **Idea:** Karpathy argues the best AI products are partial-autonomy products with an "autonomy slider" — the user tunes how much autonomy to grant per task (his examples: Cursor's tab-completion → Cmd-K → Cmd-L → Cmd-I progression, Perplexity's quick search → research modes, Tesla Autopilot) — and that workflows must keep the AI "on a leash" with fast human verification loops.
- **Where stated:** "Software Is Changing (Again)", keynote at Y Combinator's AI Startup School, San Francisco, June 2025 (recording on YC's channel; verified via web search, June 2026).
- **How this tool operationalizes it:** It turns the slider from a product feature into a working agreement — four concrete autonomy levels (L0 suggest-only through L3 full-task), risk-based selection criteria, a one-line declaration at task start, and evidence-driven downgrade triggers that shorten the leash the moment the agent is surprised or corrected.
