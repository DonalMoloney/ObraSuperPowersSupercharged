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
