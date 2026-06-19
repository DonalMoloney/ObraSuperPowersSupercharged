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
