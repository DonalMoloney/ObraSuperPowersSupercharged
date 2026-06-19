# v7 Karpathy AutoResearch Plugin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `v7/plugins/autoresearch` — a runnable Claude Code plugin that runs Karpathy's keep-or-revert optimization loop (agent proposes, harness judges) over any measurable objective.

**Architecture:** A bash harness (`autoresearch.sh`) owns the loop, git worktree isolation, evaluation, metric comparison, and accept/revert. Small Node helpers (`scripts/lib/*.mjs`) own config validation, metric extraction, scope checking, and prompt composition — each unit-tested with `node --test`. Each iteration spawns a fresh `claude -p` proposer (injectable, so the loop is testable without an LLM via a mock). The harness's accept/reject logic is proven deterministically with a mock proposer.

**Tech Stack:** bash (3.2+ compatible), Node.js 18+ (helpers + built-in test runner), git worktrees, `shellcheck`. JSON config. No third-party npm/pip dependencies.

## Global Constraints

Copy these into every task's mental checklist.

- **Tier/layout:** Plugin lives at `v7/plugins/autoresearch/`, following the repo `vN/plugins/<name>/` convention (`.claude-plugin/plugin.json`, `commands/`, `skills/<name>/SKILL.md`, `scripts/`). Tier folder gets `v7/README.md`.
- **v7 contract (per spec):** the skill MUST carry `tier: v7`, an `inspiration:` line naming Karpathy AutoResearch, and a `## Provenance` section (artifact + release date 2026-03-07).
- **Load-bearing invariant:** the harness — not the LLM — runs the eval, compares the metric, and decides commit vs revert. The proposer only edits files; it never evals and never commits.
- **Runtime deps:** Node.js ≥ 18 (helpers + `node --test`); git; `shellcheck` for lint; per-iteration timeout uses `timeout`/`gtimeout` if present, else a `perl alarm` fallback. Scripts must run on macOS default bash 3.2 — **no `mapfile`, no associative arrays, no `${var^^}`**.
- **Config:** `autoresearch.config.json` with fields `objective` (string), `artifact` (non-empty string array of globs), `eval_cmd` (string), `metric` (`{type:"regex",pattern}` or `{type:"json",path}`), `direction` (`"minimize"|"maximize"`), `budget` (`{max_iterations,max_wallclock_min,per_iter_timeout_sec}` all positive numbers), optional `stop_after_no_improve` (number), optional `baseline`.
- **Safety:** refuse to start on a dirty tree unless `--allow-dirty`; run inside a git worktree on branch `autoresearch/<run-id>`; enforce `max_iterations`, `max_wallclock_min`, `per_iter_timeout_sec`, `stop_after_no_improve`; honor a `STOP` file; **never auto-merge or auto-push**; **auto-revert any edit outside the artifact set**.
- **Proposer:** default is a fresh `claude -p` per iteration, cwd = worktree, `--permission-mode acceptEdits` (edits only, no bash, no commits). Injectable via env var `AUTORESEARCH_PROPOSER_CMD` so tests substitute a deterministic mock.
- **Run artifacts:** run dir `.autoresearch/<run-id>/` (worktree + `journal.md` + `STOP` + `eval.out`); `.autoresearch/` is git-ignored in the target repo (harness appends it if missing).
- **Verification gates:** all `.mjs` pass `node --test`; all `.sh` pass `shellcheck`; `skill-auditor` on the SKILL; `plugin-validator` on the plugin.

---

## File Structure

| File | Responsibility |
|---|---|
| `v7/README.md` | v7 tier intro + discipline contract |
| `v7/plugins/autoresearch/.claude-plugin/plugin.json` | Plugin manifest |
| `v7/plugins/autoresearch/README.md` | Install, config schema, launch, merge/discard results |
| `v7/plugins/autoresearch/commands/autoresearch.md` | `/autoresearch` — config interview + launch |
| `v7/plugins/autoresearch/skills/autoresearch-loop/SKILL.md` | Proposer discipline + journal protocol |
| `v7/plugins/autoresearch/scripts/autoresearch.sh` | The harness (loop, worktree, eval, accept/revert, budget) |
| `v7/plugins/autoresearch/scripts/lib/config.mjs` | Load/validate config; field/array getters |
| `v7/plugins/autoresearch/scripts/lib/metric.mjs` | Extract metric (regex/json); improvement test |
| `v7/plugins/autoresearch/scripts/lib/scope.mjs` | Glob match; are all changed files in-scope? |
| `v7/plugins/autoresearch/scripts/lib/prompt.mjs` | Compose the proposer prompt |
| `v7/plugins/autoresearch/scripts/lib/proposer.sh` | Default proposer: build prompt + call `claude -p` |
| `v7/plugins/autoresearch/scripts/lib/*.test.mjs` | `node --test` unit tests for the helpers |
| `v7/plugins/autoresearch/tests/harness.test.sh` | Integration tests (mock proposer) |
| `v7/plugins/autoresearch/examples/hillclimb/` | Deterministic toy: artifact + eval + config |

---

## Task 1: Plugin scaffold + tier README + manifest

**Files:**
- Create: `v7/README.md`
- Create: `v7/plugins/autoresearch/.claude-plugin/plugin.json`
- Create: `v7/plugins/autoresearch/README.md`

**Interfaces:**
- Produces: the plugin root and a valid `plugin.json` (consumed by Claude Code's plugin loader and `plugin-validator`).

- [ ] **Step 1: Write the failing test**

Create `v7/plugins/autoresearch/.claude-plugin/manifest.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';

test('plugin.json is valid and has required fields', () => {
  const m = JSON.parse(readFileSync(new URL('./plugin.json', import.meta.url), 'utf8'));
  assert.equal(typeof m.name, 'string');
  assert.ok(m.name.length > 0, 'name non-empty');
  assert.match(m.version, /^\d+\.\d+\.\d+$/, 'semver version');
  assert.equal(typeof m.description, 'string');
  assert.ok(m.description.length > 0, 'description non-empty');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test v7/plugins/autoresearch/.claude-plugin/manifest.test.mjs`
Expected: FAIL — cannot find `plugin.json`.

- [ ] **Step 3: Create the manifest**

`v7/plugins/autoresearch/.claude-plugin/plugin.json`:

```json
{
  "name": "autoresearch",
  "version": "0.1.0",
  "description": "Karpathy's keep-or-revert optimization loop (agent proposes, harness judges) for any measurable objective."
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test v7/plugins/autoresearch/.claude-plugin/manifest.test.mjs`
Expected: PASS.

- [ ] **Step 5: Write the tier README and plugin README**

`v7/README.md`:

```markdown
# v7 — Tool ports as runnable Claude Code plugins

Ports of notable published AI tools/artifacts into installable Claude Code plugins
(starting with Karpathy's). Where **v4** distills Karpathy/Cherny *ideas* into skills,
**v7** ports a *specific named artifact* into a runnable plugin.

## Contract

Each port = `v7/plugins/<name>/`: an installable plugin
(`.claude-plugin/plugin.json` + `commands/` + `skills/` + `scripts/`, optional `hooks/`).
Every v7 plugin MUST:

1. Name the source artifact + release date in a `## Provenance` section and the skill's
   `inspiration:` frontmatter.
2. Preserve the source's core invariant (autoresearch: the harness — not the LLM — owns
   accept/reject).
3. Be runnable out of the box via a deterministic example.
4. Carry `tier: v7` on its skill(s).

`skill-auditor` applies to the skill(s); shell harnesses must be `shellcheck`-clean.

## Plugins

