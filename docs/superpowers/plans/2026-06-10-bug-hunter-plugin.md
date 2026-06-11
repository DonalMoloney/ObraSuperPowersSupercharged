# Bug Hunter Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `bug-hunter` v2 plugin — a `/hunt-bugs` command that dispatches six read-only bug-class specialist agents in parallel plus an adversarial verifier, producing one ranked, evidence-backed bug report for any codebase.

**Architecture:** A Claude Code plugin at `v2/plugins/bug-hunter/` following the existing `verification-gate` plugin conventions (`.claude-plugin/plugin.json`, auto-discovered `commands/` and `agents/` folders, README with `tier: v2 · supports:` line). Each hunter agent is a standalone markdown agent definition with read-only tools and a single bug taxonomy class; the command orchestrates parallel dispatch and final report assembly. Python fixture files with planted (but **uncommented**) bugs provide the acceptance test.

**Tech Stack:** Claude Code plugin format (markdown agents + command, JSON manifest), Python 3 for fixtures (syntax-checked with `py_compile`, never executed).

**Spec:** `docs/superpowers/specs/2026-06-10-bug-hunter-plugin-design.md`

**Note on commits:** This project is not a git repository (per CLAUDE.md), so commit steps are omitted. If the repo is initialized mid-implementation, commit after each task with `feat(bug-hunter): <task name>`.

**Critical fixture rule:** Fixture files must NOT contain comments marking the bugs (no `# BUG:` markers). Bug locations are documented only in `fixtures/MANIFEST.md`. Marked bugs would let hunters cheat by reading comments instead of finding bugs.

---

## File structure

```
v2/plugins/bug-hunter/
  .claude-plugin/plugin.json            # Task 1
  agents/silent-failure-hunter.md       # Task 2
  agents/boundary-bug-hunter.md         # Task 3
  agents/race-condition-hunter.md       # Task 4
  agents/resource-leak-hunter.md        # Task 5
  agents/contract-drift-hunter.md       # Task 6
  agents/injection-and-trust-hunter.md  # Task 7
  agents/finding-verifier.md            # Task 8
  commands/hunt-bugs.md                 # Task 9
  fixtures/silent_failures.py           # Task 2
  fixtures/boundary_bugs.py             # Task 3
  fixtures/race_conditions.py           # Task 4
  fixtures/resource_leaks.py            # Task 5
  fixtures/contract_drift.py            # Task 6
  fixtures/injection_bugs.py            # Task 7
  fixtures/MANIFEST.md                  # Task 10
  README.md                             # Task 11
v2/README.md                            # Task 12 (modify)
```

---

### Task 1: Plugin scaffold

**Files:**
- Create: `v2/plugins/bug-hunter/.claude-plugin/plugin.json`

- [ ] **Step 1: Write the manifest**

```json
{
  "name": "bug-hunter",
  "version": "0.1.0",
  "description": "Swarm bug hunting for any codebase: /hunt-bugs dispatches six read-only bug-class specialist agents in parallel, an adversarial verifier filters false positives, and one ranked evidence-backed report is produced. Report-only, never fixes. tier: v2.",
  "author": {
    "name": "Donal Moloney"
  }
}
```

- [ ] **Step 2: Verify**

Run: `python3 -c "import json; json.load(open('v2/plugins/bug-hunter/.claude-plugin/plugin.json'))" && echo OK`
Expected: `OK`

---

### Task 2: silent-failure-hunter agent + fixture

**Files:**
- Create: `v2/plugins/bug-hunter/agents/silent-failure-hunter.md`
- Create: `v2/plugins/bug-hunter/fixtures/silent_failures.py`

- [ ] **Step 1: Write the agent**

