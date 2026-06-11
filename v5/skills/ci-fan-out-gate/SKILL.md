---
name: ci-fan-out-gate
description: Runs an adversarial-verify quality gate on every pull request that touches skills/ — fans each skeptic check out N times, applies majority-vote survival logic, and auto-emits a PROVEN BY: block to proof-gate.
author: Donal Moloney
track: A
---

## Not this skill if
- You are still drafting a skill — only invoke at PR-open or merge-readiness
- No files under `skills/` are changed in the current diff
- You need general CI setup — this gate is scoped exclusively to `SKILL.md` quality enforcement

## Purpose

`ci-fan-out-gate` enforces that every `SKILL.md` touched in a pull request passes a structured adversarial-verify check before merge. Each skeptic module forms a hypothesis ("this skill has problem X"), runs independently N times, and the majority vote decides whether the finding survives. Surviving findings are posted as GitHub check-run annotations and fail the gate.

The gate ships as a deterministic, zero-dependency Node linter so it runs in CI today with no API keys. Plugging in an LLM-backed skeptic later is a one-file change — the fan-out loop, majority rule, and annotation rendering are all handled by the core.

## When to use

- A PR changes one or more `skills/**/SKILL.md` files
- You want CI to enforce frontmatter completeness, required sections, and proof-chain integrity automatically
- You want surviving findings to appear as inline PR annotations rather than in a free-form review comment
- You are wiring `ci-fan-out-gate` output into `proof-gate` to satisfy CI-backed evidence blocks without writing them by hand

## Steps

1. **Copy the workflow** into your repo:
   ```bash
   cp v2/plugins/ci-fan-out-gate/workflows/fan-out-gate.yml .github/workflows/fan-out-gate.yml
   ```
   The workflow assumes the plugin lives at `v2/plugins/ci-fan-out-gate/`. If you move it, update `PLUGIN_DIR` at the top of the workflow file.

2. **Commit and open a PR** that touches a file under `skills/`. The workflow triggers on `pull_request` with `paths: ['skills/**']`. No secrets or API keys are required.

3. **Per changed file, the gate:**
   - Runs every registered skeptic against the `SKILL.md` content.
   - Fans each skeptic out N times (default `3`; override with `--skeptics N` or `FANOUT=N`).
   - Each run votes `refuted: false` (finding confirmed) or `refuted: true` (finding not confirmed).
   - A finding **survives** when more than half of its N runs vote `refuted: false`.

4. **Surviving findings** are emitted as `::error` or `::warning` workflow annotations (inline in the PR diff) and summarized in `$GITHUB_STEP_SUMMARY` with the survival vote (e.g. `3/3`).

5. **Gate result:**
   - Zero surviving findings → exit `0`, gate passes.
   - One or more surviving findings → exit `1`, gate fails.

6. **Auto-emit PROVEN BY: block** (see [Auto-emit to proof-gate](#auto-emit-to-proof-gate) below).

## Built-in skeptics

| Skeptic | Severity | Flags |
|---|---|---|
| `frontmatter-name` | error | Missing or empty `name`, or not lowercase kebab-case |
| `frontmatter-description` | error | Missing or empty `description` |
| `description-length` | warning | Description shorter than 20 or longer than 500 characters |
| `required-sections` | error | Missing a Purpose, When-to-use, or Process section |
| `broken-links` | warning | Empty wiki links `[[]]` |
| `leftover-todos` | warning | `TODO` / `FIXME` / `XXX` / `TBD` markers left in |
| `claims-without-proof` | warning | Completion claim (done/passing/fixed) with no `PROVEN BY:` block |

## Auto-emit to proof-gate

When `ci-fan-out-gate` completes, it writes a structured evidence block that `proof-gate` accepts directly as CI-backed proof. This removes the manual step of writing a `PROVEN BY:` block for any claim that CI can verify.

**Format emitted by the gate:**

```
PROVEN BY (ci-fan-out-gate): fan-out-gate.yml → 0 findings survived [N/N skeptics refuted, M files checked]
```

**Wiring:**

1. `ci-fan-out-gate` runs in the PR workflow and exits `0`.
2. The job summary includes the evidence line above.
3. Copy or reference that line in the PR description or task completion note.
4. `proof-gate` treats it as equivalent to a terminal-output evidence block — the command is the workflow run, the key output is the survival count.

**When findings survive (gate fails):**

Do not emit a `PROVEN BY:` block. Address surviving findings, push a fix, and wait for the gate to re-run cleanly before claiming the skill is done.

**Fallback:**

If the workflow is not available (e.g. first-time local run before pushing), use `run-local.sh` and emit:
```
PROVEN BY (ci-fan-out-gate/local): ./run-local.sh skills/my-skill/SKILL.md → exit 0, 0 findings survived
```

## Running locally

```bash
# Verify every skills/**/SKILL.md in the repo:
./run-local.sh

# Verify specific files:
./run-local.sh skills/proof-gate/SKILL.md skills/diagnose-bug/SKILL.md

# Increase fan-out:
FANOUT=5 ./run-local.sh skills/proof-gate/SKILL.md
```

Direct CLI:
```bash
node verify.mjs <file> [more...] [--skeptics N] [--json] [--annotations]
```

## Adding a skeptic

Each skeptic is a module under `skeptics/` with a default export:

```js
export default {
  id: 'my-skeptic',
  title: 'Human-readable finding title',
  severity: 'error',           // 'error' | 'warning'
  run(skillText, path) {
    return {
      refuted: false,          // false = problem confirmed; true = no problem found
      reason: 'explanation',
      line: 12,                // optional 1-based line number
    };
  },
};
```

Register it in `skeptics/index.mjs`. A skeptic that throws is treated as `refuted: true` — it cannot fail a PR on its own.

## Output

- GitHub check-run annotations (inline PR diff comments) for each surviving finding
- `$GITHUB_STEP_SUMMARY` table: file, skeptic, severity, survival vote, reason
- Exit code: `0` (all findings refuted) or `1` (one or more findings survived)
- Auto-emitted `PROVEN BY (ci-fan-out-gate):` evidence line when exit code is `0`

## Limitations

- The LLM skeptic is a documented contract stub. The shipped skeptics are deterministic by design. Wiring a model call is left to the integrator.
- `broken-links` only flags empty `[[]]` links; it does not resolve whether `[[some-skill]]` actually exists.
- Frontmatter parsing is YAML-lite (flat `key: value` only) — sufficient for `SKILL.md` frontmatter.

## Integrates with

- [`proof-gate`](../proof-gate/SKILL.md): consumes the structured evidence block emitted on a clean gate run
- [`verify-before-done`](../verify-before-done/SKILL.md): run locally before pushing; `ci-fan-out-gate` is the CI counterpart
- [`finish-branch`](../finish-branch/SKILL.md): the gate should pass before a branch is merged; `finish-branch` checks for a clean gate as a precondition
- [`claims-without-proof` skeptic]: flags any completion claim in a `SKILL.md` that lacks a `PROVEN BY:` block — closing the loop on proof-gate enforcement inside skill files themselves