| Plugin | Source artifact | What it does |
|--------|-----------------|--------------|
| `autoresearch` | Karpathy AutoResearch (2026-03-07) | Keep-or-revert optimization loop over any measurable objective |
```

`v7/plugins/autoresearch/README.md`:

```markdown
# autoresearch

A domain-general port of Andrej Karpathy's **AutoResearch** loop: an agent proposes one
change, a harness runs your evaluation, and the change is kept only if your metric improves
— otherwise it's reverted. Repeats unattended until a budget is hit.

**Invariant:** the harness, not the LLM, decides keep vs revert.

## Requirements

Node.js ≥ 18, git, and a shell. (`shellcheck` only needed to develop the plugin.)

## Configure

Create `autoresearch.config.json` in your repo (or run `/autoresearch` to generate it):

\`\`\`json
{
  "objective": "Minimize p95 latency of the search endpoint",
  "artifact": ["src/search/**/*.ts"],
  "eval_cmd": "npm run bench:search",
  "metric": { "type": "regex", "pattern": "p95=([0-9.]+)ms" },
  "direction": "minimize",
  "budget": { "max_iterations": 40, "max_wallclock_min": 480, "per_iter_timeout_sec": 120 },
  "stop_after_no_improve": 8,
  "baseline": null
}
\`\`\`

- `artifact` — globs the proposer may edit; edits outside this set are auto-reverted.
- `eval_cmd` — must exit 0 and print the metric; run only by the harness.
- `metric` — `{ "type": "regex", "pattern": "...(group)..." }` or `{ "type": "json", "path": "a.b.c" }`.

## Run

\`\`\`bash
node ... ; bash scripts/autoresearch.sh [autoresearch.config.json] [--allow-dirty]
\`\`\`

The run is isolated in a git worktree on branch `autoresearch/<run-id>`. Stop early with
`touch .autoresearch/<run-id>/STOP`. When it finishes it prints how to merge or discard:

\`\`\`bash
git merge autoresearch/<run-id>                 # keep the winning changes
git worktree remove .autoresearch/<run-id>/worktree && git branch -D autoresearch/<run-id>
\`\`\`

Nothing is auto-merged or auto-pushed.

## Provenance

Andrej Karpathy, **AutoResearch**, open-sourced 2026-03-07 — a ~630-line single-file tool
(a stripped-down nanochat training core) in which an agent runs autonomous, time-boxed ML
experiments and keeps a change only if validation loss improves, else `git revert`s.
Karpathy framed it as a public *recipe* to adapt to your own domain. This plugin ports the
transferable core — the measurable keep-or-revert loop — as a domain-general engine.
```

- [ ] **Step 6: Commit**

```bash
git add v7/README.md v7/plugins/autoresearch/.claude-plugin/ v7/plugins/autoresearch/README.md
git commit -m "feat(v7): scaffold autoresearch plugin + tier README"
```

---

## Task 2: Config loader/validator (`config.mjs`)

**Files:**
- Create: `v7/plugins/autoresearch/scripts/lib/config.mjs`
- Test: `v7/plugins/autoresearch/scripts/lib/config.test.mjs`

**Interfaces:**
- Produces:
  - `validateConfig(cfg) -> cfg` (throws `Error` on invalid)
  - `loadConfig(path) -> cfg`
  - `getField(cfg, dottedKey) -> string` (scalar, stringified)
  - `getArray(cfg, key) -> string[]`
  - CLI: `node config.mjs validate <path>` (prints `OK` / exits 1 with message);
    `node config.mjs get <path> <dotted.key>` (prints scalar);
    `node config.mjs get-array <path> <key>` (prints items newline-delimited).

- [ ] **Step 1: Write the failing test**

`v7/plugins/autoresearch/scripts/lib/config.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert';
import { validateConfig, getField, getArray } from './config.mjs';

const good = {
  objective: 'go faster', artifact: ['src/**/*.ts'], eval_cmd: 'make bench',
  metric: { type: 'regex', pattern: 'x=([0-9.]+)' }, direction: 'minimize',
  budget: { max_iterations: 5, max_wallclock_min: 10, per_iter_timeout_sec: 30 },
};

test('accepts a valid config', () => {
  assert.deepEqual(validateConfig(structuredClone(good)), good);
});

test('rejects missing required field', () => {
  const c = structuredClone(good); delete c.eval_cmd;
  assert.throws(() => validateConfig(c), /eval_cmd/);
});

test('rejects bad direction', () => {
  const c = structuredClone(good); c.direction = 'sideways';
  assert.throws(() => validateConfig(c), /direction/);
});

test('rejects empty artifact array', () => {
  const c = structuredClone(good); c.artifact = [];
  assert.throws(() => validateConfig(c), /artifact/);
});

test('rejects non-positive budget', () => {
  const c = structuredClone(good); c.budget.max_iterations = 0;
  assert.throws(() => validateConfig(c), /max_iterations/);
});

test('getField reads dotted keys', () => {
  assert.equal(getField(good, 'metric.type'), 'regex');
  assert.equal(getField(good, 'budget.max_iterations'), '5');
});

test('getArray returns items', () => {
  assert.deepEqual(getArray(good, 'artifact'), ['src/**/*.ts']);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test v7/plugins/autoresearch/scripts/lib/config.test.mjs`
Expected: FAIL — cannot import from `./config.mjs`.

- [ ] **Step 3: Write the implementation**

`v7/plugins/autoresearch/scripts/lib/config.mjs`:

```js
import { readFileSync } from 'node:fs';

const REQUIRED = ['objective', 'artifact', 'eval_cmd', 'metric', 'direction', 'budget'];
const BUDGET_KEYS = ['max_iterations', 'max_wallclock_min', 'per_iter_timeout_sec'];

export function validateConfig(cfg) {
  if (cfg == null || typeof cfg !== 'object') throw new Error('config: not an object');
  for (const k of REQUIRED) {
    if (cfg[k] === undefined) throw new Error(`config: missing required field "${k}"`);
  }
  if (!Array.isArray(cfg.artifact) || cfg.artifact.length === 0) {
    throw new Error('config: "artifact" must be a non-empty array of globs');
  }
  if (!['minimize', 'maximize'].includes(cfg.direction)) {
    throw new Error('config: "direction" must be "minimize" or "maximize"');
  }
  if (!cfg.metric || !['regex', 'json'].includes(cfg.metric.type)) {
    throw new Error('config: "metric.type" must be "regex" or "json"');
  }
  if (cfg.metric.type === 'regex' && !cfg.metric.pattern) {
    throw new Error('config: regex metric requires "pattern"');
  }
  if (cfg.metric.type === 'json' && !cfg.metric.path) {
    throw new Error('config: json metric requires "path"');
  }
  const b = cfg.budget || {};
  for (const k of BUDGET_KEYS) {
    if (typeof b[k] !== 'number' || !(b[k] > 0)) {
      throw new Error(`config: budget.${k} must be a positive number`);
    }
  }
  return cfg;
}

export function loadConfig(path) {
  let raw;
  try { raw = readFileSync(path, 'utf8'); }
  catch { throw new Error(`config: cannot read ${path}`); }
  let cfg;
  try { cfg = JSON.parse(raw); }
  catch (e) { throw new Error(`config: invalid JSON in ${path}: ${e.message}`); }
  return validateConfig(cfg);
}

export function getField(cfg, dotted) {
  const v = dotted.split('.').reduce((o, k) => (o == null ? undefined : o[k]), cfg);
  if (v === undefined || v === null) throw new Error(`config: no value at "${dotted}"`);
  return String(v);
}

export function getArray(cfg, key) {
  const v = cfg[key];
  if (!Array.isArray(v)) throw new Error(`config: "${key}" is not an array`);
  return v.map(String);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [cmd, path, key] = process.argv.slice(2);
  try {
    if (cmd === 'validate') { loadConfig(path); console.log('OK'); }
    else if (cmd === 'get') { console.log(getField(loadConfig(path), key)); }
    else if (cmd === 'get-array') { console.log(getArray(loadConfig(path), key).join('\n')); }
    else throw new Error('usage: config.mjs validate|get|get-array <path> [key]');
  } catch (e) { console.error(e.message); process.exit(1); }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `node --test v7/plugins/autoresearch/scripts/lib/config.test.mjs`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add v7/plugins/autoresearch/scripts/lib/config.mjs v7/plugins/autoresearch/scripts/lib/config.test.mjs
git commit -m "feat(v7): autoresearch config loader/validator"
```

