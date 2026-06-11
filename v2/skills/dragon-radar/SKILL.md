---
name: dragon-radar
description: Use before claiming a multi-site change complete — when a fix, rename, or refactor must touch every instance of a pattern, the radar enumerates all occurrences first, tracks each to resolution, and re-sweeps to zero before done is allowed.
author: Donal Moloney
tier: v2
supports: [verification-before-completion, systematic-debugging]
type: technique
chains-to: verification-before-completion
pairs-with: zenkai-boost
---

## Not this skill if

- The change is single-site by construction (one function, one call site) — just verify it.
- You can't name the pattern you're hunting — define it first; a radar needs a signature to track.

# Dragon Radar

## Purpose

There are always seven dragon balls — the radar's job is to show the count so you know when you have them all. Multi-site changes fail by under-enumeration: the fix lands on the four obvious instances and the fifth ships broken. Enumerate first, fix second, re-sweep to zero.

Supports v1 **verification-before-completion** (the zero-result re-sweep is the completion evidence) and v1 **systematic-debugging** (root-cause classes often have multiple instances; the radar finds them all).

## Triggers

**Use when:**
- Renames, signature changes, API migrations — anything "change every place that does X"
- A bug's root cause is a *pattern* (misused API, copied snippet), not a single line
- Reviewing whether a "fixed everywhere" claim is actually everywhere

**Don't use when:**
- The change is provably single-site
- The pattern can't yet be expressed as something searchable

## The sweep

### 1. Define the signature

What exactly identifies an occurrence? Write it down before searching — literal string, regex, AST shape, or "calls to f with 2 args".

### 2. Multi-band scan

One grep is one band; dragon balls hide in others. Sweep every band that applies:

| Band | Finds |
|---|---|
| Literal grep | Direct uses |
| Synonyms & aliases | Re-exports, wrapper names, deprecated spellings |
| Dynamic construction | String-built names, reflection, config keys |
| Non-code | Docs, configs, CI scripts, templates, tests |

### 3. The ledger

List every hit with file:line. For each: **fixed**, or **excluded** with a one-line reason. Silent omission is the failure mode the radar exists to prevent.

### 4. Re-sweep to zero

After the changes, run the same scans again. Expected result: zero unhandled occurrences. A re-sweep that finds a new hit goes back to step 3.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Fix-as-you-find without enumerating | Build the full ledger first, then fix |
| One literal grep declared exhaustive | Sweep synonyms, dynamic construction, and non-code bands |
| Hits skipped without a note | Every ledger row is fixed or excluded-with-reason |
| Claiming done from memory of the ledger | Re-sweep; the radar, not recollection, says all seven are found |

## After

Attach the ledger and the zero-result re-sweep output as evidence to v1 **verification-before-completion**. If the occurrences came from a bug class, v2 **zenkai-boost**'s sibling sweep is this skill in miniature — add the regression test while you're there.
