---
name: selective-priming
description: Use at the start of a task before loading any standing knowledge (CLAUDE.md sections, conventions docs, architecture notes, past-decision logs) — compute which files the task will touch, then prime the context window with ONLY the knowledge attached to those files instead of dumping the whole knowledge base
tier: v4
inspiration: "Karpathy — context engineering / context-window-as-RAM: 'filling the context window with just the right information for the next step' (Andrej Karpathy on X, June 25, 2025, x.com/karpathy/status/1937902205765607626)"
---

# Selective Priming

**Not this skill if:**

- You are matching a situation to a known LLM cognitive deficit and applying a standing compensation (amnesia → write notes, jagged intelligence → re-verify basics) → **v4 cognitive-prosthetics**. That skill answers "which weakness is in play"; this skill answers "which knowledge to load." Prosthetics' context-window-limits row says *externalize* working state to files; this skill says *what to read back in* from those files at task start.
- You are deciding whether to acquire a new tool/integration vs. compose existing CLIs → **v4 bash-first-tooling**. That ladder is about capability acquisition; this is about knowledge loading. (They do rhyme — both refuse to pay context cost you don't need — but the trigger and the artifact are different.)

The context window is RAM, not disk. Before a task, do not page in the whole knowledge base "just in case." Compute the task's file footprint, then load only the knowledge that is *about those files*. Everything else stays on disk where it costs nothing.

## The procedure

Run these four steps at task start, before the first edit and before reading any standing docs end-to-end.

### 1. Compute the affected-file set

Name the files the task will plausibly touch. Use cheap, deterministic probes — not a guess:

```bash
# Files matching the feature/area named in the task
git ls-files | grep -i 'checkout\|payment'           # by path keyword
git grep -l 'parseInvoice'                            # by symbol the task names
git log --name-only -n 5 --pretty=format: | sort -u   # what recent work touched
git diff --name-only                                  # what is already dirty
```

Write the set down in one line: `Affected files: src/checkout/*, src/payment/stripe.ts`. If the set is genuinely unknowable yet (exploratory task), say so and prime broadly *once*, then narrow as soon as the footprint is known — re-run this procedure when it firms up.

### 2. Find the knowledge attached to those files

For each affected path, pull only the knowledge that references it. The knowledge base is whatever your repo already has — CLAUDE.md, a `docs/` tree, `ADR-*.md`, a JSONL decision/pattern log, conventions files. Grep it *by the affected paths and their key symbols*, not by topic:

```bash
# Which knowledge entries mention the files we are about to touch?
grep -rniE 'checkout|payment|stripe\.ts|parseInvoice' \
  CLAUDE.md docs/ ADR/ .claude/knowledge.jsonl 2>/dev/null
```

Read in full only the sections that hit. A 4,000-line architecture doc with three relevant paragraphs costs you three paragraphs, not 4,000 lines.

### 3. Prime the window with the hits, name what you skipped

State, in one line, what you loaded and what you deliberately left on disk:

> Primed: payment ADR-014, the `stripe.ts` conventions block in CLAUDE.md, two past-decision entries tagged `checkout`. Skipped: the rest of the architecture doc, all frontend/auth knowledge — not in this task's footprint.

Naming the skip is the discipline. It makes "I didn't load that" a deliberate choice you can be corrected on, not an accident.

### 4. Re-prime on footprint change, not on impulse

If the task expands to a new area mid-flight (an edit lands in a file outside the declared set, or you discover a new dependency), that is a footprint change: re-run steps 1–3 for the *new* paths and load their knowledge then. Do not pre-load it now against a maybe. Load-on-demand, keyed to actual files touched, is the whole point.

## Why this beats "load everything"

- **Accuracy degrades with fill, not just at the limit.** Frontier models lose accuracy continuously as the window fills — a slope from token one, not a cliff at max tokens. Unrelated knowledge is not free; it is noise that crowds the signal for the next step.
- **The relevant slice is small.** Most standing knowledge is about parts of the system this task will never touch. Footprint-keyed loading turns a whole-repo knowledge base into a per-task briefing without rewriting the knowledge base.
- **It is deterministic and cheap.** `git grep` / `grep -l` over real paths is rung-1 bash (see bash-first-tooling) — no index to build, no embedding store to query, nothing to install.

## Provenance

- **Idea (Karpathy):** The context window is the LLM's RAM — a scarce, curated resource, not a dumping ground. Karpathy named the discipline of managing it "context engineering": "the delicate art and science of filling the context window with just the right information for the next step." The corollary in his LLM-as-OS framing (CPU = the model, RAM = the context window, disk = retrieval/knowledge stores) is that knowledge sits on disk by default and you pay an explicit load to bring only the needed slice into RAM.
- **Where stated:** Andrej Karpathy on X, June 25, 2025 — x.com/karpathy/status/1937902205765607626 ("+1 for 'context engineering' over 'prompt engineering' ... context engineering is the delicate art and science of filling the context window with just the right information for the next step"), endorsing Tobi Lütke's framing from June 18, 2025. The RAM/CPU/OS analogy is from Karpathy's "Software Is Changing (Again)" / Software 3.0 talk (Sequoia AI event and YC AI Startup School, 2025). Both verified via web search, June 2026.
- **How this tool operationalizes it:** It turns "fill the window with just the right information" into a four-step task-start procedure that computes the *right information* mechanically: derive the affected-file set with `git grep`/`git ls-files`, pull only the knowledge that references those exact paths and symbols, prime the window with those hits while naming what was deliberately skipped, and re-prime on footprint change rather than pre-loading against a maybe. The selection rule is adapted from metaswarm's external `bd prime` (load knowledge by affected files), but the mechanism here is plain bash file-affinity over whatever knowledge base the repo already keeps — no external tool required.
