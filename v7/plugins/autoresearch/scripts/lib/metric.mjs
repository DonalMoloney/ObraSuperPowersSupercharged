import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

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

if (process.argv[1] === fileURLToPath(import.meta.url)) {
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
