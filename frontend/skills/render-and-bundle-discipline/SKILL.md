---
name: render-and-bundle-discipline
description: Use when shipping or reviewing frontend work that adds dependencies, data fetching, or stateful rendering — before it merges. Budget-driven check for unnecessary re-renders, oversized payloads, and render-blocking resources using the network request list and trace data.
cluster: perf
---

# render-and-bundle-discipline — state the budget, measure against it

Extends v1 **verification-before-completion**: a performance claim without a
measurement is an assertion, and assertions don't merge. Here the verification
artifacts are budgets and the numbers measured against them.

**Core rule: no budget, no judgment. "Seems fine" is not a measurement —
write the numbers down first, then compare.**

## Not this skill if

- A page already fails a Core Web Vital and needs fixing — `web-vitals-triage`
  runs the fix loop; this skill is the preventive merge-time check.
- The bug is functional — `frontend-bug-forensics`.

## Process

1. **State the budgets** before measuring (project's own, or these defaults):
   - JS transferred on initial load ≤ 300 KB compressed
   - total initial payload ≤ 1 MB; no single image > 200 KB
   - zero render-blocking third-party scripts
   - zero re-renders of unchanged components on an unrelated interaction
2. **Measure payloads.** Load the page fresh, then `list_network_requests`
   (Chrome DevTools MCP) or `browser_network_requests` (Playwright MCP).
   Tally JS/CSS/image/font transfer sizes; inspect outliers with
   `get_network_request`. Flag: duplicate libraries, uncompressed responses,
   full-size images in thumbnail slots, anything render-blocking in `<head>`.
3. **Measure rendering.** `performance_start_trace` → perform one typical
   interaction (type in one field, toggle one control) →
   `performance_stop_trace`. Use `performance_analyze_insight` on long-task /
   rendering insights. Cross-check suspect wide re-renders with
   `evaluate_script` (e.g. a mutation counter via `MutationObserver`, or the
   framework's own profiling hook) — an interaction in one widget that
   re-renders the page fails the budget.
4. **Compare against budget, line by line.** Each line gets a measured number
   and over/under. Over budget → fix the offender (split the chunk, lazy-load,
   compress, memoize, narrow the state subscription) — or record a one-line
   justified exception.
5. **Re-measure the fixed lines** (steps 2–3 for the affected measurements)
   until every line is under budget or recorded as an exception.

## Red flags

- Adding a dependency without checking what it does to the JS line.
- Judging bundle size from the build log alone — the network list shows what
  the user actually downloads, compression and caching included.
- A budget table written after the measurements, fitted to pass.

## Verification

Before claiming the work within budget:

1. The budget table, stated before measurement, with a measured number per
   line from `list_network_requests` / `browser_network_requests` (payloads)
   and the trace + `performance_analyze_insight` output (rendering).
2. The interaction re-render check result from the trace and the
   `evaluate_script` cross-check.
3. For any line initially over budget: the re-measured number now under it,
   or the recorded exception.

Evidence required: the filled-in budget table with every line under budget or
explicitly excepted. No table, no merge.