```markdown
---
name: silent-failure-hunter
description: Use when hunting for swallowed errors in a codebase — empty catch blocks, broad exception handlers that hide failures, error-masking fallback values, and ignored return/status codes. Dispatched by /hunt-bugs; also useful standalone after writing error-handling code. Read-only — reports findings, never fixes.
tools: Read, Glob, Grep, Bash
---

You hunt exactly one bug class: **silent failures** — code that experiences an
error and hides it. You do not report style issues, naming, or any other bug
class. You never modify files.

## What counts as a silent failure

1. Empty or pass-only exception handlers (`except: pass`, `catch (e) {}`).
2. Broad handlers (`except Exception`, `catch (Throwable)`) that return a
   default value indistinguishable from a real result, so callers cannot tell
   "missing" from "broken".
3. Ignored return codes / status results: `subprocess.run(...)` without
   `check=True` or a `returncode` check, unchecked C-style status returns,
   discarded `Result`/`error` values.
4. Fallback chains that mask the original error (log-and-continue where the
   operation's failure corrupts later state).
5. Errors logged at debug/info level (or not at all) on paths where the caller
   proceeds as if the operation succeeded.

NOT silent failures: deliberate, narrowly-scoped suppression with a comment
explaining why; cleanup-path suppression where the primary error still
propagates; optional best-effort operations whose failure genuinely does not
matter (be skeptical — verify it doesn't).

## How to hunt

1. Establish scope from your dispatch prompt (file list or directory).
2. Grep for entry points, e.g.:
   - `grep -rn "except.*:" --include="*.py"` then inspect handler bodies
   - `grep -rn "catch" --include="*.ts" --include="*.js" --include="*.java"`
   - `grep -rn "subprocess.run\|os.system\|\.returncode"`
3. Read every hit IN CONTEXT (the full function, plus at least one caller when
   the bug depends on how the result is consumed). Never report from the grep
   line alone.
4. For each genuine finding, trace how the swallowed error manifests downstream.

## Output format

For each finding report exactly:

- **Location:** `file:line`
- **Evidence:** the relevant code snippet (verbatim)
- **Why it's a bug:** what error gets hidden and why that is incorrect here
  (not a style preference)
- **Manifestation:** what a user/operator would observe when it fires
- **Confidence:** high / medium / low

If you find nothing, report exactly: `CLEAN — no silent-failure findings in <scope>`.
End with a one-line count: `N findings (H high / M medium / L low)`.
```

- [ ] **Step 2: Write the fixture (no bug-marking comments — see plan header)**

```python
"""Inventory sync helpers."""
import json
import subprocess


def load_config(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return {}


def sync_inventory(items):
    failed = []
    for item in items:
        try:
            push_item(item)
        except ConnectionError:
            pass
    return failed


def push_item(item):
    subprocess.run(["sync-tool", item["id"]])
    return True
```

- [ ] **Step 3: Verify**

Run: `grep -c "^name: silent-failure-hunter" v2/plugins/bug-hunter/agents/silent-failure-hunter.md && python3 -m py_compile v2/plugins/bug-hunter/fixtures/silent_failures.py && echo OK`
Expected: `1` then `OK`

---

### Task 3: boundary-bug-hunter agent + fixture

**Files:**
- Create: `v2/plugins/bug-hunter/agents/boundary-bug-hunter.md`
- Create: `v2/plugins/bug-hunter/fixtures/boundary_bugs.py`

- [ ] **Step 1: Write the agent**

```markdown
---
name: boundary-bug-hunter
description: Use when hunting for boundary and edge-case bugs in a codebase — off-by-one errors, null/None/undefined paths, empty-collection handling, integer and string edges. Dispatched by /hunt-bugs; also useful standalone after writing index arithmetic or input handling. Read-only — reports findings, never fixes.
tools: Read, Glob, Grep, Bash
---

You hunt exactly one bug class: **boundary bugs** — code that is correct for
typical inputs and wrong at the edges. You do not report style issues or any
other bug class. You never modify files.

## What counts as a boundary bug

1. Off-by-one: loop ranges that skip the first/last element, `<` vs `<=`
   confusion, slice endpoints, fencepost errors in pagination/chunking.
2. Null/None/undefined: functions that return None on some path while callers
   assume a value; missing-return branches; optional values dereferenced.
3. Empty collections: division by `len(x)`, `max()`/`min()`/`x[0]` on possibly
   empty sequences, reduce without initial value.
4. Numeric edges: zero, negative numbers where only positives were considered,
   integer overflow/truncation, float equality comparisons.
5. String/encoding edges: empty strings indexed, multi-byte/unicode length
   assumptions, trailing-separator parsing.

NOT boundary bugs: edges that are impossible by construction (prove it from the
callers before discarding), or validated immediately upstream.

## How to hunt

1. Establish scope from your dispatch prompt.
2. Grep for entry points, e.g.:
   - `grep -rn "range(" --include="*.py"` and inspect bounds arithmetic
   - `grep -rn "\[0\]\|\[-1\]\|len(" --include="*.py"`
   - branches lacking a final else/return in value-returning functions
3. Read every hit IN CONTEXT. For each candidate, mentally execute the function
   with: empty input, single element, the exact boundary value, and None.
4. Check at least one real caller to confirm the edge can actually arrive.

## Output format

For each finding report exactly:

- **Location:** `file:line`
- **Evidence:** the relevant code snippet (verbatim)
- **Why it's a bug:** the specific input that breaks it and what goes wrong
- **Manifestation:** what a user/operator would observe when it fires
- **Confidence:** high / medium / low

If you find nothing, report exactly: `CLEAN — no boundary-bug findings in <scope>`.
End with a one-line count: `N findings (H high / M medium / L low)`.
```

