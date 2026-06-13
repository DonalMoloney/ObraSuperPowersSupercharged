---
name: eval-driven-dev
description: Use when building, changing, or hardening an LLM-powered feature (prompt, chain, agent, RAG, classifier) and ordinary unit tests can't capture "is the output good" — sets up a small eval suite that drives iteration with numbers instead of vibes. For deterministic code, use test-driven-development instead.
tier: v2
supports: [test-driven-development, verification-before-completion]
---

# eval-driven-dev

The LLM-feature analog of `test-driven-development`. Evals are to a prompt/chain/agent what a RED test is to deterministic code: a runnable check that fails before the change is good and passes after, so you catch regressions and *prove* improvements.

This skill does not restate v1 `test-driven-development` — it borrows its RED→GREEN discipline and applies it where outputs are non-deterministic and "correct" is a distribution, not an equality. When the feature has **no LLM in the loop**, stop and use `test-driven-development` directly.

## Supports

- **`test-driven-development`** — same write-the-failing-check-first loop; evals are the failing check when the unit under test is a model call.
- **`verification-before-completion`** — a passing eval run (with per-tag numbers and the diff vs. the prior run) is the *evidence* that the LLM change is done. Never claim an LLM feature "works" on vibes; show the pass rate.

## When to invoke

Trigger on: "set up evals", "build an eval harness", "evaluation-driven development", "how do I measure this prompt", "I keep changing the prompt and breaking things", or any change to an LLM feature you can't gate with a normal assertion.

## Process

### 1. Pin down what "good" means (the rubric is the spec)
Before writing any eval, get one paragraph: what the feature does in user terms, one **clearly good** output, one **clearly bad** output, and the **most common failure mode** today. If the user can't answer these, do that first — evals on an undefined target are noise.

### 2. Pick the cheapest metric that catches the failures that matter
In order of preference:
1. **Exact match / regex / schema** — structured output (JSON shape, required key, refusal phrase). Deterministic, free, never wrong.
2. **Heuristic** — length, embedding cosine, ROUGE. Cheap, noisy.
3. **LLM-as-judge** — a separate rubric-scoring prompt. Use *only* where structure can't capture quality (tone, faithfulness, helpfulness). Costly and judge-sensitive.
4. **Human review** — only for rows the cheaper metrics already flag.

Never use LLM-as-judge for something a `JSON.parse` decides.

### 3. Seed dataset: 10–30 rows, not 1,000
Cover happy path, common edge cases, each known failure mode, and one adversarial input. Each row: `input`, `expected` (or rubric), `tags` (to slice). Store as version-controlled JSONL beside the feature.

### 4. Wire a minimum harness
A script that reads the JSONL, calls the feature, applies the metrics, writes results; a summary printing overall + **per-tag** pass rate; a **diff mode** vs. the previous run. Keep the seed run under ~2 minutes or iteration stalls.

### 5. Run the RED→GREEN loop
1. Change prompt / model / chain.
2. Run evals.
3. If any tag's pass rate **dropped**, inspect those rows before accepting.
4. If it **rose**, commit prompt + dataset together so a reviewer can re-run.

### 6. Grow the dataset like regression tests
When a real user hits a bug: add the input as a row with the desired output → confirm it **fails** → fix → confirm it **passes** and nothing else regressed. (This is exactly v1 `test-driven-development`'s regression-test reflex, applied to the model.)

## Deliverables

1. A short markdown plan tailored to the feature.
2. `evals/dataset.jsonl` seeded with 10–20 tagged rows.
3. A runnable `evals/run.{py,ts}` printing per-tag pass rates + diff vs. last run.
4. A "how to add a case" paragraph for future contributors.

## Verification

PROVEN BY: a committed `evals/` directory whose harness runs in under ~2 minutes, prints per-tag pass rates, and shows a diff against the previous run — and a worked RED→GREEN instance (one row that failed before a change and passes after, with no other tag regressing). Hand that run to `verification-before-completion` as the done-evidence for the LLM change.
