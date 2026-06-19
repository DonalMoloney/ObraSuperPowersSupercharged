import { fileURLToPath } from 'node:url';

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

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const globs = (process.argv[2] || '').split('\n').filter(Boolean);
  let stdin = '';
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', (d) => (stdin += d));
  process.stdin.on('end', () => {
    const changed = stdin.split('\n').map((s) => s.trim()).filter(Boolean);
    process.exit(allInScope(changed, globs) ? 0 : 1);
  });
}
