---
name: fast-verify-loop
description: Use before starting any implementation work — picks the fastest verifier that is still sufficient for the change class, so the generation–verification loop stays tight between edits
tier: v4
inspiration: "Karpathy — generation–verification loop speed (Software Is Changing (Again), YC AI Startup School keynote, June 2025)"
chains-to: [loop-until-green]
---

# Fast Verify Loop

**Not this skill if:** you need the loop RUN repeatedly until green → v2 `loop-until-green` (this skill chooses the verifier; that one drives it); you don't know the project's canonical build/test/lint commands → v2 `verify-command-suggester`; you need a verification TARGET defined (what "correct" even means) → v4 `verification-target-first`.

This skill answers one question before the first edit: **what is the cheapest check that would actually catch a mistake in this change?** Run that check between increments. Save the expensive checks for the end.

## The verifier-latency ladder

Lowest rung = fastest feedback. Climb only as far as the change class requires.

| Rung | Verifier | Typical latency |
|------|----------|-----------------|
| 1 | Type-check (`tsc --noEmit`, `mypy`, compiler) | seconds |
| 2 | Lint (`eslint`, `ruff`, `clippy`) | seconds |
| 3 | Single test file (the one covering the change) | seconds–tens of seconds |
| 4 | Affected-package tests | tens of seconds–minutes |
| 5 | Full suite | minutes |
| 6 | E2E / integration | many minutes |

**UI work has its own mini-ladder:** screenshot (visual check) < DOM dump. A screenshot is verified in one glance; a DOM dump must be read. Prefer the visual artifact — that is the whole point of the inspiration.

## Sufficiency rules: change class → minimum rung

| Change class | Between increments | At end of task |
|--------------|--------------------|----------------|
| Pure refactor in a typed codebase | Rung 1 (type-check) is sufficient | Full suite (rung 5) once |
| Logic change | Rung 3 — the single test file that should fail/pass | Affected packages (rung 4) |
| Cross-module change | Rung 4 — affected-package tests | Full suite (rung 5) |
| Release-bound change | Rung 4 minimum | Full suite + e2e (rungs 5–6) |
| UI change | Screenshot after each visible change | Screenshot + affected tests |

Two failure modes this table prevents:

- **Over-verifying:** running the full suite after every two-line edit. The loop slows to minutes per increment and you stop iterating in small chunks.
- **Under-verifying:** type-checking a logic change. Types pass, behavior is wrong, and the error compounds across edits before anything catches it.

## Pre-warm step

Before the first edit, get the chosen verifier hot so per-increment cost is near zero:

1. If rung 3–4 is the loop verifier, start watch mode if available (`vitest --watch`, `pytest-watch`, `cargo watch -x test`) scoped to the relevant file/package.
2. If rung 1, confirm incremental compilation is on (warm `tsc --watch`, a running language server, or an incremental build cache).
3. If UI, get the dev server running and take one baseline screenshot before changing anything — the before/after pair makes each later glance-check instant.
4. Run the chosen verifier once on the untouched code. It must pass (or its failures must be known) before edit one, or every later result is ambiguous.

## Loop discipline

- One increment → one run of the chosen rung → next increment. Never batch multiple unverified increments.
- If the loop verifier ever takes longer than the edit it checks, you picked too high a rung — drop down and defer the expensive rung to the end.
- The end-of-task rung from the table is mandatory, not optional polish. Hand the actual loop-running to v2 `loop-until-green` when failures need iterating to green.

## Provenance

- **Idea:** Human–AI collaboration throughput is bounded by the generation–verification loop: the AI generates, the human verifies, and products/workflows should make that loop "very, very fast." Visual presentation (GUIs, red/green diffs) makes verification much faster than reading text, and work should proceed in small incremental chunks so each verification is cheap.
- **Where stated:** Andrej Karpathy, "Software Is Changing (Again)," keynote at Y Combinator AI Startup School, June 2025 (web-verified: YC Startup Library hosts the talk under this title; transcript confirms the "generation verification loop ... very, very fast" framing, the GUI-speeds-verification point, and "always go in small incremental chunks ... spin this loop very, very fast").
- **How this tool operationalizes it:** It converts loop speed from an aspiration into a selection procedure — a latency-ordered ladder of verifiers, sufficiency rules that pick the cheapest rung that still catches the relevant mistake class, a preference for visual artifacts (screenshots) in UI work, and a pre-warm step so the chosen verifier costs near zero per increment.