---

## Task 3: Metric extraction + improvement test (`metric.mjs`)

**Files:**
- Create: `v7/plugins/autoresearch/scripts/lib/metric.mjs`
- Test: `v7/plugins/autoresearch/scripts/lib/metric.test.mjs`

**Interfaces:**
- Produces:
  - `extractMetric(output, spec) -> number|null` (`spec` = `{type:'regex',pattern}` or `{type:'json',path}`)
  - `isImprovement(candidate, best, direction) -> boolean`
  - CLI: `node metric.mjs extract-regex <pattern> <file>` / `extract-json <path> <file>`
    (print number, or exit 1 if none); `node metric.mjs improved <candidate> <best> <direction>`
    (exit 0 if improvement, else 1).

- [ ] **Step 1: Write the failing test**

`v7/plugins/autoresearch/scripts/lib/metric.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert';
import { extractMetric, isImprovement } from './metric.mjs';

test('regex extracts the capture group', () => {
  assert.equal(extractMetric('p95=12.5ms done', { type: 'regex', pattern: 'p95=([0-9.]+)ms' }), 12.5);
});

test('regex returns null when no match', () => {
  assert.equal(extractMetric('nothing here', { type: 'regex', pattern: 'p95=([0-9.]+)' }), null);
});

test('json extracts a dotted path', () => {
  assert.equal(extractMetric('{"a":{"b":3.0}}', { type: 'json', path: 'a.b' }), 3.0);
});

test('json returns null on unparseable output', () => {
  assert.equal(extractMetric('not json', { type: 'json', path: 'a' }), null);
});

test('minimize: lower is better', () => {
  assert.equal(isImprovement(5, 10, 'minimize'), true);
  assert.equal(isImprovement(12, 10, 'minimize'), false);
});

test('maximize: higher is better', () => {
  assert.equal(isImprovement(12, 10, 'maximize'), true);
});

test('null candidate is never an improvement; null best always is', () => {
  assert.equal(isImprovement(null, 10, 'minimize'), false);
  assert.equal(isImprovement(5, null, 'minimize'), true);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test v7/plugins/autoresearch/scripts/lib/metric.test.mjs`
Expected: FAIL — cannot import from `./metric.mjs`.

- [ ] **Step 3: Write the implementation**

`v7/plugins/autoresearch/scripts/lib/metric.mjs`:

```js
import { readFileSync } from 'node:fs';

export function extractMetric(output, spec) {
  if (spec.type === 'regex') {
    const m = String(output).match(new RegExp(spec.pattern));
    if (!m || m[1] === undefined) return null;
    const v = Number(m[1]);
    return Number.isFinite(v) ? v : null;
  }
  if (spec.type === 'json') {
    let obj;
    try { obj = JSON.parse(output); } catch { return null; }
    const v = spec.path.split('.').reduce((o, k) => (o == null ? undefined : o[k]), obj);
    const n = Number(v);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

export function isImprovement(candidate, best, direction) {
  if (candidate === null || candidate === undefined || !Number.isFinite(Number(candidate))) return false;
  if (best === null || best === undefined || best === '' || !Number.isFinite(Number(best))) return true;
  const c = Number(candidate), b = Number(best);
  return direction === 'minimize' ? c < b : c > b;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [cmd, a, b, c] = process.argv.slice(2);
  if (cmd === 'extract-regex' || cmd === 'extract-json') {
    const type = cmd === 'extract-regex' ? 'regex' : 'json';
    const spec = type === 'regex' ? { type, pattern: a } : { type, path: a };
    const out = readFileSync(b, 'utf8');
    const v = extractMetric(out, spec);
    if (v === null) process.exit(1);
    console.log(String(v));
  } else if (cmd === 'improved') {
    process.exit(isImprovement(a, b, c) ? 0 : 1);
  } else {
    console.error('usage: metric.mjs extract-regex|extract-json <arg> <file> | improved <cand> <best> <dir>');
    process.exit(2);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `node --test v7/plugins/autoresearch/scripts/lib/metric.test.mjs`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add v7/plugins/autoresearch/scripts/lib/metric.mjs v7/plugins/autoresearch/scripts/lib/metric.test.mjs
git commit -m "feat(v7): autoresearch metric extraction + improvement test"
```

---

## Task 4: Scope guard (`scope.mjs`)

**Files:**
- Create: `v7/plugins/autoresearch/scripts/lib/scope.mjs`
- Test: `v7/plugins/autoresearch/scripts/lib/scope.test.mjs`

**Interfaces:**
- Produces:
  - `globToRegExp(glob) -> RegExp` (supports `**`, `*`, `?`)
  - `allInScope(changedPaths, globs) -> boolean`
  - CLI: `node scope.mjs <glob1\nglob2...>` reads newline-delimited changed paths from
    **stdin**; exits 0 if every changed path matches at least one glob, else 1.

- [ ] **Step 1: Write the failing test**

`v7/plugins/autoresearch/scripts/lib/scope.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert';
import { globToRegExp, allInScope } from './scope.mjs';

test('* matches within a path segment, ** across segments', () => {
  assert.ok(globToRegExp('src/*.ts').test('src/a.ts'));
  assert.ok(!globToRegExp('src/*.ts').test('src/sub/a.ts'));
  assert.ok(globToRegExp('src/**/*.ts').test('src/sub/deep/a.ts'));
});

test('? matches a single char', () => {
  assert.ok(globToRegExp('f?o.js').test('foo.js'));
  assert.ok(!globToRegExp('f?o.js').test('fooo.js'));
});

test('allInScope true only when every path matches some glob', () => {
  assert.equal(allInScope(['src/a.ts', 'src/b/c.ts'], ['src/**/*.ts']), true);
  assert.equal(allInScope(['src/a.ts', 'db/pool.ts'], ['src/**/*.ts']), false);
  assert.equal(allInScope([], ['src/**/*.ts']), true);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test v7/plugins/autoresearch/scripts/lib/scope.test.mjs`
Expected: FAIL — cannot import from `./scope.mjs`.

- [ ] **Step 3: Write the implementation**

`v7/plugins/autoresearch/scripts/lib/scope.mjs`:

