---
name: salience-compressor
description: Use when context rot is confirmed — selects what to keep by salience (TextRank) and removes near-duplicates (MinHash/LSH), producing a measurable, reproducible compressed handoff with a reported compression ratio.
author: Donal Moloney
track: context
type: process
chains-to: check-remaining-context
---

## Not this skill if
- Context isn't actually tight — measure with `check-remaining-context` first
- A handoff summary is all you need and headroom is fine — write it directly
- The transcript splits into distinct, independent regions and one pass won't recover enough budget — use `parallel-context-recovery` instead. Deciding factor: `salience-compressor` is a single-pass, in-place compressor with a measurable ratio; `parallel-context-recovery` fans summarizers out over disjoint regions and re-injects into a fresh session. (Inside that skill, `salience-compressor` is the natural per-region compressor.)

# salience-compressor — measured context compression

## Purpose

Give `shrink-context` a real method behind its compression ratios: keep the salient, drop the
redundant, and prove the ratio.

## Core rule

> **Rule:** Report the achieved compression ratio with before/after token counts — a claimed ratio
> without numbers is not proof.

## Triggers

**Use when:**
- `check-remaining-context` reports < 30 % headroom remaining
- The user says "compress this session", "trim context", or "we're running out of tokens"
- You are about to start a handoff and the context is too large to re-inject cleanly
- `detect-context-rot` has confirmed rot and `shrink-context` needs a principled method
- `parallel-context-recovery` delegates a single region to you for per-region compression

**Don't use when:**
- Context is fine — headroom above 40 % and no rot detected
- The task requires full fidelity of every prior message (legal transcripts, audit trails)
- N context blocks < 5; write a short manual summary instead — algorithm overhead not justified
- The goal is a clean fresh session handoff of multiple disjoint regions — use `parallel-context-recovery`

## Algorithm

**TextRank / centrality** scores sentences/blocks for extractive keep-selection; **MinHash/LSH**
removes near-duplicate blocks. Tune keep-fraction to the headroom band.

## Steps

### 1. Measure before-state

Run `check-remaining-context` and record the **before token count**. Write it down explicitly — you need this number for the proof block. Do not proceed without a concrete before count; an estimated or eyeballed number invalidates the ratio.

### 2. Segment the context into blocks

Divide the full context into logical units: one block per assistant turn, one per user turn, or one per thematic exchange cluster — whichever granularity gives you 10–200 blocks. Smaller blocks give finer-grained keep/drop decisions but increase MinHash overhead. If the context is a raw transcript, split on turn boundaries. If it is already structured (tasks, code blocks, decisions), split on section headers.

Record total block count before filtering.

### 3. Score blocks with TextRank

Apply TextRank (or pytextrank) to the full block set to produce a centrality score per block. TextRank treats each block as a node and edges as sentence-level similarity; high-centrality blocks are the load-bearing content.

- Set **keep-fraction** based on headroom target:
  - < 10 % headroom: keep top 25 % of blocks
  - 10–20 % headroom: keep top 40 % of blocks
  - 20–30 % headroom: keep top 55 % of blocks
- Always keep blocks that contain: open decisions, active task state, explicit TODO items, error messages referenced in the current task, and the last 3 assistant turns unconditionally (recency anchor).
- Mark dropped blocks as `status: dropped` with their score for the proof log — do not silently discard.

### 4. Drop near-duplicates via MinHash/LSH

Run the kept blocks through MinHash/LSH (datasketch). Set Jaccard similarity threshold at 0.75 — blocks above that threshold are near-duplicates; retain only the highest-scoring copy from each duplicate cluster.

- Do not deduplicate across the recency-anchor blocks (last 3 turns) — near-duplicate recency content is still needed for coherence.
- Log each dropped duplicate pair: `(block_A, block_B, similarity=0.xx)`.

### 5. Assemble the compressed handoff

Reconstruct the kept blocks in their original chronological order. Do not reorder by score — chronological order preserves causal chains.

Add a preamble line: `[Compressed — N of M blocks retained, <ratio>% reduction]`.

Write the reconstructed handoff as the new working context or as an explicit handoff document depending on the use case.

### 6. Measure after-state and compute ratio

Run `check-remaining-context` again (or count tokens directly). Compute:

```
compression_ratio = (before_tokens - after_tokens) / before_tokens * 100
```

A valid compression run achieves at least a **30 % reduction**. If the ratio is below 30 %, you kept too many blocks; tighten the keep-fraction by 10 percentage points and re-run from step 3.

### 7. Emit the proof block

Produce a `PROVEN BY:` block (see Proof section). Chain to `check-remaining-context` to confirm headroom is now acceptable before handing off.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Claiming a ratio without before/after token counts | Always record before-state token count in step 1; ratio without numbers is explicitly forbidden by the Core rule |
| Silently dropping blocks with no log | Mark every dropped block `status: dropped` with its TextRank score; include count in the proof block |
| Reordering kept blocks by salience score | Reconstruct in original chronological order — reordering breaks causal chains and confuses the reader |
| Deduplicating the recency anchor turns | Exempt the last 3 turns from MinHash/LSH — near-duplicate recency content is needed for coherence |
| Skipping measurement because "it looks smaller" | The Core rule is absolute: ratio without before/after numbers is not proof — always run `check-remaining-context` twice |
| Running when headroom is fine | Confirm rot with `check-remaining-context` first; compression on a healthy context wastes time and discards useful content |

## Proof

Chain to `check-remaining-context` after step 6 to confirm the compressed context fits within the target headroom band.

The output must contain:

- Before token count (from step 1)
- After token count (from step 6)
- Achieved compression ratio as a percentage
- Block counts: total blocks | blocks kept | blocks dropped (TextRank) | blocks dropped (MinHash dedup)
- Confirmation that headroom is now above 30 % (from `check-remaining-context` post-compression)

```
PROVEN BY:
  before_tokens: <N>
  after_tokens: <M>
  compression_ratio: <(N-M)/N * 100>%
  blocks_total: <total>
  blocks_kept: <kept>
  blocks_dropped_textrank: <dropped_tr>
  blocks_dropped_dedup: <dropped_dedup>
  headroom_after: <pct>% (confirmed via check-remaining-context)
```

## Adapt from
- **`summanlp/textrank`** (`pip install summa`) or **`DerwenAI/pytextrank`** (extractive) +
  **`ekzhu/datasketch`** (MinHash/LSH). <https://github.com/summanlp/textrank> · <https://github.com/ekzhu/datasketch>
