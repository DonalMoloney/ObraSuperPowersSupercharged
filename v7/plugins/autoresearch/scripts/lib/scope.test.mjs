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
