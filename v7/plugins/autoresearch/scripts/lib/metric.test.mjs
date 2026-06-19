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