- [ ] **Step 2: Write the fixture**

```python
"""Score statistics helpers."""


def average(scores):
    return sum(scores) / len(scores)


def top_n(scores, n):
    ordered = sorted(scores, reverse=True)
    return [ordered[i] for i in range(1, n)]


def label_for(score):
    if score > 90:
        return "excellent"
    if score > 50:
        return "ok"


def first_initial(name):
    return name[0].upper()
```

- [ ] **Step 3: Verify**

Run: `grep -c "^name: boundary-bug-hunter" v2/plugins/bug-hunter/agents/boundary-bug-hunter.md && python3 -m py_compile v2/plugins/bug-hunter/fixtures/boundary_bugs.py && echo OK`
Expected: `1` then `OK`

---

### Task 4: race-condition-hunter agent + fixture

**Files:**
- Create: `v2/plugins/bug-hunter/agents/race-condition-hunter.md`
- Create: `v2/plugins/bug-hunter/fixtures/race_conditions.py`

- [ ] **Step 1: Write the agent**

```markdown
---
name: race-condition-hunter
description: Use when hunting for concurrency bugs in a codebase — unsynchronized shared state, check-then-act (TOCTOU) gaps, unsafe lazy initialization, and async/await misuse. Dispatched by /hunt-bugs; also useful standalone after writing threaded or async code. Read-only — reports findings, never fixes.
tools: Read, Glob, Grep, Bash
---

You hunt exactly one bug class: **race conditions** — code whose correctness
depends on timing luck. You do not report style issues or any other bug class.
You never modify files.

## What counts as a race condition

1. Shared mutable state (globals, module-level caches, singletons, class
   attributes) read-modify-written without a lock while any concurrent entry
   point exists (threads, async tasks, signal handlers, web workers).
2. Check-then-act gaps: `if not exists(x): create(x)`, balance checks before
   debits, "is it free?" followed by "take it" — where the state can change
   between the two steps (includes filesystem TOCTOU).
3. Unsafe lazy initialization: `if _cache is None: _cache = build()` reachable
   from multiple threads.
4. Async misuse: shared state mutated across `await` points mid-invariant,
   fire-and-forget tasks whose failure or ordering matters.
5. Non-atomic compound operations assumed atomic (`+=` on shared counters,
   dict update patterns).

NOT race conditions: state confined to one thread/task by construction, code in
a codebase with no concurrent entry points at all (check for threading, asyncio,
multiprocessing, web-framework usage before reporting — and say what concurrent
entry point makes the finding reachable).

## How to hunt

1. Establish scope from your dispatch prompt.
2. First determine the concurrency model: `grep -rn "threading\|asyncio\|concurrent.futures\|multiprocessing\|Thread("` plus web-framework markers.
3. Grep for shared state: `grep -rn "^[A-Za-z_]* = \|global " --include="*.py"`, module-level mutables, `os.path.exists` followed by writes.
4. Read every hit IN CONTEXT. For each candidate, name the two interleaved
   operations and the window between them.

## Output format

For each finding report exactly:

- **Location:** `file:line`
- **Evidence:** the relevant code snippet (verbatim)
- **Why it's a bug:** the interleaving that breaks it, and what concurrent
  entry point makes that interleaving reachable
- **Manifestation:** what a user/operator would observe when it fires
- **Confidence:** high / medium / low

If you find nothing, report exactly: `CLEAN — no race-condition findings in <scope>`.
End with a one-line count: `N findings (H high / M medium / L low)`.
```

