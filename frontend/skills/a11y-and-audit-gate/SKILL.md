---
name: a11y-and-audit-gate
description: Use when about to ship any user-facing page or flow — new or meaningfully changed. Runs an accessibility snapshot review (roles, labels, contrast, keyboard path) plus a Lighthouse audit; red findings get fixed and the gate re-runs to confirm.
cluster: verify
---

# a11y-and-audit-gate — ship gate for accessibility and audits

Extends v1 **verification-before-completion** with a second, stricter evidence
bar for shipping: not just "does it work," but "does it pass." Same rule —
evidence before assertions — applied to accessibility and audit scores.

**Core rule: red findings block shipping. Fix, re-run the gate, and only a
clean re-run opens it.**

## Not this skill if

- Verifying a small UI change works at all — run `visual-verification-loop`
  first; this gate comes after, at ship time.
- Performance triage on a known-slow page — `web-vitals-triage` owns the
  trace-and-fix loop; this gate only flags the score.

## The gate

1. **Accessibility snapshot.** `take_snapshot` (Chrome DevTools MCP) or
   `browser_snapshot` (Playwright MCP) of the page. Review the tree for:
   - elements missing roles or accessible names (unlabeled buttons, icon-only
     controls, images without alt);
   - heading structure (one h1, no skipped levels);
   - form inputs without associated labels.
2. **Keyboard path.** Walk the changed flow with `press_key` /
   `browser_press_key` (Tab, Shift+Tab, Enter, Escape) only — no clicks.
   Confirm focus is visible at each stop (`take_screenshot` at the
   hard-to-see stops) and nothing is unreachable or trapped.
3. **Contrast spot-check.** `evaluate_script` / `browser_evaluate` reading
   `getComputedStyle` color and background-color of body text, secondary
   text, and the accent-on-background pairs; compute the ratios against
   WCAG AA (4.5:1 body, 3:1 large text).
4. **Lighthouse audit.** `lighthouse_audit` (Chrome DevTools MCP) on the page.
   Record the accessibility and performance scores and every red (failing)
   audit item.
5. **Triage.** Red findings: fix now. Yellow: fix or record a one-line reason
   it ships anyway. Then **re-run steps 1–4** — the gate only opens on the
   re-run's results, never on the first run plus promises.

## Red flags

- Fixing the findings and shipping without the re-run.
- "The component library handles a11y" — snapshot it anyway; composition
  breaks what components guarantee.
- Keyboard-testing with the mouse in hand.

## Verification

The gate's opening evidence, all from the post-fix re-run:

1. The re-run `take_snapshot` / `browser_snapshot` output showing the
   previously flagged roles/names/labels resolved.
2. Keyboard-path confirmation: the Tab-walk sequence with focus-visible
   screenshots at the previously failing stops.
3. The re-run `lighthouse_audit` result: zero red accessibility items, scores
   recorded, any accepted yellows listed with reasons.

First-run results prove the problems; only re-run results prove the fixes.
