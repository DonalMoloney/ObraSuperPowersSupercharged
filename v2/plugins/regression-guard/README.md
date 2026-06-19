# regression-guard (v2 plugin)

A **regression workflow**: a test that used to pass now fails. Don't guess, and
don't blind-retry until it's green. Three disciplined moves —

1. **Rule out flakiness** — is the failure real, or nondeterministic noise?
2. **Localize** — find the *single* commit that introduced the regression.
3. **Re-verify mechanically** — a hook re-runs the suite when Claude finishes, so
   "it's green now" is a fact, not a memory.

## The flow

```
test failure
   │
   ▼
flaky-test-quarantine        (standalone v2 skill — REFERENCED, not bundled)
   │   classify: flaky vs real. Flaky → quarantine + ticket, stop here.
   ▼   Real → continue.
bisect-the-regression        (this plugin's skill)
   │   git bisect run + an automated check script → one bad commit SHA,
   │   handed to v1 systematic-debugging for root cause.
   ▼
run-verifier Stop hook       (this plugin's hook)
       re-runs the project's test command when Claude stops; WARNS if red.
```

### Step 1 — rule out flakiness (referenced, not copied)

Before localizing anything, classify the failure with the standalone v2 skill
**flaky-test-quarantine**, which lives at `v2/skills/flaky-test-quarantine/`.
It re-runs the failing test in isolation `K` times to decide flaky vs real. A
flaky failure gets quarantined with a ticket and the workflow stops — bisecting
a nondeterministic failure is wasted effort because the bisect predicate can't be
trusted. Only a **real** (deterministic) failure proceeds to step 2.

> This plugin **references** flaky-test-quarantine; it does not vendor a copy.
> Use the canonical skill at its own path so there is one source of truth.

### Step 2 — localize the regression (this plugin)

The skill **bisect-the-regression** (`skills/bisect-the-regression/`) wraps
`git bisect run` with an automated check script, binary-searching history to the
**single** commit that turned the test red, then hands that SHA to v1
**systematic-debugging** for root-cause work.

Boundary with the standalone v2 **delta-debugger**: delta-debugger minimizes the
failing **input** (ddmin → a 1-minimal reproducer); bisect-the-regression
minimizes **history** (which commit). They are complementary — minimize the input
to get a clean predicate, then bisect history with it.

### Step 3 — re-verify mechanically (this plugin's hook)

A `Stop` hook (`hooks/run-verifier.sh`) fires when Claude finishes a turn,
detects the project's test command, re-runs it, and **warns** (non-blocking by
default) if the suite is red.

## Why a plugin, not just a skill

Hooks fire **mechanically**, regardless of what the model remembers — Cherny's
hooks-as-enforcement principle. A skill that says "re-run the tests at the end"
can be forgotten under context pressure; a `Stop` hook cannot. The verifier
becomes part of the session machinery instead of a thing the model has to choose
to do, so a "done" claim is always backed by an actual run.

## Configuration

The verifier hook is **fail-soft and warn-by-default** — false blocks are what get
hooks uninstalled. Tune via environment variables:

| Variable | Default | Effect |
|---|---|---|
| `RG_MODE` | `warn` | `warn` = print a note on red, never block; `block` = exit 2 on red; `off` = disable |
| `RG_TEST_CMD` | (auto) | Override autodetection with an explicit command, e.g. `RG_TEST_CMD="pytest -q"` |

Autodetection order when `RG_TEST_CMD` is unset: `npm test` (if `package.json`
has a `test` script) → `pytest` (if available and tests look present) →
`make test` (if a `Makefile` target exists). If **none** is found, the hook
prints a one-line note and exits 0 — it never bricks the session.

## Files

```
regression-guard/
├── .claude-plugin/plugin.json
├── README.md
├── skills/
│   └── bisect-the-regression/SKILL.md
└── hooks/
    ├── hooks.json
    └── run-verifier.sh
```