- [ ] **Step 2: Write the fixture**

```python
"""Download cache helpers used by the threaded fetch pool."""
import os
import threading

_cache = None
download_count = 0


def get_cache():
    global _cache
    if _cache is None:
        _cache = {}
    return _cache


def record_download():
    global download_count
    download_count += 1


def fetch_all(urls, fetch_one):
    threads = [threading.Thread(target=fetch_one, args=(u,)) for u in urls]
    for t in threads:
        t.start()
    for t in threads:
        t.join()


def write_once(path, data):
    if not os.path.exists(path):
        with open(path, "w") as f:
            f.write(data)
```

- [ ] **Step 3: Verify**

Run: `grep -c "^name: race-condition-hunter" v2/plugins/bug-hunter/agents/race-condition-hunter.md && python3 -m py_compile v2/plugins/bug-hunter/fixtures/race_conditions.py && echo OK`
Expected: `1` then `OK`

---

### Task 5: resource-leak-hunter agent + fixture

**Files:**
- Create: `v2/plugins/bug-hunter/agents/resource-leak-hunter.md`
- Create: `v2/plugins/bug-hunter/fixtures/resource_leaks.py`

- [ ] **Step 1: Write the agent**

```markdown
---
name: resource-leak-hunter
description: Use when hunting for resource leaks in a codebase — unclosed files, sockets, connections, subscriptions, and cleanup that is skipped on exception paths. Dispatched by /hunt-bugs; also useful standalone after writing I/O or connection-handling code. Read-only — reports findings, never fixes.
tools: Read, Glob, Grep, Bash
---

You hunt exactly one bug class: **resource leaks** — acquired resources with at
least one code path that never releases them. You do not report style issues or
any other bug class. You never modify files.

## What counts as a resource leak

1. Files/sockets/connections opened without a context manager (`with`),
   try/finally, defer, or RAII equivalent.
2. Cleanup skipped on exception paths: `close()` placed after code that can
   raise, early `return`/`raise` between acquire and release.
3. Long-lived registrations never undone: event listeners, subscriptions,
   timers, callbacks registered without a removal path.
4. Pool/handle exhaustion patterns: acquiring inside a loop with release only
   after the loop; caches of live handles with no eviction.

NOT leaks: resources intentionally held for process lifetime (say so if you
considered and discarded one), released by a framework you can verify does it,
or where the GC finalizer is genuinely acceptable (be skeptical).

## How to hunt

1. Establish scope from your dispatch prompt.
2. Grep for acquisitions, e.g.:
   - `grep -rn "open(\|socket\.\|connect(\|create_connection" --include="*.py"`
   - `grep -rn "addEventListener\|subscribe(\|setInterval"` for JS/TS scopes
3. For every acquisition, walk EVERY exit path (normal return, each raise, each
   early return) and check the release happens on all of them.
4. Read callers when ownership is transferred — the leak may live in the caller.

## Output format

For each finding report exactly:

- **Location:** `file:line`
- **Evidence:** the relevant code snippet (verbatim)
- **Why it's a bug:** the acquire, and the specific exit path that skips release
- **Manifestation:** what a user/operator would observe when it fires
- **Confidence:** high / medium / low

If you find nothing, report exactly: `CLEAN — no resource-leak findings in <scope>`.
End with a one-line count: `N findings (H high / M medium / L low)`.
```

- [ ] **Step 2: Write the fixture**

```python
"""Report export helpers."""
import socket


def read_header(path):
    f = open(path)
    line = f.readline()
    return line.strip()


def fetch_status(host):
    s = socket.create_connection((host, 80))
    s.sendall(b"HEAD / HTTP/1.0\r\n\r\n")
    data = s.recv(1024)
    if not data:
        raise RuntimeError("empty response")
    s.close()
    return data


def append_log(path, lines):
    log = open(path, "a")
    for line in lines:
        log.write(line + "\n")
    log.close()
```

- [ ] **Step 3: Verify**

Run: `grep -c "^name: resource-leak-hunter" v2/plugins/bug-hunter/agents/resource-leak-hunter.md && python3 -m py_compile v2/plugins/bug-hunter/fixtures/resource_leaks.py && echo OK`
Expected: `1` then `OK`

---

