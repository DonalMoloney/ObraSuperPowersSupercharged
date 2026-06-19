---
name: jagged-intelligence-guard
description: Use when a task enters a known-spiky domain for LLMs — exact arithmetic, counting/tallying, character-level or spatial reasoning, a fresh or unseen API, or precise dates — to force a tool call or a verify step instead of trusting the model's first output
tier: v4
inspiration: "Karpathy — jagged intelligence (state-of-the-art LLMs solve hard problems yet fail simple adjacent ones; treat current LLMs as tools, like text calculators), X posts July 25, 2024 and January 23, 2025"
---

# Jagged Intelligence Guard

**Not this skill if:** you want the full deficit→prosthetic MAP (amnesia, hallucination, context limits, *and* jaggedness) → **v4 cognitive-prosthetics** owns that map. This skill is the *territory* for its one jaggedness row: the runtime detector plus the forced action. Cognitive-prosthetics' jaggedness row points here; do not restate the map.

Capability is spiky, not smooth. The model can be superhuman one line and confidently wrong the next, in an adjacent, simpler-looking spot. The danger is that the spike feels identical from the inside — fluent, certain — whether it is right or wrong. So jaggedness is not handled by trying harder; it is handled by *refusing to trust the first output in a spiky domain* and routing through a tool or a check instead. In Karpathy's framing, treat the LLM here as a text calculator: do the calculator part with a calculator.

## The pattern

### Step 1 — Detect: is this a jagged domain?

Scan the current task against the spiky-domain table. If **any** row matches, the model's first-pass answer is untrusted by default — proceed to Step 2. One match is enough to fire.

| Spiky domain | What makes it jagged | Detection trigger |
|--------------|----------------------|-------------------|
| **Exact arithmetic** | Token-level prediction approximates math; multi-digit ops, percentages, and unit conversions drift silently. | Any computed number that must be exact (totals, diffs, rates, conversions, money). |
| **Counting / tallying** | No internal counter; the model estimates cardinality instead of enumerating. | "How many X", off-by-one-sensitive loops, list lengths, occurrence counts. |
| **Character-level / spatial reasoning** | Trained on tokens, not characters or 2-D layout; reversals, substrings, and grids are guesswork. | Reversing/sorting characters, "letters in word", ASCII layout, column/row alignment, coordinate geometry. |
| **Fresh / unseen API** | Post-cutoff or niche signatures aren't memorized; the model interpolates a plausible-looking API that may not exist. | A library/CLI/SDK call whose exact signature, flag, or option isn't already visible in context. |
| **Precise dates** | Day-of-week, durations, "N days from", and timezone math are reconstructed, not computed. | Any date arithmetic, weekday lookup, age/duration, or "today"-relative claim. |

### Step 2 — Forced action ladder

Do not answer from the spike. Take the **highest rung that applies**, top-down — never skip to "just trust it":

1. **Use a tool.** Route the spiky part to a deterministic executor: run the arithmetic/count/date in `python3 -c`, `date`, or a real script; let the calculator be the calculator. Prefer this for arithmetic, counting, character/spatial, and dates.
2. **Write a check.** If no one-shot tool fits, write a tiny verifier and run it: a script that recomputes the value, a test that asserts the count, a `diff` against a known-good. The answer is whatever the check returns, not what you predicted.
3. **Cite-or-verify.** For a fresh/unseen API, do not state the signature from memory — open `--help`, read the actual source/docs, or run a probe call, and quote what you saw. (This is the cite-or-check rule from cognitive-prosthetics' hallucination row, applied to the jaggedness trigger; see **v4 cognitive-prosthetics**.)

State which rung you took in one line before giving the result, e.g. `Jagged domain (exact arithmetic) → ran python3, not estimated: total = 4187.` If you genuinely cannot reach a rung (no executor, no docs, no probe), say the number is unverified rather than presenting a spike as fact.

## Provenance

- **Idea:** Karpathy's "jagged intelligence" — the strange, unintuitive fact that state-of-the-art LLMs can perform extremely impressive tasks (e.g. solve complex math problems) while simultaneously failing some very dumb, adjacent ones; competence is spiky and does not transfer smoothly. His prescription is to treat current-capability LLMs as tools — "a bit more like text calculators" — i.e. push the verifiable part through a deterministic tool rather than trusting the generation.
- **Where stated:** Andrej Karpathy on X — original coinage July 25, 2024 (x.com/karpathy/status/1816531576228053133, "Jagged Intelligence — the word I came up with to describe the (strange, unintuitive) fact that state of the art LLMs can both perform extremely impressive tasks while simultaneously struggle with some very dumb problems"), reaffirmed January 23, 2025 (x.com/karpathy/status/1882518317585650064, "Yep I call it Jagged Intelligence... favor thinking about current capability LLMs as tools, a bit more like text calculators"); verified via web search, June 2026.
- **How this tool operationalizes it:** It converts the observation into a runtime guard — a detection table that flags the five domains where the spike is most likely to be wrong, and a forced-action ladder (use a tool / write a check / cite-or-verify) that routes the spiky part through a deterministic executor or an explicit verification instead of the model's first output. It is the standalone territory for the single jaggedness row in v4 cognitive-prosthetics' deficit map, not a re-listing of that map.
