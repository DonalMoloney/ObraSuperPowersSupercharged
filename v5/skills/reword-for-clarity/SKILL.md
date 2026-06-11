---
name: reword-for-clarity
description: Paste any skill/doc section → plain-English rewrite with zero meaning change
---

# Reword for Clarity

> Take any confusing text and rewrite it in plain English without changing the meaning.

## When to use this skill

- A skill's steps are hard to follow
- Documentation uses jargon that obscures the core idea
- You want to simplify a section but preserve all technical intent
- Someone says "I don't understand what this means"

## How it works

1. You paste the text (skill section, doc paragraph, etc.)
2. The skill rewrites it in simpler, clearer language
3. Every technical detail survives — only the wording changes
4. You review and accept, or ask for another pass with a specific concern

## Composition

**Calls:** None (standalone)
**Called by:** `writing-skills`, `unify-skill-style`

## Example

**Before:**
"Leverage adversarial verification by orchestrating independent skeptical perspectives across parallel agents to refute plausible but unsound findings."

**After:**
"Have multiple agents each try to prove the finding wrong. If most of them succeed, discard the finding."

## Pitfalls

- If it changes technical meaning, restart with more context
- Don't use jargon in the rewrite (that defeats the purpose)
- Preserve all constraints and conditions from the original

---

**Status:** Stub — outline complete, implementation pending