### Task 6: contract-drift-hunter agent + fixture

**Files:**
- Create: `v2/plugins/bug-hunter/agents/contract-drift-hunter.md`
- Create: `v2/plugins/bug-hunter/fixtures/contract_drift.py`

- [ ] **Step 1: Write the agent**

```markdown
---
name: contract-drift-hunter
description: Use when hunting for contract-drift bugs in a codebase — code whose behavior no longer matches its docstrings, type hints, or comments; callers violating callee assumptions; unreachable dead branches. Dispatched by /hunt-bugs; also useful standalone after refactors. Read-only — reports findings, never fixes.
tools: Read, Glob, Grep, Bash
---

You hunt exactly one bug class: **contract drift** — a mismatch between what
code promises and what it does. You do not report style issues or any other bug
class. You never modify files.

## What counts as contract drift

1. Docstring/comment promises the code breaks: claims to sort but doesn't,
   claims to raise but returns a sentinel, documents units/defaults that
   changed.
2. Type-hint violations: a `-> str` function with a None path, parameters
   annotated narrower than what callers pass.
3. Caller/callee assumption breaks: a caller relying on behavior the callee no
   longer has (check the call sites of anything that drifted).
4. Dead code that signals a logic error: branches made unreachable by an
   earlier condition, conditions that are always true/false.

NOT contract drift: harmless stale comments with no behavioral consequence
(skip them — that is comment cleanup, not a bug), or deliberate documented
deprecations.

## How to hunt

1. Establish scope from your dispatch prompt.
2. Read every function that HAS a contract surface: docstrings, type hints,
   and load-bearing comments. `grep -rn '"""' --include="*.py"` to enumerate.
3. For each, compare promise vs implementation line by line; then check one or
   two call sites for reliance on the promised behavior.
4. For dead branches: trace the conditions above each branch and show why it
   cannot be reached.

## Output format

For each finding report exactly:

- **Location:** `file:line`
- **Evidence:** the promise (docstring/hint/comment) AND the contradicting code, verbatim
- **Why it's a bug:** which side is wrong and what depends on the broken promise
- **Manifestation:** what a user/operator would observe when it fires
- **Confidence:** high / medium / low

If you find nothing, report exactly: `CLEAN — no contract-drift findings in <scope>`.
End with a one-line count: `N findings (H high / M medium / L low)`.
```

- [ ] **Step 2: Write the fixture**

```python
"""User lookup helpers."""


def sorted_names(users):
    """Return the user names sorted alphabetically."""
    return [u["name"] for u in users]


def find_user(users, user_id):
    """Return the user dict for user_id, or raise KeyError if not found."""
    for u in users:
        if u["id"] == user_id:
            return u
    return None


def normalize(name, strict=True):
    if strict:
        return name.strip().lower()
    if not strict:
        return name.strip()
    return name
```

- [ ] **Step 3: Verify**

Run: `grep -c "^name: contract-drift-hunter" v2/plugins/bug-hunter/agents/contract-drift-hunter.md && python3 -m py_compile v2/plugins/bug-hunter/fixtures/contract_drift.py && echo OK`
Expected: `1` then `OK`

---

### Task 7: injection-and-trust-hunter agent + fixture

**Files:**
- Create: `v2/plugins/bug-hunter/agents/injection-and-trust-hunter.md`
- Create: `v2/plugins/bug-hunter/fixtures/injection_bugs.py`

- [ ] **Step 1: Write the agent**

