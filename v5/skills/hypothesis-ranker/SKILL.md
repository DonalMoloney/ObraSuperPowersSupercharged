---
name: hypothesis-ranker
description: Use while debugging — maintains a Bayesian posterior over competing hypotheses, updating each on observed evidence so the most-likely cause is always ranked first, replacing the bare "3 REFUTED → escalate" counter.
author: Donal Moloney
track: B
type: support
chains-to: diagnose-bug
---

## Not this skill if
- Only one hypothesis on the table — just test it
- Not a debugging context — this ranks *causal* hypotheses
- You have no `decision-ledger` entries yet — collect at least one observation first, then apply this skill

# hypothesis-ranker — Bayesian cause ranking

## Purpose

Give `decision-ledger` a quantitative spine: rank competing hypotheses by posterior probability and
escalate on a principled confidence floor rather than a fixed strike count.

Replace intuition-driven triage ("this feels most likely") with a live ranked list where every new
observation shifts the order and a hard floor triggers escalation automatically.

## Core rule

> **Rule:** Every observation updates the posterior. Escalate when the top hypothesis stays below the
> confidence floor after N updates — not at an arbitrary count.

## Triggers

**Use when:**
- Two or more competing hypotheses exist for a bug or failure mode
- A `decision-ledger` entry records a new observation (test result, log line, reproduction step)
- The ranked order has not changed after three successive updates and the top posterior is still below floor
- `diagnose-bug` asks "which cause is most likely right now?"

**Don't use when:**
- Only one hypothesis remains — test it directly; ranking a singleton wastes a step
- The hypotheses are non-causal (feature options, design directions) — use `decision-ledger` or `mash-ideas` instead
- No observations have been recorded yet — gather at least one `decision-ledger` entry first

## The pattern

```
prior[H1..Hn]           // start with uniform or domain-informed priors
for each observation O:
    likelihood[Hi] = P(O | Hi)      // how well does Hi predict O?
    posterior[Hi] ∝ prior[Hi] * likelihood[Hi]
    normalise(posterior)            // sum to 1.0
    re-rank(hypotheses, posterior)
    prior = posterior               // update for next round
if max(posterior) < floor after N rounds:
    escalate()
```

## Algorithm

### Step 1 — List hypotheses and set priors

Write out every competing hypothesis. If domain knowledge favours one over another, weight it
proportionally (e.g., 0.5 / 0.3 / 0.2). If you have no prior knowledge, set uniform priors
(1/N each). Record the hypothesis list and initial priors in the active `decision-ledger` session.

Sub-steps:
- Give each hypothesis a short, falsifiable label (H1: "cache miss", H2: "null pointer", H3: "race condition").
- Avoid vague labels — "something wrong in module X" is not a testable hypothesis.
- Cap the list at 6–8 hypotheses; prune any that are not independently testable.

### Step 2 — Assign a likelihood for each new observation

For each `decision-ledger` observation, ask: "How likely is this observation *if* hypothesis Hi is true?"
Express this as a probability between 0.0 and 1.0 for each hypothesis.

Sub-steps:
- A confirming observation raises the likelihood of the matching hypothesis (e.g., 0.8).
- A refuting observation lowers it (e.g., 0.1).
- An uninformative observation (identical likelihood across all Hi) does not shift rank — note it as neutral and move on.
- If the observation is ambiguous, split it: assign moderate likelihoods (0.4–0.6) across several hypotheses rather than forcing a binary.

### Step 3 — Apply the Bayesian update and renormalise

Multiply each hypothesis's current prior by its likelihood for this observation.
Divide every result by the sum of all products so the posteriors sum to 1.0.
This is the Beta/Bernoulli update from the `bgalbraith/bandits` / `PlaytikaOSS/pybandits` model.

Sub-steps:
- New posterior[Hi] = prior[Hi] * likelihood[Hi] / Σ(prior[Hj] * likelihood[Hj])
- Round to two decimal places for readability.
- Replace prior[Hi] with the new posterior[Hi] before the next observation.

### Step 4 — Re-rank and display

Sort hypotheses by descending posterior. Output the ranked table after every update so the most
probable cause is always visible at the top.

Format:
```
Rank | Hypothesis | Posterior | Change
  1  | H2: null pointer | 0.54 | +0.21
  2  | H1: cache miss   | 0.31 | -0.14
  3  | H3: race cond.   | 0.15 | -0.07
```

### Step 5 — Evaluate the escalation condition

After each update, check two conditions:

1. **Confidence floor:** if `max(posterior) >= floor` (default 0.75), the top hypothesis is
   sufficiently likely — proceed to test it in `diagnose-bug`.
2. **Stall condition:** if the top hypothesis has stayed below floor for N consecutive updates
   (default N = 3), ranking is not converging. Escalate immediately.

Escalation paths:
- If hypotheses are exhausted or stalled: hand off to `mash-ideas` to generate new hypotheses.
- If the top hypothesis is plausible but stuck: hand off to `try-different-approach` to change the test strategy.
- Return to `diagnose-bug` with the updated ranked list after any escalation resolves.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Setting all priors to equal when domain knowledge exists | Use informed priors — a known-flaky module deserves a higher prior than an untouched path |
| Assigning likelihood 0.0 to a hypothesis on a single refuting observation | Use 0.05–0.1, not 0.0 — a zero posterior can never recover no matter how much evidence follows |
| Treating an uninformative observation as confirmatory | Check whether likelihoods differ across hypotheses; if they don't, skip the update |
| Escalating at a fixed strike count instead of the confidence floor | Use `max(posterior) < floor after N updates` as the trigger; fixed counts ignore probability mass |
| Letting the hypothesis list grow unbounded mid-session | Prune hypotheses with posterior < 0.05 after three consecutive updates — they are effectively eliminated |
| Skipping the renormalisation step | Posteriors must always sum to 1.0; unnormalised values produce meaningless rankings |

## Verification / Proof

Hand the ranked list back to `diagnose-bug` once either the confidence floor is cleared or an
escalation path is chosen.

The `PROVEN BY:` block must contain:

- The full ranked hypothesis table at the point of handoff (rank, label, final posterior)
- The number of `decision-ledger` observations processed
- The escalation condition that fired (floor cleared OR stall after N updates), or "top hypothesis selected"
- The receiving skill (`diagnose-bug`, `mash-ideas`, or `try-different-approach`) and the input passed to it

```
PROVEN BY:
  observations processed: <N>
  final ranking: [table]
  exit condition: <floor cleared | stall at round N | hypotheses exhausted>
  handed to: <skill> with input: <summary>
```

## Adapt from
- **`bgalbraith/bandits`** / **`PlaytikaOSS/pybandits`** — Beta/Bayesian update primitives.
  <https://github.com/bgalbraith/bandits>
