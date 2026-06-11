---
name: web-vitals-triage
description: Use when a page is slow, janky, or failing Core Web Vitals (LCP, CLS, INP) and you need to make it measurably faster. Trace-driven loop — record, read the insights, fix the single top offender, re-trace to prove the gain. One offender per iteration.
cluster: perf
---

# web-vitals-triage — one offender per loop, proven by re-trace

Applies v1 **systematic-debugging**'s one-hypothesis-at-a-time discipline to
performance: the trace is the evidence, the top insight is the hypothesis, the
re-trace is the verification. Read that skill for the discipline; this skill
maps it onto the performance tools.

**Core rule: never fix two things between traces. A re-trace after each single
fix is the only proof the fix worked — and the only way to know which one did.**

## Not this skill if

- Nothing is measured yet and the concern is payload size or re-renders in
  general — `render-and-bundle-discipline` sets budgets first.
- The page is broken, not slow — `frontend-bug-forensics`.

## The loop

1. **Record the baseline trace.** Chrome DevTools MCP:
   `performance_start_trace` (with page reload to capture load metrics) →
   exercise the slow interaction if INP is the complaint →
   `performance_stop_trace`. Record the reported LCP / CLS / INP values —
   this is the baseline; nothing counts as "faster" except against it.
2. **Read the insights, pick ONE.** `performance_analyze_insight` on the
   trace's top insight (LCP breakdown, render-blocking requests, layout
   shift culprits, long tasks). Pick the single biggest offender by impact
   on the worst metric. Write one line: metric, offender, expected
   improvement.
3. **Cross-check the offender** before touching code: `list_network_requests`
   for the implicated resource (size, timing, priority), or
   `evaluate_script` for the implicated DOM/script behavior.
4. **Fix that one offender.** Nothing else. Resist drive-by optimizations —
   they contaminate the measurement.
5. **Re-trace.** Repeat step 1 identically (same page state, same
   interaction). Compare metrics to baseline. Improved → keep, record the
   delta. Not improved → revert, the insight was misread; back to step 2.
6. **Loop or stop.** Loop while the target metric misses its threshold
   (LCP ≤ 2.5s, CLS ≤ 0.1, INP ≤ 200ms — or the project's stated targets).
   Stop when met; record the final trace.

## Red flags

- "While I'm in here…" — batched fixes make the re-trace unreadable.
- Claiming a fix worked from theory without the re-trace numbers.
- Comparing traces recorded under different conditions (cold vs warm cache,
  different viewport, different interaction).

## Verification

Before claiming the page faster:

1. Baseline trace numbers: LCP / CLS / INP from the first
   `performance_start_trace` / `performance_stop_trace` run, plus the
   `performance_analyze_insight` output naming the offender.
2. Per-iteration re-trace numbers showing the delta attributable to each
   single fix.
3. Final trace meeting the stated thresholds, recorded under the same
   conditions as the baseline.

Evidence required: baseline trace, per-fix re-traces, final trace. A faster
feel is an anecdote; a re-trace is proof.