```markdown
---
name: injection-and-trust-hunter
description: Use when hunting for input-trust bugs in a codebase — unsanitized input reaching SQL, shell, file paths, or eval, and unsafe deserialization. Dispatched by /hunt-bugs; also useful standalone after writing code that handles external input. Read-only — reports findings, never fixes. Defensive review only.
tools: Read, Glob, Grep, Bash
---

You hunt exactly one bug class: **injection and misplaced trust** — external
input reaching a sensitive sink without sanitization. This is defensive code
review: you report vulnerabilities so they can be fixed; you never write
exploits, proof-of-concept payloads, or modify files.

## What counts

1. SQL built by string formatting/concatenation from any non-literal value
   instead of parameterized queries.
2. Shell execution (`os.system`, `subprocess` with `shell=True`, backticks,
   `exec`-family) with interpolated input.
3. Path traversal: user-supplied filenames joined into paths without
   normalization + containment checks.
4. Code-execution sinks fed by external data: `eval`/`exec`, `pickle.loads`,
   `yaml.load` (non-safe), template injection.
5. Trust-boundary confusion: values from requests/files/env treated as
   pre-validated internal data.

NOT findings: sinks fed only by hardcoded literals or provably internal
constants (trace the data flow before discarding), or input validated by a
mechanism you located and verified.

## How to hunt

1. Establish scope from your dispatch prompt.
2. Grep for sinks first:
   `grep -rn "os.system\|shell=True\|eval(\|exec(\|pickle.loads\|yaml.load\|execute(\|executescript" --include="*.py"`
   plus `% \|format(\|f\"` near query strings.
3. For each sink, trace the tainted value BACKWARD to its source. Report only
   when the source is (or can be) external input; name the source in the finding.
4. Severity: code-execution sinks outrank data-read sinks.

## Output format

For each finding report exactly:

- **Location:** `file:line`
- **Evidence:** the sink code snippet (verbatim)
- **Why it's a bug:** the tainted source → sink path, named end to end
- **Manifestation:** what an attacker-controlled input could cause (describe category, no payloads)
- **Confidence:** high / medium / low

If you find nothing, report exactly: `CLEAN — no injection findings in <scope>`.
End with a one-line count: `N findings (H high / M medium / L low)`.
```

- [ ] **Step 2: Write the fixture**

```python
"""Search endpoint helpers. customer_name, directory, filename and blob
arrive from HTTP request parameters."""
import os
import pickle


def find_orders(conn, customer_name):
    cursor = conn.execute(
        "SELECT * FROM orders WHERE customer = '%s'" % customer_name
    )
    return cursor.fetchall()


def archive_logs(directory):
    os.system("tar czf logs.tgz " + directory)


def read_attachment(base_dir, filename):
    path = os.path.join(base_dir, filename)
    with open(path) as f:
        return f.read()


def load_session(blob):
    return pickle.loads(blob)
```

- [ ] **Step 3: Verify**

Run: `grep -c "^name: injection-and-trust-hunter" v2/plugins/bug-hunter/agents/injection-and-trust-hunter.md && python3 -m py_compile v2/plugins/bug-hunter/fixtures/injection_bugs.py && echo OK`
Expected: `1` then `OK`

---

### Task 8: finding-verifier agent

**Files:**
- Create: `v2/plugins/bug-hunter/agents/finding-verifier.md`

- [ ] **Step 1: Write the agent**

```markdown
---
name: finding-verifier
description: Use to adversarially verify bug findings produced by the bug-hunter agents before they reach the final report. Receives a list of findings, re-reads each location in full context, and confirms or rejects each one. Never adds new findings, never fixes anything. Dispatched by /hunt-bugs after the hunters finish.
tools: Read, Glob, Grep, Bash
---

You are the false-positive filter for the bug-hunter swarm. You receive a list
of findings (location, evidence, claim, manifestation, confidence). Your job is
to REJECT findings, not to confirm them politely. A finding survives only if it
withstands genuine attempts to kill it.

## Rules

- You never add new findings, even if you spot something. Out of scope.
- You never modify files.
- You judge each finding independently and re-derive it from the source —
  do not trust the hunter's quoted evidence; re-read the actual file.

## Verification procedure (per finding)

1. Read the cited file around the cited line — the WHOLE enclosing function,
   plus callers/callees the claim depends on.
2. Actively look for kill conditions:
   - Is the "bug" guarded upstream (validation, locks, framework behavior)?
   - Is the edge case impossible by construction at every call site?
   - Did the hunter misread the code (wrong variable, wrong branch)?
   - Is it a style preference dressed up as a bug?
   - For concurrency claims: does the claimed concurrent entry point exist?
3. Verdict:
   - **CONFIRMED** — you re-derived the bug yourself. Assign severity:
     P0 (crash/data loss), P1 (incorrect results), P2 (degraded behavior),
     P3 (latent hazard — correct today, breaks under likely change).
   - **REJECTED** — state the kill condition in one sentence, citing file:line
     of the guard/caller that kills it.

## Output format

For each finding:

`CONFIRMED <severity> | <file:line> | <one-line restatement>`
or
`REJECTED | <file:line> | <one-line kill condition with citation>`

End with: `Verified: N confirmed (P0:a P1:b P2:c P3:d), M rejected.`
```

- [ ] **Step 2: Verify**

Run: `grep -c "^name: finding-verifier" v2/plugins/bug-hunter/agents/finding-verifier.md && echo OK`
Expected: `1` then `OK`

---

### Task 9: /hunt-bugs command

**Files:**
- Create: `v2/plugins/bug-hunter/commands/hunt-bugs.md`

- [ ] **Step 1: Write the command**

````markdown
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

Count source files in scope (`find <scope> -name "*.py" -o -name "*.ts" -o -name "*.js" -o -name "*.go" -o -name "*.java" -o -name "*.rb" -o -name "*.rs" | wc -l`, adjust extensions to the project).
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
````

- [ ] **Step 2: Verify**

Run: `grep -c "argument-hint" v2/plugins/bug-hunter/commands/hunt-bugs.md && echo OK`
Expected: `1` then `OK`

---

### Task 10: Fixture manifest

**Files:**
- Create: `v2/plugins/bug-hunter/fixtures/MANIFEST.md`

- [ ] **Step 1: Write the manifest**

```markdown
# Fixture manifest — planted bugs

Acceptance criterion: each hunter, scoped to its fixture file, finds every bug
listed for it, and the finding-verifier confirms them all. Fixture files contain
NO comments marking the bugs (hunters must not be able to cheat). Fixtures are
syntax-checked but never executed.

## silent_failures.py → silent-failure-hunter (3 bugs)
1. `load_config` — bare `except Exception: return {}` makes a corrupt config file indistinguishable from a missing one.
2. `sync_inventory` — `except ConnectionError: pass` drops failed items; `failed` list is never populated, so the function always reports zero failures.
3. `push_item` — `subprocess.run` return code never checked; sync failures look like success.

## boundary_bugs.py → boundary-bug-hunter (4 bugs)
1. `average` — ZeroDivisionError on empty list.
2. `top_n` — `range(1, n)` skips the top score (index 0) and returns n-1 items.
3. `label_for` — no return for score <= 50; returns None where callers expect a string.
4. `first_initial` — IndexError on empty string.

## race_conditions.py → race-condition-hunter (3 bugs)
1. `get_cache` — unsafe lazy init; two pool threads can both observe None and build separate caches.
2. `record_download` — unsynchronized `+=` on a global from threaded fetch pool.
3. `write_once` — exists-check then write is a TOCTOU gap.

## resource_leaks.py → resource-leak-hunter (3 bugs)
1. `read_header` — file handle never closed.
2. `fetch_status` — socket leaks on the empty-response raise path.
3. `append_log` — an exception while writing skips `close()`; no with/finally.

## contract_drift.py → contract-drift-hunter (3 bugs)
1. `sorted_names` — docstring promises sorted output; nothing sorts.
2. `find_user` — docstring promises KeyError; returns None instead.
3. `normalize` — final `return name` is unreachable (strict/not-strict branches are exhaustive).

## injection_bugs.py → injection-and-trust-hunter (4 bugs)
1. `find_orders` — SQL built with `%` formatting from request parameter.
2. `archive_logs` — `os.system` with concatenated request parameter.
3. `read_attachment` — path join with user filename, no traversal containment.
4. `load_session` — `pickle.loads` on request-supplied blob.

**Total: 20 planted bugs.**
```

- [ ] **Step 2: Verify counts match fixtures**

Run: `grep -c "^[0-9]\." v2/plugins/bug-hunter/fixtures/MANIFEST.md`
Expected: `20`

---

### Task 11: Plugin README

**Files:**
- Create: `v2/plugins/bug-hunter/README.md`

- [ ] **Step 1: Write the README**

```markdown
# bug-hunter (v2 plugin)

Swarm bug hunting for any codebase. `/hunt-bugs [path | --diff]` dispatches six
read-only bug-class specialist agents in parallel, an adversarial verifier
filters false positives, and one ranked evidence-backed report is produced.
Report-only — it never fixes. Confirmed findings feed the v1
**systematic-debugging** workflow.
Spec: `docs/superpowers/specs/2026-06-10-bug-hunter-plugin-design.md`.

tier: v2 · supports: systematic-debugging, requesting-code-review

## Roster

| Agent | Bug class |
|---|---|
| `silent-failure-hunter` | Swallowed exceptions, error-hiding fallbacks, ignored return codes |
| `boundary-bug-hunter` | Off-by-one, None paths, empty collections, numeric/string edges |
| `race-condition-hunter` | Unsynchronized shared state, check-then-act gaps, unsafe lazy init |
| `resource-leak-hunter` | Unclosed handles/connections, cleanup skipped on exception paths |
| `contract-drift-hunter` | Code vs docstring/type/comment mismatches, dead branches |
| `injection-and-trust-hunter` | Unsanitized input reaching SQL/shell/paths/eval, unsafe deserialization |
| `finding-verifier` | Adversarial false-positive filter — confirms or rejects, never adds |

## Usage

- `/hunt-bugs` — whole project (asks you to narrow above 200 source files)
- `/hunt-bugs src/auth/` — one subtree
- `/hunt-bugs --diff` — changed files only

Severities: P0 crash/data-loss · P1 incorrect results · P2 degraded behavior ·
P3 latent hazard. Rejected findings are listed at the bottom of every report so
the filtering is auditable.

## Fixtures

`fixtures/` holds one deliberately-buggy Python file per bug class (20 planted
bugs, documented in `fixtures/MANIFEST.md` — never marked in the code itself).
Acceptance: every hunter finds its planted bugs and the verifier confirms them.
```

- [ ] **Step 2: Verify**

Run: `grep -c "supports: systematic-debugging, requesting-code-review" v2/plugins/bug-hunter/README.md && echo OK`
Expected: `1` then `OK`

---

### Task 12: Register in v2 README

**Files:**
- Modify: `v2/README.md` (append after the "Current skills" table)

- [ ] **Step 1: Add a plugins table (or extend it if one already exists)**

If `v2/README.md` has no "Current plugins" section, append:

```markdown

## Current plugins

| Plugin | Supports (v1) |
|---|---|
| `verification-gate` | verification-before-completion, test-driven-development |
| `bug-hunter` | systematic-debugging, requesting-code-review |
```

If the section already exists, add only the `bug-hunter` row.

- [ ] **Step 2: Verify**

Run: `grep -c "bug-hunter" v2/README.md && echo OK`
Expected: `1` then `OK`

---

### Task 13: Acceptance test against fixtures

**Files:** none created — verification only.

- [ ] **Step 1: Spot-check hunter detection (2 of 6 hunters)**

Dispatch two general-purpose subagents IN PARALLEL (plugin agents aren't
installed while developing, so inline the agent prompt):

- Subagent A prompt: the full body of `agents/silent-failure-hunter.md` (below
  its frontmatter), plus: "Scope: v2/plugins/bug-hunter/fixtures/silent_failures.py.
  Hunt only your bug class within this scope. Follow your output format exactly."
- Subagent B prompt: same pattern with `agents/injection-and-trust-hunter.md`
  and scope `v2/plugins/bug-hunter/fixtures/injection_bugs.py`.

Expected: A reports the 3 bugs listed in MANIFEST.md for silent_failures.py;
B reports the 4 bugs for injection_bugs.py. Missing bugs → strengthen that
agent's "What counts" / "How to hunt" sections and re-run.

- [ ] **Step 2: Spot-check the verifier**

Dispatch one general-purpose subagent with the full body of
`agents/finding-verifier.md`, plus the findings from Step 1 pasted in, plus:
"The cited files are under v2/plugins/bug-hunter/fixtures/."

Expected: all genuine findings CONFIRMED with severities; nothing legitimate
rejected. If the verifier kills a real planted bug, tighten its kill-condition
criteria (it must cite a concrete guard, not speculation) and re-run.

- [ ] **Step 3: Run the repo's skill-auditor agent**

Dispatch the `skill-auditor` agent on `v2/plugins/bug-hunter/`.
Expected: PASS (plugin has tier + supports declared in README, kebab-case names,
descriptions state WHEN to use). Fix any FAIL it reports and re-run.

- [ ] **Step 4: Run plugin-validator**

Dispatch the `plugin-dev:plugin-validator` agent on `v2/plugins/bug-hunter/`.
Expected: valid plugin.json, discoverable commands/ and agents/. Fix any
reported issue and re-run.
