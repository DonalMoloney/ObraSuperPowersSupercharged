---
description: Dispatch the bug-hunter swarm — six read-only bug-class specialists in parallel plus an adversarial verifier — and produce one ranked bug report. Report-only; never fixes.
argument-hint: "[path | --diff]"
---

Run a bug-hunting swarm over the requested scope. You orchestrate; the agents
hunt. You never modify files during this command.

## 1. Resolve scope

Argument: `$ARGUMENTS`

- A path → hunt that file or subtree.
- `--diff` → hunt only changed files: union of `git diff --name-only` and
  `git diff --name-only --staged` (if not a git repo, tell the user and stop).
- Empty → the whole current project.

Count source files in scope (`find <scope> \( -name "*.py" -o -name "*.ts" -o -name "*.js" -o -name "*.go" -o -name "*.java" -o -name "*.rb" -o -name "*.rs" \) | wc -l`, adjust extensions to the project).
**If the count exceeds 200, stop and ask the user to narrow the scope** (suggest
`--diff` or a subdirectory). Do not run a partial sweep.

Exclude: dependency dirs (node_modules, venv, vendor), generated code, and any
`fixtures/` directory belonging to this plugin.

## 2. Dispatch hunters (parallel, single message)

Dispatch ALL SIX hunter agents in ONE message so they run concurrently:
`bug-hunter:silent-failure-hunter`, `bug-hunter:boundary-bug-hunter`,
`bug-hunter:race-condition-hunter`, `bug-hunter:resource-leak-hunter`,
`bug-hunter:contract-drift-hunter`, `bug-hunter:injection-and-trust-hunter`.

Each prompt must contain: the resolved scope (explicit file list if ≤20 files,
else the directory), the project's primary language(s), and the instruction
"Hunt only your bug class within this scope. Follow your output format exactly."

## 3. Collect

Gather every finding. Hunters reporting `CLEAN` are recorded as clean. A hunter
that errors is recorded as a COVERAGE GAP — never silently dropped.

## 4. Verify

Dispatch `bug-hunter:finding-verifier` ONCE with the complete finding list
(every field each hunter reported). If there are zero findings, skip this step.
Carry each hunter's original confidence through to its confirmed finding when
assembling the report.

## 5. Report

Print one report:

```
# Bug Hunt Report — <scope> — <date>

## Confirmed findings (ranked)
<P0 first, then P1/P2/P3; within severity, high confidence first.
 Per finding: severity, file:line, claim, evidence snippet, manifestation,
 originating hunter.>

## Rejected by verifier
<one line each: file:line — kill condition>

## Coverage
<table: hunter → findings / clean / GAP (with error note)>
```

If everything is clean, say so plainly — do not pad the report. Suggest the v1
systematic-debugging workflow for any confirmed P0/P1 as the natural next step.
