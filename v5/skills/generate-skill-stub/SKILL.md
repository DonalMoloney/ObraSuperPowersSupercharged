---
name: generate-skill-stub
description: One-line description → skeleton SKILL.md with all mandatory sections pre-filled
---

# Generate Skill Stub

> Turn an idea into a ready-to-edit skill scaffold in seconds.

## When to use this skill

- You have a skill idea but don't know where to start
- You want a skeleton with all mandatory sections pre-filled
- You're tired of copy-pasting the same SKILL.md structure
- You need frontmatter, "When to use," and "How it works" without thinking

## How it works

1. You provide a one-liner: "Challenge assumptions in running code"
2. The skill generates a complete SKILL.md skeleton with:
   - Frontmatter (name, description, author, track)
   - All required sections (When/How/Composition/Example/Pitfalls)
   - Placeholder text you fill in
   - Proper markdown formatting
3. You edit the placeholders and you're done
4. Output: `skills/{{name}}/SKILL.md` ready to commit

## Composition

**Calls:** None (deterministic)
**Called by:** `writing-skills`, skill authors

## Example

**Input:**
```
Challenge assumptions in running code
```

**Output:**
```
---
name: challenge-implementation
description: Probe running code for hidden assumptions
---

# Challenge Implementation

> {{PASTE_YOUR_THESIS}}

## When to use this skill

- {{USE_CASE_1}}
- {{USE_CASE_2}}

[... rest of sections with placeholders ...]
```

## Pitfalls

- Placeholder text is not final — you MUST customize every section
- Stub generation doesn't validate skill fit (use `writing-skills` to refine)
- Don't ship a skill that's just placeholders (run `factory-templates` quality check first)

---

**Status:** Stub — outline complete, implementation pending