```js
export function globToRegExp(glob) {
  let re = '';
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i];
    if (c === '*') {
      if (glob[i + 1] === '*') { re += '.*'; i++; if (glob[i + 1] === '/') i++; }
      else re += '[^/]*';
    } else if (c === '?') re += '[^/]';
    else if ('.+^${}()|[]\\'.includes(c)) re += '\\' + c;
    else re += c;
  }
  return new RegExp('^' + re + '$');
}

export function allInScope(changed, globs) {
  const res = globs.map(globToRegExp);
  return changed.every((p) => res.some((r) => r.test(p)));
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const globs = (process.argv[2] || '').split('\n').filter(Boolean);
  let stdin = '';
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', (d) => (stdin += d));
  process.stdin.on('end', () => {
    const changed = stdin.split('\n').map((s) => s.trim()).filter(Boolean);
    process.exit(allInScope(changed, globs) ? 0 : 1);
  });
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `node --test v7/plugins/autoresearch/scripts/lib/scope.test.mjs`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add v7/plugins/autoresearch/scripts/lib/scope.mjs v7/plugins/autoresearch/scripts/lib/scope.test.mjs
git commit -m "feat(v7): autoresearch scope guard (glob matcher)"
```

---

## Task 5: Harness core — preflight, worktree, baseline, iteration, accept/revert

This is the load-bearing task. The integration test uses a **mock proposer** so the
keep-or-revert invariant is proven without an LLM.

**Files:**
- Create: `v7/plugins/autoresearch/scripts/autoresearch.sh`
- Test: `v7/plugins/autoresearch/tests/harness.test.sh`
- Test fixtures: created inline by the test.

**Interfaces:**
- Consumes: `config.mjs` (`validate`/`get`/`get-array`), `metric.mjs` (`extract-*`/`improved`), `scope.mjs`.
- Produces: `autoresearch.sh [config_path] [--allow-dirty]`. Reads proposer from
  `AUTORESEARCH_PROPOSER_CMD` (default `scripts/lib/proposer.sh`). The proposer is invoked
  with env: `AR_OBJECTIVE`, `AR_BEST`, `AR_DIRECTION`, `AR_JOURNAL`, `AR_WORKTREE`,
  `AR_ARTIFACTS` (newline-delimited globs). Writes commits to branch `autoresearch/<run-id>`
  and a journal at `.autoresearch/<run-id>/journal.md`.

- [ ] **Step 1: Write the failing integration test**

`v7/plugins/autoresearch/tests/harness.test.sh`:

```bash
#!/usr/bin/env bash
# Integration test for autoresearch.sh using a deterministic mock proposer.
set -uo pipefail
HARNESS="$(cd "$(dirname "$0")/.." && pwd)/scripts/autoresearch.sh"
fails=0
assert() { if eval "$2"; then echo "ok - $1"; else echo "NOT ok - $1"; fails=$((fails+1)); fi; }

# --- build a throwaway target repo ---
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
git init -q && git config user.email t@t && git config user.name t
echo "value = 0" > knob.txt
# eval prints metric = the integer in knob.txt; lower is "worse" here we MAXIMIZE
cat > eval.sh <<'EOF'
#!/usr/bin/env bash
v=$(grep -oE '[0-9]+' knob.txt | head -1)
echo "score=${v:-0}"
EOF
chmod +x eval.sh
cat > autoresearch.config.json <<'EOF'
{ "objective":"maximize the knob","artifact":["knob.txt"],"eval_cmd":"bash eval.sh",
  "metric":{"type":"regex","pattern":"score=([0-9]+)"},"direction":"maximize",
  "budget":{"max_iterations":3,"max_wallclock_min":60,"per_iter_timeout_sec":30} }
EOF
git add -A && git commit -qm init

# mock proposer: iter1 improves (good), iter2 worsens (bad), iter3 edits out-of-scope
cat > mock.sh <<'EOF'
#!/usr/bin/env bash
cd "$AR_WORKTREE" || exit 1
n=$(grep -oE '[0-9]+' knob.txt | head -1); n=${n:-0}
case "$AR_BEST" in
  0) echo "value = 5" > knob.txt ;;        # iter1: 0 -> 5  (KEEP)
  5) echo "value = 1" > knob.txt ;;        # iter2: 5 -> 1  (REVERT, worse)
  *) echo "x" > out_of_scope.txt ;;        # iter3: out-of-scope (REVERT)
esac
EOF
chmod +x mock.sh

AUTORESEARCH_PROPOSER_CMD="$TMP/mock.sh" bash "$HARNESS" autoresearch.config.json >run.log 2>&1

run="$(ls -d .autoresearch/*/ | head -1)"
journal="${run}journal.md"
assert "journal exists"            "[ -f '$journal' ]"
assert "baseline recorded as 0"    "grep -q 'baseline: 0' '$journal'"
assert "iter1 KEPT"                "grep -q 'iter 1 — KEPT' '$journal'"
assert "iter2 REVERTED"            "grep -q 'iter 2 — REVERTED' '$journal'"
assert "iter3 out-of-scope revert" "grep -q 'iter 3 — REVERTED (out-of-scope)' '$journal'"
# worktree tree is clean after reverts
assert "worktree clean"            "[ -z \"\$(cd '${run}worktree' && git status --porcelain)\" ]"
# exactly one commit beyond init on the branch (only iter1 kept)
assert "one kept commit" "[ \"\$(cd '${run}worktree' && git rev-list --count HEAD ^main 2>/dev/null || cd '${run}worktree' && git rev-list --count HEAD)\" -ge 1 ]"
# out-of-scope file was removed
assert "out-of-scope file gone"    "[ ! -f '${run}worktree/out_of_scope.txt' ]"

echo "---"; [ "$fails" -eq 0 ] && echo "ALL PASS" || { echo "$fails FAILED"; exit 1; }
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash v7/plugins/autoresearch/tests/harness.test.sh`
Expected: FAIL — `autoresearch.sh` does not exist yet.

- [ ] **Step 3: Write the harness**

