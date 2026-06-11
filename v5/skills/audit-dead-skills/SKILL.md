---
name: audit-dead-skills
description: Scan skills/ for orphaned SKILL.md files with no invocations or references
---

# Audit Dead Skills

> Find skills nobody uses and flag them for retirement.

## When to use this skill

- You suspect some skills are dead weight
- You want to clean up the skill catalog before a release
- A skill was deprecated but never formally removed
- You need to understand skill usage patterns

## How it works

1. The skill scans all `skills/*/SKILL.md` files
2. For each skill, it checks:
   - Invocation telemetry (if available from `analyse-routing`)
   - References in `CLAUDE.md`, `AGENTS.md`, and other skills
   - Git commit history (was it touched in the last 6 months?)
3. Skills with zero references and zero invocations are flagged
4. Output: a retire/keep recommendation with reasoning
5. You review and decide: delete, archive, or revive

## Composition

**Calls:** `analyse-routing` (telemetry)
**Called by:** `cross-skill-health-check`, gardening workflows

## Example

**Orphaned:**
- `try-different-approach` — never invoked, replaced by `see-big-picture`
- `legacy-auth-check` — removed from CLAUDE.md but folder still exists

**Kept (active):**
- `verify-before-done` — 15 invocations last month
- `proof-gate` — referenced in 8 other skills

## Pitfalls

- A skill with zero invocations might be too niche, not dead (ask before deleting)
- Telemetry only covers recent sessions (old skills may look dead if users downgraded)
- Don't assume low usage = low impact (some skills are critical but infrequent)

---

**Status:** Stub — outline complete, implementation pending
