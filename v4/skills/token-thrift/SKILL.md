---
name: token-thrift
description: Use during active work whenever a Bash, Grep, or Read call is about to dump a large result into context — trim the output at the source, scope the read to the range that answers the question, or offload heavy exploration to a subagent so the main thread pays for the conclusion, not the raw bytes
tier: v4
inspiration: "Cherny — CLI tools are 'the most context-efficient way' to work + 'use subagents ... tends to preserve context availability' (Best practices for Claude Code, Anthropic engineering blog, April 2025). Karpathy — context-window-as-RAM, accuracy degrades with fill (Software Is Changing (Again), YC AI Startup School keynote, June 2025) — cited as the why."
---

# Token Thrift

**Not this skill if:**

- You are choosing *what standing knowledge to load in* at task start (CLAUDE.md sections, ADRs, conventions) → **v4 selective-priming**. That governs the *briefing*; this governs the *byte cost of each tool call during the work*.
- You are deciding *when to `/clear` or `/compact`* a session that has already bloated → **v4 context-rot-monitor**. That pages out context already in the window; this stops the wasteful bytes from entering in the first place.
- You are *compressing a context you have decided to keep* after the fact → **v5 salience-compressor** owns lossy compression.
- You are *externalizing working state to files* to survive a long task → **v4 cognitive-prosthetics** (context-window-limits row).
- You are running the *budgeting / page-table accounting* discipline — declaring the question each read answers and tracking what is already paged in → that is **K3 `context-paging`** (deferred idea, not yet built). This skill owns the **tactical read mechanics** (locate, then range-read); K3 owns the **strategic accounting**. Keep the page-table discipline ad hoc for now.

The cheapest token is the one you never bring into the window. Every tool result you generate — a full `cat`, a whole-file `Read`, an unfiltered test log — is a page you then pay attention tax on for the rest of the session. Frontier accuracy degrades continuously as the window fills, so a 600-line dump you needed three lines of is not free: it is noise crowding the next step *and* money. Token thrift is three moves — two you make **at the point of the call**, before the bytes land, and one you make **at the point of the task**, before a broad sweep floods the window.

## The three moves

### 1. Trim the output before it lands

Shape the command so it emits only what answers the question. The result never enters context bloated.

| Instead of (heavy) | Do (thrifty) | Why |
|--------------------|--------------|-----|
| `cat file.ts` to find one thing | `rg -n 'symbol' file.ts` | Lands the matching lines + numbers, not the file. |
| `git diff` (full) | `git diff --stat`, then diff the one path that matters | See the shape first; pull detail on demand. |
| `npm test` / full build log | append `2>&1 \| tail -n 40`, use `--silent`/`--reporter=dot`, or `> /tmp/out 2>&1` then `rg -n 'FAIL\|Error' /tmp/out` | A passing run needs a tail; a failing run needs the failures, not the scrollback. |
| `ls -R` / deep tree | `git ls-files \| rg 'area'` or `rg --files \| head` | Tracked, filtered, bounded. |
| Raw API/JSON blob | `jq -c '.field'` / `jq '.[].name'` | Project the fields you need; drop the envelope. |
| Verbose installers/tools | `-q` / `--quiet` / `--no-progress` | Progress spinners are pure noise in a transcript. |

Rule of thumb: **pipe through `head`/`tail`/`rg`/`jq`/`--stat` rather than reading the firehose and discarding mentally.** Discarding mentally still cost you the tokens.

### 2. Scope the read — locate, then range

When you must read a file, do not load the whole thing if a slice answers the question.

1. **Locate** with `Grep`/`Glob` (or `git grep -n`) to get the file and line number.
2. **Range-read** with `Read` using `offset` + `limit` around that line — the function, the block, the section. Not the 2,000-line module.

Read the whole file only when you genuinely need the whole file (a small file, a top-to-bottom review). Default to the slice; widen on demand. *(Mechanics only — the "declare the question each read answers / track a page table" budgeting belongs to K3 `context-paging`, deferred.)*

### 3. Offload heavy exploration to a subagent

When answering a question means sweeping *many* files — "where is X wired up", "what calls this", "which of these 30 skills mention Y" — do not read them all into the main thread. Dispatch a subagent (the read-only `Explore` agent, or `general-purpose`) to do the sweep and **return only the conclusion**. The subagent's context absorbs the file dumps; your main thread keeps the one-paragraph answer.

- Best **early in a task** (Cherny), when a broad survey would otherwise flood the window you need clean for the actual work.
- Ask for the *conclusion and the `file:line` pointers*, not the file contents — you can range-read the few that matter (move 2) afterward.
- When the subagent is a reviewer, also strip its prompt to diff + requirements → **v4 fresh-context-review**. (Token-thrift says *delegate the dump*; fresh-context-review says *delegate it uncontaminated*. They stack.)

## The test (apply at every tool call)

> **Will most of this result's tokens still be earning their attention tax three turns from now?** If no — trim it (1), scope it (2), or send it to a subagent (3) before it lands.

## Verification

This skill claims a *measurable* footprint reduction, so show it — do not just assert thrift.

- **Move 1:** name the heavy command you would have run and the thrifty one you ran, with the line counts. Evidence reads like: `Avoided cat src/app.ts (1,842 lines); ran rg -n 'createServer' src/app.ts → 3 lines.`
- **Move 2:** confirm the read was ranged, not whole-file — e.g. `Read app.ts offset 410 limit 60 (located via git grep -n), not the full 1,842 lines.`
- **Move 3:** confirm the subagent returned a conclusion + pointers, and that the file dumps stayed in *its* context — e.g. `Explore swept 31 SKILL.md files, returned 1 paragraph + 4 file:line hits; no skill bodies entered the main thread.`

If you cannot point to a concrete before/after like the above, you invoked the skill's name but not its discipline.

## Provenance

- **Idea (Cherny):** Two specific recommendations from the best-practices post. First, on tooling: CLI tools are *"the most context-efficient way to interact with external services"* — the post's whole stance is to shape what enters context, not to dump and sort later. Second, on delegation: *use subagents to verify details or investigate particular questions, especially early in a conversation or task — this "tends to preserve context availability without much downside in terms of lost efficiency."* Move 3 is that line made into a habit. **Idea (Karpathy, the why):** the context window is the model's RAM, and accuracy degrades continuously as it fills — so unneeded bytes are not free, they are a tax on every subsequent step. That is the reason trimming at the source beats reading-then-ignoring.
- **Where stated:** Cherny — "Best practices for Claude Code" (a.k.a. "Claude Code: Best practices for agentic coding"), Anthropic engineering blog, April 2025; the "Use CLI tools" and subagent guidance (verified via web fetch of the redirected docs, June 2026). Karpathy — "Software Is Changing (Again)", YC AI Startup School keynote, June 2025, and the LLM-as-OS framing (context window = RAM); the continuous accuracy-vs-fill degradation is the standard long-context finding the RAM analogy encodes (verified via web search, June 2026).
- **How this tool operationalizes it:** It turns "be context-efficient at the source" into three moves applied *at the point of the tool call* — (1) a swap table that shapes Bash output (`rg`/`head`/`--stat`/`jq`/`-q`) so only the answer lands, (2) a locate-then-range read protocol (`Grep`/`git grep -n` → `Read offset+limit`) that never loads a whole file for a slice, and (3) a subagent-offload habit that pushes broad file-sweeps into a disposable context and pulls back only the conclusion + `file:line` pointers. The boundary is deliberately narrow: token-thrift takes the *tactical read mechanics* that K3 `context-paging` had listed, leaving K3 its *strategic accounting* lane (question-per-read, page table), so the two do not duplicate.