`v7/plugins/autoresearch/scripts/autoresearch.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$SCRIPT_DIR/lib"

ALLOW_DIRTY=0
CONFIG="autoresearch.config.json"
for a in "$@"; do
  case "$a" in
    --allow-dirty) ALLOW_DIRTY=1 ;;
    *) CONFIG="$a" ;;
  esac
done

die() { echo "autoresearch: $1" >&2; exit 1; }

run_timeout() {  # run_timeout SECS CMD...
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@"; return $?; fi
  if command -v gtimeout >/dev/null 2>&1; then gtimeout "$secs" "$@"; return $?; fi
  perl -e 'my $s=shift; $SIG{ALRM}=sub{exit 124}; alarm $s; exec @ARGV or exit 127;' "$secs" "$@"
}

command -v git >/dev/null 2>&1 || die "git not found"
command -v node >/dev/null 2>&1 || die "node not found"
repo="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not a git repo"
[ -f "$CONFIG" ] || die "config not found: $CONFIG"

if [ "$ALLOW_DIRTY" -eq 0 ] && [ -n "$(git status --porcelain)" ]; then
  die "working tree is dirty; commit/stash or pass --allow-dirty"
fi

node "$LIB/config.mjs" validate "$CONFIG" >/dev/null || die "invalid config"
OBJECTIVE="$(node "$LIB/config.mjs" get "$CONFIG" objective)"
EVAL_CMD="$(node "$LIB/config.mjs" get "$CONFIG" eval_cmd)"
DIRECTION="$(node "$LIB/config.mjs" get "$CONFIG" direction)"
METRIC_TYPE="$(node "$LIB/config.mjs" get "$CONFIG" metric.type)"
MAX_ITER="$(node "$LIB/config.mjs" get "$CONFIG" budget.max_iterations)"
MAX_WALL="$(node "$LIB/config.mjs" get "$CONFIG" budget.max_wallclock_min)"
ITER_TIMEOUT="$(node "$LIB/config.mjs" get "$CONFIG" budget.per_iter_timeout_sec)"
NO_IMPROVE_LIMIT="$(node "$LIB/config.mjs" get "$CONFIG" stop_after_no_improve 2>/dev/null || echo 0)"
if [ "$METRIC_TYPE" = "regex" ]; then
  METRIC_ARG="$(node "$LIB/config.mjs" get "$CONFIG" metric.pattern)"
else
  METRIC_ARG="$(node "$LIB/config.mjs" get "$CONFIG" metric.path)"
fi
ARTIFACTS_NL="$(node "$LIB/config.mjs" get-array "$CONFIG" artifact)"

run_id="$(date +%Y%m%d-%H%M%S)-$$"
rundir="$repo/.autoresearch/$run_id"
wt="$rundir/worktree"
journal="$rundir/journal.md"
stop="$rundir/STOP"
evalout="$rundir/eval.out"
mkdir -p "$rundir"

grep -qxF '.autoresearch/' "$repo/.gitignore" 2>/dev/null || echo '.autoresearch/' >> "$repo/.gitignore"

git worktree add -b "autoresearch/$run_id" "$wt" HEAD >/dev/null 2>&1 || die "could not create worktree"

measure() {  # prints metric to stdout, or nothing on failure
  if ( cd "$wt" && run_timeout "$ITER_TIMEOUT" bash -c "$EVAL_CMD" ) >"$evalout" 2>&1; then
    if [ "$METRIC_TYPE" = "regex" ]; then
      node "$LIB/metric.mjs" extract-regex "$METRIC_ARG" "$evalout" 2>/dev/null || true
    else
      node "$LIB/metric.mjs" extract-json "$METRIC_ARG" "$evalout" 2>/dev/null || true
    fi
  fi
}

revert_worktree() { ( cd "$wt" && git checkout -- . >/dev/null 2>&1; git clean -fdq >/dev/null 2>&1 ); }

baseline="$(measure)"
[ -n "$baseline" ] || die "baseline evaluation failed (see $evalout)"
best="$baseline"

{
  echo "# autoresearch run $run_id"
  echo "objective: $OBJECTIVE"
  echo "direction: $DIRECTION | baseline: $baseline | budget: $MAX_ITER iters / $MAX_WALL min"
  echo
} > "$journal"

start="$(date +%s)"
iter=0
no_improve=0
proposer_cmd="${AUTORESEARCH_PROPOSER_CMD:-$LIB/proposer.sh}"

while [ "$iter" -lt "$MAX_ITER" ]; do
  [ -f "$stop" ] && { echo "STOP file present; stopping."; break; }
  elapsed_min=$(( ( $(date +%s) - start ) / 60 ))
  [ "$elapsed_min" -ge "$MAX_WALL" ] && { echo "wall-clock cap reached; stopping."; break; }
  if [ "$NO_IMPROVE_LIMIT" -gt 0 ] && [ "$no_improve" -ge "$NO_IMPROVE_LIMIT" ]; then
    echo "plateau ($no_improve consecutive no-improve); stopping."; break
  fi
  iter=$(( iter + 1 ))

  AR_OBJECTIVE="$OBJECTIVE" AR_BEST="$best" AR_DIRECTION="$DIRECTION" \
  AR_JOURNAL="$journal" AR_WORKTREE="$wt" AR_ARTIFACTS="$ARTIFACTS_NL" \
    "$proposer_cmd" >>"$rundir/proposer.log" 2>&1 || true

  changed="$(cd "$wt" && git status --porcelain | sed 's/^...//')"
  if [ -z "$changed" ]; then
    printf '## iter %s — REVERTED (no change)\n\n' "$iter" >> "$journal"
    no_improve=$(( no_improve + 1 )); continue
  fi

  if ! printf '%s\n' "$changed" | node "$LIB/scope.mjs" "$ARTIFACTS_NL"; then
    revert_worktree
    printf '## iter %s — REVERTED (out-of-scope)\n\n' "$iter" >> "$journal"
    no_improve=$(( no_improve + 1 )); continue
  fi

  metric="$(measure)"
  if [ -z "$metric" ]; then
    revert_worktree
    printf '## iter %s — REVERTED (eval failed/timeout)\n\n' "$iter" >> "$journal"
    no_improve=$(( no_improve + 1 )); continue
  fi

  if node "$LIB/metric.mjs" improved "$metric" "$best" "$DIRECTION"; then
    ( cd "$wt" && git add -A && git commit -q -m "autoresearch: $metric (was $best) [iter $iter]" )
    sha="$(cd "$wt" && git rev-parse --short HEAD)"
    printf '## iter %s — KEPT  (%s → %s)  commit: %s\n\n' "$iter" "$best" "$metric" "$sha" >> "$journal"
    best="$metric"; no_improve=0
  else
    revert_worktree
    printf '## iter %s — REVERTED  (%s vs best %s)\n\n' "$iter" "$metric" "$best" >> "$journal"
    no_improve=$(( no_improve + 1 ))
  fi
done

{
  echo "## summary"
  echo "baseline: $baseline -> best: $best | iterations: $iter"
} >> "$journal"

echo "autoresearch done. best=$best (baseline=$baseline) after $iter iters."
echo "branch:  autoresearch/$run_id"
echo "journal: $journal"
echo "merge:   git merge autoresearch/$run_id"
echo "discard: git worktree remove \"$wt\" && git branch -D autoresearch/$run_id"
```

- [ ] **Step 4: Run the integration test to verify it passes**

Run: `bash v7/plugins/autoresearch/tests/harness.test.sh`
Expected: `ALL PASS` — iter1 KEPT, iter2 REVERTED (worse), iter3 REVERTED (out-of-scope), worktree clean, out-of-scope file removed.

- [ ] **Step 5: shellcheck the harness**

Run: `shellcheck v7/plugins/autoresearch/scripts/autoresearch.sh v7/plugins/autoresearch/tests/harness.test.sh`
Expected: no errors. Fix any warnings inline (quote expansions, etc.).

- [ ] **Step 6: Commit**

```bash
git add v7/plugins/autoresearch/scripts/autoresearch.sh v7/plugins/autoresearch/tests/harness.test.sh
git commit -m "feat(v7): autoresearch harness core (loop + accept/revert) with mock-proposer test"
```

---

## Task 6: Harness lifecycle — budget caps, STOP file, plateau, summary

Task 5 already implements caps; this task adds focused tests that pin the lifecycle
behavior so a reviewer can reject lifecycle bugs independently.

**Files:**
- Modify: `v7/plugins/autoresearch/scripts/autoresearch.sh` (only if a test reveals a gap)
- Test: `v7/plugins/autoresearch/tests/lifecycle.test.sh`

**Interfaces:**
- Consumes: `autoresearch.sh` from Task 5.
- Produces: no new public interface; locks budget/STOP/plateau semantics.

- [ ] **Step 1: Write the failing test**

