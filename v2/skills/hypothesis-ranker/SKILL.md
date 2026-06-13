---
name: hypothesis-ranker
description: Use when a bug has two or more plausible root causes and evidence is arriving incrementally — maintains a ranked, probability-weighted set of competing hypotheses, re-ranking on each test result so the debugger never anchors on hypothesis #1.
author: Donal Moloney
tier: v2
supports: [systematic-debugging]
type: process
pairs-with: delta-debugger
---

## Not this skill if

- You only have one hypothesis — there is nothing to rank; test it directly via v1 **systematic-debugging** Phase 3.
- The failing input is large or the introducing commit is unknown — that is v2 **delta-debugger** (shrink the repro / bisect the commit), which produces the evidence this skill then ranks on.
- The fault's *location* is unknown but the cause is obvious once found — that is v2 **dragon-radar** / **instant-transmission** (locate the site), not weighing rival explanations.
- The competing options are non-causal (feature directions, design choices a human ratifies) — that is v2 **decision-ledger**, which records ratified decisions, not a live posterior over causes.

# Hypothesis Ranker

## Purpose

v1 **systematic-debugging** requires competing hypotheses (the HYPOTHESES rows of its Debugging Ledger), but its loop tests them one at a time and marks each CONFIRMED or REFUTED. Under that flow a debugger naturally anchors on H1, pours evidence into it, and only reaches for H2 once H1 is refuted. This skill keeps **all** live hypotheses ranked by probability simultaneously, so a single ambiguous observation that nudges three rivals at once is reflected, and the cheapest test that *splits* the field is always visible.

It does not replace the ledger's HYPOTHESES rows — it orders them. Each ranked hypothesis still becomes a ledger entry with its predicted observation and is marked CONFIRMED/REFUTED there.

**Core rule:** every observation updates every hypothesis's probability, then you re-rank. The next test to run is the one whose predicted outcomes differ most across the top hypotheses — the cheapest *discriminating* test, not the cheapest test.

## The ranked set

Maintain a small table alongside the ledger (in your response, or the ledger scratch file):

```
Rank | Hypothesis (falsifiable label) | P    | Predicted observation if true
  1  | H2: stale cache returns old row | 0.45 | GET after PUT returns pre-PUT value
  2  | H1: race on write path          | 0.35 | failure rate scales with concurrency
  3  | H3: serializer drops field      | 0.20 | field absent in raw response bytes
```

Rules for the set:
- Each hypothesis needs a **distinct predicted observation** — if two predict the same thing, no test can separate them; merge or sharpen them.
- Probabilities sum to ~1.0. Start uniform (1/N) unless domain knowledge justifies a skew (a known-flaky module earns a higher start).
- Cap at ~6 hypotheses. Drop any that fall below ~0.05 and stay there across two updates — note it dropped; don't delete the reasoning.
- Never set a probability to exactly 0 on one refuting result — a zeroed hypothesis can never recover. Floor it (~0.05) unless the prediction was definitively contradicted.

## Procedure

1. **Seed the set.** List the competing hypotheses as falsifiable labels, give each a distinct predicted observation and a starting probability. Mirror them into the ledger's HYPOTHESES rows.
2. **Pick the discriminating test.** Choose the cheapest test whose predicted outcome *differs* across the current top two or three hypotheses — running it will move the ranking no matter how it comes out. A test that all leading hypotheses predict identically is wasted.
3. **Update on the result.** Raise the probability of hypotheses whose prediction matched the observation, lower those it contradicted, leave untouched any the observation doesn't bear on. Re-normalise so the set sums to ~1.0, then re-sort. (Bayesian framing: new ∝ prior × how well the hypothesis predicted what you saw — exact arithmetic is optional; directional updates that re-rank are the point.)
4. **Record in the ledger.** The hypothesis you actually tested gets its ledger entry marked CONFIRMED or REFUTED with the literal test command and output, per v1 **systematic-debugging**. The ranked set is the *navigation layer*; the ledger remains the evidence record.
5. **Exit.** When the top hypothesis is clearly ahead (e.g. ≥ ~0.75) and ledger-CONFIRMED, proceed to v1 **systematic-debugging** Phase 4 to fix it. If the ranking stalls — the top stays low and unchanged across ~3 updates — the field is exhausted: stop adding tests and follow v1 Phase 4.5 ("question the architecture"), since failure to discriminate among plausible causes is itself a signal the model is wrong.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Pouring every test into H1 until it's refuted | Pick the test that splits the *top of the field*; that's how ranking earns its keep |
| Two hypotheses with the same prediction | Sharpen one or merge them — no test can rank indistinguishable causes |
| Zeroing a hypothesis on one refuting result | Floor it (~0.05); a true zero can never recover from later evidence |
| Treating an uninformative observation as confirmation | If all leading hypotheses predicted it equally, it changes nothing — don't re-rank on it |
| Keeping the ranked set but skipping the ledger | The set navigates; the v1 ledger still records the CONFIRMED/REFUTED test with literal output |
| Letting the set grow unbounded | Cap ~6; drop sub-0.05 hypotheses after two stable updates, noting why |

## After

The ranked set converged on one ledger-CONFIRMED hypothesis, or it stalled and you escalated to v1 **systematic-debugging** Phase 4.5.

PROVEN BY: the final ranked table quoted at handoff (labels + probabilities), the count of observations processed, the exit condition (top hypothesis cleared and CONFIRMED in the ledger | ranking stalled after N updates → architecture questioned), and which the ledger's matching HYPOTHESES row reflects. A fix proposed while a rival hypothesis still holds comparable probability is invalid under this skill.
