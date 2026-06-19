import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

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

if (process.argv[1] === fileURLToPath(import.meta.url)) {
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
