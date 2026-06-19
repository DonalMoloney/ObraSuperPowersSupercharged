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
