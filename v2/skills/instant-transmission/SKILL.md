---
name: instant-transmission
description: Use when a failure's location in the code is unknown — locks onto a reproducible failure signal and teleports to the faulty commit or line via signature grep, git bisect, blame, and binary-search instrumentation before the full debugging loop begins.
author: Donal Moloney
tier: v2
supports: [systematic-debugging]
type: technique
chains-to: systematic-debugging
pairs-with: loop-until-green
---

## Not this skill if

- The fault location is already known — go straight to v1 **systematic-debugging**.
- There is no reproducible failure signal — build a repro first; no ki signature, no teleport.

# Instant Transmission

## Purpose

Goku can't teleport without a ki signature to lock onto. Likewise: localization needs a reproducible failure signal, and with one you can jump straight to the fault instead of wandering the codebase. This is the cheap localization pass that runs *before* v1 systematic-debugging's hypothesis loop, so hypotheses start from a located fault, not a whole repo.

Supports v1 **systematic-debugging** — enters its workflow at the hypothesis phase with the fault already localized.

## Triggers

**Use when:**
- "It's broken somewhere" — failing behavior, unknown location
- A regression appeared and you don't know which change caused it
- Stack traces point into framework code, not yours

**Don't use when:**
- The faulty line/commit is already identified
- The failure can't be reproduced on demand

## Prerequisite: the ki signature

A command (or script) that deterministically shows the failure, plus the exact failure text. If the failure is intermittent, tighten the repro first (fixed seed, pinned data, repeated runs) until it fires reliably. **No repro = no teleport.**

## The localization ladder

Run the cheapest rung first; stop at the first rung that lands.

| Rung | When | How |
|---|---|---|
| 1. **Signature grep** | An error message exists | Grep the exact message/error code in the codebase; the throw site bounds the search |
| 2. **Bisect** | It worked before | `git bisect run <repro-script>` — script exits 0 on pass, non-zero on fail; lands on the exact commit |
| 3. **Blame the window** | Breakage is recent, bisect impractical | `git diff <last-good>..HEAD -- <suspect-paths>`, then `git blame` the implicated lines |
| 4. **Binary-search instrumentation** | Nothing above lands | Log at the midpoint of the suspect path; halve toward the fault each run |

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| Teleporting without a repro | Build the ki signature first |
| Bisecting with a flaky repro | Make the repro script deterministic, or bisect lands on noise |
| Reading the whole module "to understand it" | Run the ladder; read only what the landed rung implicates |
| Treating the landed location as the root cause | It's the *location* — hand it to v1 **systematic-debugging** for cause analysis |

## After

Hand off to v1 **systematic-debugging** at its hypothesis phase with: the ki signature (repro command + failure text), the rung that landed, and the localized commit/file/line.
