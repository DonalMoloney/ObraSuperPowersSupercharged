---
name: sample-context-fairly
description: Use when shrink-context is running with headroom below 20% and oldest-first dropping would destroy critical early turns — key architectural decisions, initial constraints, or ADRs made in the first quarter of the session.
author: Donal Moloney
track: context
type: technique
chains-to: shrink-context
---

## Not this skill if
- Headroom is above 20% — use `shrink-context` directly; no sampling needed
- The session has no early-turn decisions worth protecting (all turns are equally disposable)
- You need maximum compression speed, not fairness — use opaque compression

# sample-context-fairly — reservoir sampling for turn retention

## Purpose

When `shrink-context` drops oldest-first, it systematically destroys early turns — which are often the most valuable: the ADR from turn 8, the constraint from turn 25, the scope decision from turn 3. Reservoir sampling fixes this by giving every turn an equal survival probability, regardless of position.

**Core principle:** Every turn — including turn 1 and turn 450 — has the same probability `k/n` of surviving into the compressed context.

## When to activate

Invoke inside `shrink-context` when:
- Context headroom drops below 20%
- Session history contains early-turn decisions that the current task still depends on
- You have already tried anchored iterative summarisation and it is not sufficient

## The algorithm — Vitter's Reservoir Sampling

Given `n` current turns and a target of keeping `k` turns:

```
Algorithm R (Vitter 1985):

1. reservoir = turns[0..k-1]          # seed: keep the first k turns unconditionally
2. for i from k to n-1:
     j = random integer in [0, i]
     if j < k:
       reservoir[j] = turns[i]        # replace a random reservoir slot
3. return reservoir                   # k turns, each with survival prob k/n
```

**Survival probability:** every turn (position 0 through n-1) has exactly `k/n` probability of being in the final reservoir. The algorithm is unbiased — there is no position penalty for being early or late.

**Choosing k:** set k to the number of turns that fit within the target headroom after compression. A practical formula:

```
k = floor(target_token_budget / average_tokens_per_turn)
```

If `average_tokens_per_turn` is unknown, sample 10 random turns and compute the mean.

## Process

1. Count `n` = total turns in the current session history
2. Compute `k` from the target token budget
3. Run Algorithm R → produces a reservoir of `k` turns
4. Sort the reservoir by original turn index (preserve chronological order for the model)
5. Emit the sorted reservoir as the compressed context
6. Attach a header block noting what was dropped:

```
[RESERVOIR SAMPLE: kept k=<k> of n=<n> turns; survival prob <k>/<n>; seed <seed>]
```

7. Run probe-based evaluation (see `shrink-context`) on the result to verify critical information survived

## Worked example

Session has `n = 120` turns. Target headroom allows `k = 40` turns.

- Turn 8 (ADR: chose Redis over Postgres) → survival prob = 40/120 = 33%
- Turn 112 (latest test result) → survival prob = 40/120 = 33%
- Both have the same chance. Oldest-first would delete turn 8 with certainty.

After running Algorithm R:
- If turn 8 survives: the Redis decision is preserved
- If it does not: the header block records the loss → run a decision probe to detect it

## Decision probes (post-sample)

After sampling, verify critical information survived:

| Probe | Question to ask | Pass condition |
|-------|----------------|----------------|
| Early decision | "What was the database choice and why?" | Correct answer without re-reading conversation |
| Constraint | "What are the out-of-scope items?" | Correct scope recalled |
| File trail | "Which files have been modified?" | Accurate file list |

If a probe fails, re-run the sample with a higher `k` (increase the target budget), or extract the missing information into a protected preamble before sampling.

## Protected preamble pattern

For decisions that are too critical to risk losing, extract them before sampling:

```markdown
## Protected context (extracted before reservoir sample)
- Turn 3: Scope — in-scope: X, out-of-scope: Y, Z
- Turn 8: ADR — chose Redis for session store (rationale: latency < 1ms required)
- Turn 25: Constraint — must not modify auth.controller.ts (legal freeze)
```

Prepend the preamble to the reservoir output. The preamble is not counted toward `k`.

## Pitfalls

| Problem | Fix |
|---------|-----|
| Reservoir is unordered | Sort by original turn index before emitting |
| k set too low | Probe failures reveal missing decisions — increase k |
| Critical turns never survive across multiple sessions | Use protected preamble for non-negotiable information |
| Random seed not recorded | Record seed in the header block for reproducibility |

## Integration

- `shrink-context` — invoke this technique when headroom < 20% and oldest-first dropping is unacceptable
- `detect-context-rot` — diagnose before compressing; confirm rot before sampling
- `check-remaining-context` — measure headroom before and after sampling
