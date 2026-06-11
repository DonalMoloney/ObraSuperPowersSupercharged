---
name: challenge-implementation
description: Probe running code for hidden assumptions one question at a time
---

# Challenge Implementation

> Like `challenge-spec` but for shipped code — surface hidden assumptions through probing questions.

## When to use this skill

- You're reviewing existing code and want to expose unstated assumptions
- A feature seems to work but you suspect fragile coupling
- You want to understand the author's mental model before refactoring
- Testing reveals edge cases the implementation doesn't handle

## How it works

1. You select a function, component, or subsystem
2. The skill asks one probing question at a time about design choices
3. Each answer reveals what the code assumes about inputs, invariants, or context
4. When patterns emerge, the skill bundles them into a "hidden assumptions" list
5. You can then decide: refactor, add guards, or document the assumptions

## Composition

**Calls:** `find-original-reason`
**Called by:** `improve-codebase-architecture`, `refactor-safely`

## Example

**Code:** A payment processor that only handles USD

**Question 1:** "What happens if someone passes EUR?"
→ Reveals assumption: currency is always USD, never validated

**Question 2:** "Why does the fee calculation assume a flat 2.5%?"
→ Reveals assumption: fee model is static, can't change per region/customer

## Pitfalls

- Don't ask questions you can answer from the code yourself first
- Stop asking when you've found 3–5 core assumptions (diminishing returns)
- Distinguish between "intentional design choices" and "accidental gaps"

---

**Status:** Stub — outline complete, implementation pending