`v7/plugins/autoresearch/tests/lifecycle.test.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
HARNESS="$(cd "$(dirname "$0")/.." && pwd)/scripts/autoresearch.sh"
fails=0
assert() { if eval "$2"; then echo "ok - $1"; else echo "NOT ok - $1"; fails=$((fails+1)); fi; }

mkrepo() {
  TMP="$(mktemp -d)"; cd "$TMP"
  git init -q && git config user.email t@t && git config user.name t
  echo "value = 0" > knob.txt
  printf '#!/usr/bin/env bash\nv=$(grep -oE "[0-9]+" knob.txt|head -1); echo "score=${v:-0}"\n' > eval.sh
  chmod +x eval.sh
  git add -A && git commit -qm init
}
# a proposer that never improves (always writes the same worse value) -> all reverts
neverimprove() {
  printf '#!/usr/bin/env bash\ncd "$AR_WORKTREE"; echo "value = 0" > knob.txt\n' > "$TMP/mock.sh"
  chmod +x "$TMP/mock.sh"
}

# (a) max_iterations cap: 2 iters max, proposer always no-net-change
mkrepo
cat > autoresearch.config.json <<'EOF'
{ "objective":"x","artifact":["knob.txt"],"eval_cmd":"bash eval.sh",
  "metric":{"type":"regex","pattern":"score=([0-9]+)"},"direction":"maximize",
  "budget":{"max_iterations":2,"max_wallclock_min":60,"per_iter_timeout_sec":30} }
EOF
neverimprove
AUTORESEARCH_PROPOSER_CMD="$TMP/mock.sh" bash "$HARNESS" >/dev/null 2>&1
j="$(ls .autoresearch/*/journal.md|head -1)"
assert "stops at max_iterations=2" "[ \"\$(grep -c '## iter' '$j')\" -eq 2 ]"
rm -rf "$TMP"

# (b) STOP file halts before the first iteration completes the loop budget
mkrepo
cat > autoresearch.config.json <<'EOF'
{ "objective":"x","artifact":["knob.txt"],"eval_cmd":"bash eval.sh",
  "metric":{"type":"regex","pattern":"score=([0-9]+)"},"direction":"maximize",
  "budget":{"max_iterations":50,"max_wallclock_min":60,"per_iter_timeout_sec":30},
  "stop_after_no_improve":3 }
EOF
neverimprove
AUTORESEARCH_PROPOSER_CMD="$TMP/mock.sh" bash "$HARNESS" >out.log 2>&1
j="$(ls .autoresearch/*/journal.md|head -1)"
assert "plateau stops after 3 no-improve" "[ \"\$(grep -c '## iter' '$j')\" -eq 3 ]"
assert "plateau message printed" "grep -q 'plateau' out.log"
assert "summary written" "grep -q '## summary' '$j'"
rm -rf "$TMP"

echo "---"; [ "$fails" -eq 0 ] && echo "ALL PASS" || { echo "$fails FAILED"; exit 1; }
```

- [ ] **Step 2: Run the test**

Run: `bash v7/plugins/autoresearch/tests/lifecycle.test.sh`
Expected: PASS if Task 5's caps are correct. If any assertion fails, fix `autoresearch.sh` (cap comparison, STOP/plateau ordering) until green — do not weaken the test.

- [ ] **Step 3: shellcheck**

Run: `shellcheck v7/plugins/autoresearch/tests/lifecycle.test.sh`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add v7/plugins/autoresearch/tests/lifecycle.test.sh v7/plugins/autoresearch/scripts/autoresearch.sh
git commit -m "test(v7): lock autoresearch budget/STOP/plateau lifecycle"
```

---

## Task 7: Prompt composition (`prompt.mjs`) + default proposer (`proposer.sh`)

**Files:**
- Create: `v7/plugins/autoresearch/scripts/lib/prompt.mjs`
- Create: `v7/plugins/autoresearch/scripts/lib/proposer.sh`
- Test: `v7/plugins/autoresearch/scripts/lib/prompt.test.mjs`

**Interfaces:**
- Consumes: env `AR_OBJECTIVE`, `AR_BEST`, `AR_DIRECTION`, `AR_ARTIFACTS`, `AR_JOURNAL`, `AR_WORKTREE`.
- Produces:
  - `buildPrompt({objective, best, direction, artifacts, journalTail}) -> string`
  - CLI `node prompt.mjs` reads the env vars + tails `AR_JOURNAL`, prints the prompt.
  - `proposer.sh` pipes that prompt into `claude -p` (cwd = worktree, `--permission-mode acceptEdits`).

- [ ] **Step 1: Write the failing test**

`v7/plugins/autoresearch/scripts/lib/prompt.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert';
import { buildPrompt } from './prompt.mjs';

