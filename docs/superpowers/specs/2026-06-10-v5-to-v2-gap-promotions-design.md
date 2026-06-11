# v5 → v2 Gap Promotions — Design

**Date:** 2026-06-10
**Status:** Approved (brainstorm with Donal)

## Problem

An audit of the v1 tier found no missing skills: all 14 obra/superpowers 5.1.0
skills are ported verbatim (byte-identical, supporting files included). The real
gaps are lifecycle phases the obra 14 do not cover. The obra suite forms a tight
loop around greenfield feature work (idea → plan → execute → TDD → debug → review
→ verify → merge) and goes silent where work is *not* a fresh feature.

Four gap areas were confirmed in the brainstorm:

1. **Code health** — refactoring, migrations, change-impact analysis in existing code.
2. **Adversarial rigor** — attacking specs, claims, and attack surface, not just bugs.
   (Partially covered: `red-team-spec` already in v2.)
3. **Continuity** — surviving session boundaries and unverified assumptions.
   (Partially covered: `session-handoff` already in v2.)
4. **Communication artifacts** — records that outlive the session (ADRs, postmortems).

## Approach (chosen: A — promote from v5)

Use the promotion path CLAUDE.md already defines: for each gap, take the best
Forge skill from `v5/skills/`, rewrite it to v2 standards, move it into
`v2/skills/`, delete it from v5. Alternatives considered and rejected:

- **B — design fresh, ignore v5:** best fit but reinvents what v5 already
  sketches, then still owes a decision about the redundant v5 skills.
- **C — route per gap (promote / fold into v1 supercharge / design fresh):**
  most principled, but folding into v1 collides with `v1/SUPERCHARGING-OPTIONS.md`,
  which already assigns each v1 skill one chosen upgrade.

Rule carried over from C: if a candidate turns out ~90% redundant with an
existing v1/v2 skill during rewrite, drop it instead of promoting it.

## Promotion slate (7 skills)

| # | Gap area | v5 skill | `supports:` (v1 skills) |
|---|---|---|---|
| 1 | Code health | `blast-radius` | requesting-code-review, verification-before-completion |
| 2 | Code health | `migrate-codebase` | dispatching-parallel-agents, using-git-worktrees |
| 3 | Adversarial | `security-audit` | requesting-code-review, verification-before-completion |
| 4 | Adversarial | `devils-advocate` | receiving-code-review, verification-before-completion |
| 5 | Continuity | `track-assumption` | brainstorming, executing-plans, finishing-a-development-branch |
| 6 | Communication | `write-adr` | brainstorming, writing-plans |
| 7 | Communication | `incident-postmortem` | systematic-debugging |

### Deliberately excluded (YAGNI)

- `progressive-context-recovery`, `evidence-trail` — duplicate `session-handoff`
  and verification-before-completion's evidence discipline; v2 forbids duplication.
- `challenge-implementation` — thin (48 lines), subsumed by `devils-advocate`.
- `dependency-risk-sweep`, `test-impact-analysis`, `write-release-notes` —
  real but second-priority; remain in v5, promotable later.

## Rewrite rules (definition of "promote")

Promotion is a rewrite, not a move. For each skill:

1. Frontmatter: add `tier: v2` and `supports:` listing the v1 skill(s) from the
   slate table; keep `name` (kebab-case, unchanged); rewrite `description` to
   state WHEN to use the skill.
2. **Strip Forge-isms:** references to Forge-only skills (`proof-gate`,
   `verify-before-done`, `shrink-context`, etc.) are remapped to their v1
   equivalents (usually `verification-before-completion`) or cut entirely.
3. **Reference, don't duplicate:** any passage restating v1 content is replaced
   with a pointer to the v1 skill.
4. Add a row to the "Current skills" table in `v2/README.md`.
5. Delete the source directory from `v5/skills/`.
6. Run the `skill-auditor` agent on the rewritten skill; fix findings before done.

## Execution shape

The 7 promotions are independent (no shared files except `v2/README.md`, which
is an append-per-skill edit). They can be executed in parallel per the
`dispatching-parallel-agents` pattern, each audited individually. If sequenced,
do `blast-radius` and `security-audit` first — they plug the largest holes.

`v2/README.md` is the one shared touchpoint: if promotions run in parallel, the
table rows are merged by the controller at the end rather than edited
concurrently.

## Error handling

- A candidate failing the redundancy rule mid-rewrite is dropped, recorded in
  this spec's slate table as "dropped: redundant with X", and left in v5.
- `skill-auditor` findings block completion of that promotion until fixed.
- Nothing in `superpowers2/` is touched — v5 inside this project is the source.

## Verification

A promotion is done when: the v2 SKILL.md exists with valid `tier`/`supports`
frontmatter, no references to Forge-only skill names remain (grep), the
`v2/README.md` row exists, the v5 source directory is deleted, and
`skill-auditor` reports no blocking findings.

## Out of scope

- Supercharging the 14 v1 skills (tracked separately in
  `v1/SUPERCHARGING-OPTIONS.md`).
- Promotions into v3/v4.
- Any git operations (the project is not yet a git repository).
