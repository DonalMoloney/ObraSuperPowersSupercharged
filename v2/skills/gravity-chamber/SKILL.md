---
name: gravity-chamber
description: Use when the happy-path suite passes but confidence is low — trains the code under increased gravity by escalating test rigor in graded levels (edge matrix, repetition for flakes, property-based and adversarial inputs).
author: Donal Moloney
tier: v2
supports: [test-driven-development, verification-before-completion]
type: technique
chains-to: verification-before-completion
pairs-with: loop-until-green
---

## Not this skill if

- The basic suite isn't green yet — get to 1g first via v1 **test-driven-development** and v2 **loop-until-green**.
- The code is a throwaway spike — match rigor to lifespan.

# Gravity Chamber

## Purpose

Training at 1g proves you can stand. Code that has only seen its happy-path suite has only stood at 1g. The chamber raises gravity in graded levels until the code has survived the conditions production will actually apply — and each level is a deliberate, recorded choice, not vague "more testing".

Supports v1 **test-driven-development** (each level's failures become new red tests) and v1 **verification-before-completion** (the gravity level reached is part of the completion evidence).

## Triggers

**Use when:**
- The suite is green but the change touches parsing, money, time, concurrency, or user input
- "It works on my input" needs to become "it works"
- Deciding how much testing is enough for a risky change

**Don't use when:**
- Still red at 1g
- Rigor would exceed the code's lifespan or blast radius

## Gravity levels

Climb in order; stop at the level the change's risk justifies. Record the level reached.

| Level | Training | Catches |
|---|---|---|
| **1g** | Happy-path suite green | Basic correctness |
| **10g** | Edge matrix: empty, one, many, max, malformed, unicode, negative, zero, boundary ±1 | Off-by-ones, unhandled shapes |
| **50g** | Repetition: run N times, shuffled order, parallel | Flakes, ordering deps, shared state |
| **100g** | Property-based / fuzz: invariants over generated inputs | The cases you couldn't think of |
| **150g** | Adversarial: inputs crafted to break assumptions (injection shapes, huge payloads, concurrent mutation) | Security-adjacent and hostile conditions |

Every failure at any level: write it as a permanent red test (v1 **test-driven-development**), fix, re-run the level.

## Pitfalls

| ❌ Anti-pattern | ✅ Correct |
|---|---|
| "Added more tests" with no level stated | Name the level: "trained to 50g" |
| Jumping to fuzzing while edge cases are unwritten | Climb in order — cheap levels catch most failures |
| Chamber failures fixed without a captured test | Every failure becomes a permanent suite member |
| 150g on a log-message change | Match the level to risk and lifespan |

## After

Report the gravity level reached and the failures captured as tests to v1 **verification-before-completion**. New tests stay in the suite permanently — the chamber's point is that the next fighter trains at your level by default.
