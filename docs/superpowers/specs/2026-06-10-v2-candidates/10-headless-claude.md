# headless-claude — v2 candidate spec

| Field | Value |
|---|---|
| Type | **plugin** (command + skill) |
| Theme | Advanced Claude Code |
| Tier | v2 |
| Supports (v1) | verification-before-completion, requesting-code-review |
| Composes with (v2) | fan-out-code-review (#6), skill-lint |
| Status | proposed |

## Problem

Every v1 workflow assumes an interactive session. But Claude Code runs headless
(`claude -p`) in scripts and CI — where review and verification discipline pay
off most, because they run on *every* PR with no human remembering to ask. There
is no skill covering how to package a v1 workflow into a reliable non-interactive
invocation: prompt construction, output contracts, exit codes, permission flags.

## What it does

Two deliverables in one plugin:
1. A **skill** teaching how to wrap any v1 workflow for headless execution.
2. A worked **command + script** example: a CI review gate that runs a review
   pass on a PR diff and exits nonzero on blockers.

## Parts

### `SKILL.md` (the general technique)

**Frontmatter**
- `name: headless-claude`
- `description`: "Use when a v1 workflow (review, verification, lint) should run
  non-interactively — in CI, a git hook, or a script — covers prompt packaging,
  output contracts, exit codes, and permission scoping for `claude -p`."
- `tier: v2`, `supports: [verification-before-completion, requesting-code-review]`.

**Section: Not this skill if**
- A human is in the loop — run the v1 skill interactively.
- The job is a recurring *cloud* schedule — that's the scheduling/routines
  surface, not a script you own.

**Section: The headless contract (core content)**
A headless invocation must fix four things the interactive session gets for
free:
1. **Complete prompt** — no follow-up questions possible; the same six-element
   standard as v2 `context-sufficiency-check` applies, plus the instruction to
   never ask and to fail loudly when context is insufficient.
2. **Output contract** — demand a machine-parseable tail (JSON block or
   sentinel lines like `VERDICT: pass|fail`); never grep prose.
3. **Exit/permission discipline** — least-privilege tool allowlist for the job
   (a reviewer needs read+grep, not write); explicit timeout; treat the model's
   verdict, not its exit code alone, as the gate.
4. **Determinism aids** — pin the diff/inputs into the prompt (heredoc or file
   refs), so reruns see identical inputs.

**Section: Failure handling**
Headless runs can't debug interactively: on insufficient context or tool denial
the script must surface the transcript path and fail the job — silent passes are
the cardinal sin (same principle as v1 `verification-before-completion`).

### `commands/ci-review.md` (slash command)
`/ci-review [base-ref]` — interactive entry point that assembles the same
review prompt locally so users can test the gate before wiring CI.

### `scripts/ci-review.sh` (worked example)
- Collects `git diff base...HEAD`, builds the prompt per the contract, invokes
  `claude -p` with the read-only allowlist, parses the `VERDICT:` tail, exits
  0/1.
- Annotated as the template to copy for other workflows (verification gate,
  skill-lint in CI, changelog checks).

## Workflow

pick v1 workflow → write headless contract (prompt, output, permissions,
timeout) → test via `/ci-review` locally → wire script into CI → PRs get the
discipline automatically.

## Interfaces

- **v1 requesting-code-review**: the worked example is its headless form.
- **#6 fan-out-code-review**: a later iteration of the script can fan out lenses
  in CI; out of scope for v1 of this plugin.
- **v2 skill-lint**: second-best candidate for headless wrapping (lint SKILL.md
  files on every commit) — mention as an exercise.

## Success criteria

- The example script run on a seeded bad PR exits 1 with a parseable verdict,
  and on a clean PR exits 0 — both without any interactive prompt.
- The SKILL.md contract transfers: wrapping skill-lint headlessly requires no
  new concepts.

## Risks / open questions

- CLI flags and output formats evolve — keep exact flags in the script (one
  place to update), principles in the SKILL.md.
- Cost control in CI: per-run token budget / model choice guidance needed —
  cheap-model-first for gates, escalate on failure?
- API key handling in CI is deliberately out of scope (point at CI secret
  stores; never inline).