test('prompt names objective, metric direction, current best, and artifact globs', () => {
  const p = buildPrompt({
    objective: 'make search faster', best: '134.0', direction: 'minimize',
    artifacts: ['src/search/**/*.ts'], journalTail: '## iter 1 — KEPT',
  });
  assert.match(p, /make search faster/);
  assert.match(p, /minimize/);
  assert.match(p, /134\.0/);
  assert.match(p, /src\/search\/\*\*\/\*\.ts/);
  assert.match(p, /## iter 1 — KEPT/);
});

test('prompt forbids eval/commit and limits to one change', () => {
  const p = buildPrompt({ objective: 'x', best: '0', direction: 'maximize', artifacts: ['a'], journalTail: '' });
  assert.match(p, /exactly one/i);
  assert.match(p, /do not run the eval/i);
  assert.match(p, /do not commit/i);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test v7/plugins/autoresearch/scripts/lib/prompt.test.mjs`
Expected: FAIL — cannot import from `./prompt.mjs`.

- [ ] **Step 3: Write `prompt.mjs`**

```js
import { readFileSync } from 'node:fs';

export function buildPrompt({ objective, best, direction, artifacts, journalTail }) {
  const globs = Array.isArray(artifacts) ? artifacts.join(', ') : String(artifacts).split('\n').join(', ');
  return [
    `You are one iteration of an autoresearch optimization loop.`,
    `OBJECTIVE: ${objective}`,
    `METRIC DIRECTION: ${direction} (current best: ${best}).`,
    `EDITABLE FILES (globs): ${globs}`,
    ``,
    `Recent experiment journal (most recent last):`,
    journalTail || '(none yet)',
    ``,
    `RULES:`,
    `- Propose and apply EXACTLY ONE change to the editable files that you believe will`,
    `  improve the metric. Keep it small and reversible.`,
    `- Do NOT repeat an idea the journal shows was already reverted.`,
    `- Edit ONLY files matching the globs above. Anything else is auto-reverted.`,
    `- Do NOT run the eval. Do NOT commit. The harness does both.`,
    `- End by writing a one-line summary of the change you made.`,
  ].join('\n');
}

if (import.meta.url === `file://${process.argv[1]}`) {
  let journalTail = '';
  try {
    const all = readFileSync(process.env.AR_JOURNAL || '', 'utf8').split('\n');
    journalTail = all.slice(-40).join('\n');
  } catch { /* no journal yet */ }
  process.stdout.write(buildPrompt({
    objective: process.env.AR_OBJECTIVE || '',
    best: process.env.AR_BEST || '',
    direction: process.env.AR_DIRECTION || '',
    artifacts: process.env.AR_ARTIFACTS || '',
    journalTail,
  }));
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test v7/plugins/autoresearch/scripts/lib/prompt.test.mjs`
Expected: PASS (2 tests).

- [ ] **Step 5: Write the default proposer**

`v7/plugins/autoresearch/scripts/lib/proposer.sh`:

```bash
#!/usr/bin/env bash
# Default proposer: build the prompt and run a fresh headless `claude -p` in the worktree.
# Overridable in tests via AUTORESEARCH_PROPOSER_CMD.
set -uo pipefail
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v claude >/dev/null 2>&1 || { echo "proposer: 'claude' CLI not found" >&2; exit 127; }

prompt="$(node "$LIB/prompt.mjs")"

cd "$AR_WORKTREE" || exit 1
# Edits only; never let the proposer run bash or commit.
printf '%s' "$prompt" | claude -p --permission-mode acceptEdits
```

- [ ] **Step 6: shellcheck the proposer**

Run: `shellcheck v7/plugins/autoresearch/scripts/lib/proposer.sh`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add v7/plugins/autoresearch/scripts/lib/prompt.mjs v7/plugins/autoresearch/scripts/lib/prompt.test.mjs v7/plugins/autoresearch/scripts/lib/proposer.sh
git commit -m "feat(v7): autoresearch prompt composition + default claude -p proposer"
```

---

## Task 8: The proposer skill (`autoresearch-loop/SKILL.md`)

**Files:**
- Create: `v7/plugins/autoresearch/skills/autoresearch-loop/SKILL.md`

**Interfaces:**
- Produces: the skill loaded by each proposer invocation and consulted when a human sets up a run.

- [ ] **Step 1: Write the SKILL.md**

```markdown
---
name: autoresearch-loop
description: Use when proposing a single change inside an autoresearch optimization run, or when helping a user configure one. Governs how to read the journal, propose one high-information change, stay in scope, and never eval or commit.
tier: v7
inspiration: "Karpathy — AutoResearch (keep-or-revert agent loop, open-sourced 2026-03-07)"
---

# autoresearch-loop

You are one iteration of a keep-or-revert optimization loop. A bash harness owns the
truth: it runs the evaluation, compares the metric, and commits or reverts. **You only
propose and apply one change.**

## Each iteration

1. **Read the journal tail** (`AR_JOURNAL`). It is your only memory of prior iterations —
   what was tried, the resulting metric, and whether it was KEPT or REVERTED.
2. **Pick one high-information change** toward the objective. Prefer the change most likely
   to move the metric. Do not repeat anything the journal shows was reverted; build on what
   was kept.
3. **Apply exactly one change** to files matching the artifact globs (`AR_ARTIFACTS`).
   Keep it small and reversible.
4. **Write a one-line rationale** as your final output — it is recorded in the journal.

## Hard rules

- Edit ONLY files in the artifact set. Edits outside it are auto-reverted (wasted iteration).
- Do NOT run the evaluation. Do NOT commit. The harness does both, deterministically.
- One concern per iteration — a large diff is harder to attribute to a metric change.

## Helping a human configure a run

When asked to set up autoresearch, produce an `autoresearch.config.json`:
- `artifact`: the narrowest globs that contain the thing worth changing.
- `eval_cmd`: a command that exits 0 and prints the metric, fast enough to run many times.
- `metric`: a `regex` capture group or a `json` path into the eval's output.
- `direction`: `minimize` or `maximize`.
- `budget`: start conservative (e.g. 10 iterations) for the first run.

## Provenance

Andrej Karpathy, **AutoResearch**, open-sourced 2026-03-07 — a ~630-line nanochat-derived
tool where an agent runs autonomous, time-boxed ML experiments and keeps a change only if
validation loss improves, else `git revert`s. This skill ports the proposer's discipline
from that loop; the v7 harness ports the judge.

## Boundaries

- The harness, not this skill, enforces accept/reject — see `scripts/autoresearch.sh`.
- Related v4 ideas: `cognitive-prosthetics` (journal = amnesia prosthetic),
  `fast-verify-loop` (fast evaluator), `autonomy-slider` (unattended-in-sandbox autonomy).
```

- [ ] **Step 2: Run skill-auditor**

Dispatch the `skill-auditor` agent on `v7/plugins/autoresearch/skills/autoresearch-loop/SKILL.md`.
Expected: passes. Fix any reported issues inline (description must say WHEN; frontmatter complete).

- [ ] **Step 3: Commit**

```bash
git add v7/plugins/autoresearch/skills/autoresearch-loop/SKILL.md
git commit -m "feat(v7): autoresearch-loop proposer skill"
```

---

## Task 9: The `/autoresearch` command

**Files:**
- Create: `v7/plugins/autoresearch/commands/autoresearch.md`

**Interfaces:**
- Consumes: `scripts/autoresearch.sh`, `scripts/lib/config.mjs`.
- Produces: the `/autoresearch` slash command.

- [ ] **Step 1: Write the command**

`v7/plugins/autoresearch/commands/autoresearch.md`:

```markdown
---
description: Configure and launch a Karpathy-style keep-or-revert optimization run.
---

# /autoresearch

Set up and start an autoresearch run in the current repo.

## Steps

1. **Find or create config.** If `autoresearch.config.json` exists, validate it:
   `node ${CLAUDE_PLUGIN_ROOT}/scripts/lib/config.mjs validate autoresearch.config.json`.
   If it does not exist, interview the user for: the editable file globs (`artifact`),
   the command that measures success (`eval_cmd`), how to read the number (`metric`:
   regex capture group or json path), `direction` (minimize/maximize), and a starting
   `budget` (default `{max_iterations:10, max_wallclock_min:120, per_iter_timeout_sec:120}`).
   Write the JSON and validate it.

2. **Confirm safety.** Ensure the working tree is clean (the harness refuses a dirty tree
   unless `--allow-dirty`). Confirm `.autoresearch/` will be git-ignored (the harness adds
   it automatically).

3. **Launch.** Run:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/autoresearch.sh autoresearch.config.json`
   Each iteration spawns a fresh `claude -p`. Edits, evaluation, and accept/revert all
   happen in an isolated worktree on branch `autoresearch/<run-id>`.

4. **Report.** When it finishes, surface the journal path, the baseline → best metric, and
   the printed `git merge` / `git worktree remove` commands. Do not merge or push
   automatically — the user decides.

## Notes

- Stop early: `touch .autoresearch/<run-id>/STOP`.
- The harness owns accept/reject; the proposer only edits files (see the
  `autoresearch-loop` skill).
```

- [ ] **Step 2: Verify structure**

Run: `node -e "const fs=require('fs');const s=fs.readFileSync('v7/plugins/autoresearch/commands/autoresearch.md','utf8');if(!/^---[\s\S]*description:[\s\S]*---/.test(s))throw new Error('missing frontmatter');console.log('OK')"`
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add v7/plugins/autoresearch/commands/autoresearch.md
git commit -m "feat(v7): /autoresearch command"
```

---

## Task 10: Deterministic `hillclimb` example + end-to-end proof

**Files:**
- Create: `v7/plugins/autoresearch/examples/hillclimb/knob.py`
- Create: `v7/plugins/autoresearch/examples/hillclimb/eval.sh`
- Create: `v7/plugins/autoresearch/examples/hillclimb/autoresearch.config.json`
- Create: `v7/plugins/autoresearch/examples/hillclimb/README.md`
- Test: `v7/plugins/autoresearch/tests/example.test.sh`

**Interfaces:**
- Consumes: `autoresearch.sh`.
- Produces: a runnable example whose metric the loop must improve.

- [ ] **Step 1: Write the example files**

`examples/hillclimb/knob.py`:

```python
# autoresearch will edit VALUE to minimize abs(VALUE - 0.7)
VALUE = 0.0
```

`examples/hillclimb/eval.sh`:

```bash
#!/usr/bin/env bash
# Prints metric=<distance from target 0.7>. Lower is better.
val="$(python3 -c 'import knob; print(knob.VALUE)')"
python3 -c "print('metric=%.6f' % abs(${val} - 0.7))"
```

`examples/hillclimb/autoresearch.config.json`:

```json
{
  "objective": "Set VALUE in knob.py as close to 0.7 as possible.",
  "artifact": ["knob.py"],
  "eval_cmd": "bash eval.sh",
  "metric": { "type": "regex", "pattern": "metric=([0-9.]+)" },
  "direction": "minimize",
  "budget": { "max_iterations": 12, "max_wallclock_min": 30, "per_iter_timeout_sec": 30 },
  "stop_after_no_improve": 5
}
```

`examples/hillclimb/README.md`:

```markdown
# hillclimb example

A dependency-light demo (Python 3 only) proving the loop end-to-end. The proposer edits
`VALUE` in `knob.py`; the metric is the distance from 0.7; lower is better.

Real run (uses `claude -p`):

\`\`\`bash
cd examples/hillclimb && git init -q && git add -A && git commit -qm init
bash ../../scripts/autoresearch.sh autoresearch.config.json
\`\`\`

The journal under `.autoresearch/<run-id>/journal.md` should show the metric improving
toward 0, with KEPT commits only when it improves.
```

- [ ] **Step 2: Write the deterministic test (smart mock proposer)**

`v7/plugins/autoresearch/tests/example.test.sh`:

```bash
#!/usr/bin/env bash
# Proves the loop drives the hillclimb metric down using a deterministic mock that
# nudges VALUE toward the target. (No LLM; proves the engine + example wiring.)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HARNESS="$ROOT/scripts/autoresearch.sh"
command -v python3 >/dev/null 2>&1 || { echo "skip - python3 not installed"; exit 0; }
fails=0
assert() { if eval "$2"; then echo "ok - $1"; else echo "NOT ok - $1"; fails=$((fails+1)); fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$ROOT/examples/hillclimb/"* "$TMP/"
cd "$TMP"
git init -q && git config user.email t@t && git config user.name t
git add -A && git commit -qm init

# mock: move VALUE halfway toward 0.7 each call (monotonic improvement)
cat > mock.sh <<'EOF'
#!/usr/bin/env bash
cd "$AR_WORKTREE" || exit 1
cur="$(python3 -c 'import knob; print(knob.VALUE)')"
next="$(python3 -c "print(${cur} + (0.7 - ${cur})/2)")"
printf 'VALUE = %s\n' "$next" > knob.py
EOF
chmod +x mock.sh

AUTORESEARCH_PROPOSER_CMD="$TMP/mock.sh" bash "$HARNESS" autoresearch.config.json >run.log 2>&1
j="$(ls .autoresearch/*/journal.md | head -1)"
assert "journal exists" "[ -f '$j' ]"
assert "at least one KEPT" "grep -q 'KEPT' '$j'"
# final best strictly better than baseline 0.7 (baseline VALUE=0 -> metric=0.7)
best="$(grep '^baseline:' "$j" >/dev/null 2>&1; grep -oE 'best: [0-9.]+' '$j' | tail -1 | grep -oE '[0-9.]+')"
assert "best metric < baseline 0.7" "python3 -c \"import sys; sys.exit(0 if ${best:-1} < 0.7 else 1)\""

echo "---"; [ "$fails" -eq 0 ] && echo "ALL PASS" || { echo "$fails FAILED"; exit 1; }
```

- [ ] **Step 3: Run the example test**

Run: `bash v7/plugins/autoresearch/tests/example.test.sh`
Expected: `ALL PASS` (or `skip` if python3 is absent). If it fails, the engine or example
wiring is wrong — fix and re-run.

- [ ] **Step 4: shellcheck**

Run: `shellcheck v7/plugins/autoresearch/examples/hillclimb/eval.sh v7/plugins/autoresearch/tests/example.test.sh`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add v7/plugins/autoresearch/examples v7/plugins/autoresearch/tests/example.test.sh
git commit -m "feat(v7): hillclimb example + deterministic end-to-end proof"
```

---

## Task 11: Final verification + plugin validation

**Files:**
- Modify: none expected (fix-ups only if a gate fails)

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Run all unit tests**

Run: `node --test v7/plugins/autoresearch/scripts/lib/ v7/plugins/autoresearch/.claude-plugin/`
Expected: all suites PASS.

- [ ] **Step 2: Run all integration tests**

Run:
```bash
bash v7/plugins/autoresearch/tests/harness.test.sh
bash v7/plugins/autoresearch/tests/lifecycle.test.sh
bash v7/plugins/autoresearch/tests/example.test.sh
```
Expected: each prints `ALL PASS` (example may `skip` without python3).

- [ ] **Step 3: shellcheck everything**

Run: `shellcheck v7/plugins/autoresearch/scripts/autoresearch.sh v7/plugins/autoresearch/scripts/lib/proposer.sh v7/plugins/autoresearch/tests/*.sh v7/plugins/autoresearch/examples/hillclimb/eval.sh`
Expected: no errors.

- [ ] **Step 4: Validate the plugin and skill**

Dispatch `plugin-validator` on `v7/plugins/autoresearch` and `skill-auditor` on the
`autoresearch-loop` skill. Fix any findings inline.

- [ ] **Step 5: Make scripts executable + final commit**

```bash
chmod +x v7/plugins/autoresearch/scripts/autoresearch.sh v7/plugins/autoresearch/scripts/lib/proposer.sh v7/plugins/autoresearch/examples/hillclimb/eval.sh v7/plugins/autoresearch/tests/*.sh
git add -A v7/plugins/autoresearch v7/README.md
git commit -m "chore(v7): finalize autoresearch plugin (perms + verification gates green)"
```

- [ ] **Step 6 (optional, ask the user): add the v7 tier row to repo CLAUDE.md and MANIFEST.md**

Per the v6 precedent the CLAUDE.md row is committed only if the user wants it. If yes, add
the `v7/` row from the spec's "Tier definition" to the tier table in `CLAUDE.md`, and add a
v7 entry to `MANIFEST.md`. Commit separately:

```bash
git add CLAUDE.md MANIFEST.md
git commit -m "docs(v7): register v7 tier in CLAUDE.md + MANIFEST"
```

---

## Self-Review

**Spec coverage:**

| Spec element | Task |
|---|---|
| v7 tier folder + contract | 1 (README), 11 step 6 (CLAUDE.md row, optional) |
| Plugin layout + manifest | 1 |
| Config contract (all fields) | 2 |
| Metric extraction (regex/json) + direction | 3 |
| Artifact-set enforcement (auto-revert out-of-scope) | 4 (matcher), 5 (wired + tested) |
| Worktree isolation + baseline + clean-tree precondition | 5 |
| Loop: propose→eval→compare→accept/revert | 5 |
| Journal as audit + memory | 5 (writes), 7 (read into prompt) |
| Budget caps, STOP file, plateau, teardown summary | 5 (impl), 6 (locked) |
| Fresh `claude -p` proposer, injectable, edits-only | 7 |
| Proposer skill (tier/inspiration/provenance) | 8 |
| `/autoresearch` command | 9 |
| Deterministic example (out-of-the-box proof) | 10 |
| Mock-proposer invariant test | 5 |
| shellcheck + node --test + plugin-validator + skill-auditor | 5, 6, 10, 11 |

No spec element is unaddressed.

**Placeholder scan:** No TBD/TODO; every code step contains complete, runnable content.

**Type/name consistency:** `config.mjs` exposes `validate|get|get-array`; the harness calls
exactly those. `metric.mjs` exposes `extract-regex|extract-json|improved`; the harness calls
exactly those. `scope.mjs` reads globs from argv[2] + changed files from stdin; the harness
pipes `$changed` and passes `$ARTIFACTS_NL` — consistent. Proposer env var names
(`AR_OBJECTIVE`, `AR_BEST`, `AR_DIRECTION`, `AR_JOURNAL`, `AR_WORKTREE`, `AR_ARTIFACTS`) are
identical in the harness (Task 5), `prompt.mjs`/`proposer.sh` (Task 7), and the mock
proposers (Tasks 5, 6, 10).
