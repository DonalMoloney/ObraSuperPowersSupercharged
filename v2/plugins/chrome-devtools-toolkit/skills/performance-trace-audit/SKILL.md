---
name: performance-trace-audit
description: Use when making any web performance claim or working on "make it faster" tasks — record before/after performance traces and Lighthouse audits under identical throttled conditions instead of asserting improvement.
author: Donal Moloney
tier: v2
supports: [verification-before-completion]
type: technique
chains-to: verification-before-completion
pairs-with: browser-evidence-debugging
---

# Performance Trace Audit

Supercharges v1 **verification-before-completion** for performance work:
"evidence before assertions" means numbers from traces, not impressions from
re-reading the diff.

**Gate rule: no performance claim without before-and-after traces recorded
under identical conditions.**

## Precondition

Requires the chrome-devtools MCP server (`performance_start_trace`,
`performance_stop_trace`, `performance_analyze_insight`, `emulate`,
`lighthouse_audit`). If unavailable, report **blocked** with an install hint.

## Not this skill if

- The claim is about correctness, not speed — use **ui-verification-loop**
  (playwright-toolkit) or v1 verification-before-completion.
- You suspect a memory leak — use **memory-leak-hunt**.

## Workflow

1. **Pin the conditions.** Set throttling once and reuse it for every run:
   `emulate` with CPU throttling (e.g. 4x) and a network preset (e.g.
   "Slow 4G"). Unthrottled dev-machine traces hide real regressions.
2. **Record the baseline.** `performance_start_trace` (with page reload) →
   `performance_stop_trace`. Note LCP, CLS, and the top insights.
3. **Analyze.** `performance_analyze_insight` on each flagged insight
   (LCP breakdown, render-blocking requests, layout shifts). Optionally run
   `lighthouse_audit` for category scores.
4. **Write the baseline numbers down** before touching code — afterwards is
   too late to be honest.
5. **Make the change.**
6. **Re-trace under identical conditions.** Same `emulate` settings, same
   page, same reload procedure.
7. **Produce the before/after table** (the gate artifact):

   | Metric | Before | After | Delta |
   |---|---|---|---|
   | LCP | … | … | … |
   | CLS | … | … | … |
   | Lighthouse perf score (if run) | … | … | … |
   | Top insight | … | … | resolved? |

8. **Verdict.** Improved / unchanged / regressed — stated from the table.
   A regression is a finding to report, not something to retry until it
   disappears.

## Red flags

- "Should be faster now" — gate violation; where is the table?
- Comparing a throttled run against an unthrottled one.
- Tracing once and eyeballing — single runs are noisy; if deltas are small,
  trace twice per side and report both.
