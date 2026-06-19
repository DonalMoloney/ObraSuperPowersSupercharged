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
