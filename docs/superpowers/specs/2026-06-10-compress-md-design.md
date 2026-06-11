# compress-md — v2 skill design

**Date:** 2026-06-10
**Tier:** v2 (supporting skill)
**Location:** `v2/skills/compress-md/SKILL.md`
**Status:** approved by user

## Problem

SKILL.md files, CLAUDE.md files, and general markdown docs accumulate filler prose,
duplicated instructions, and verbose examples. Every load of those files burns tokens.
There is no skill that compresses a markdown file into a Claude-optimized form while
guaranteeing no instruction is lost.

## Decision summary (user-approved)

- **Tier:** v2 — supports `writing-skills` (keeps SKILL.md lean) and `using-superpowers`
  (cuts session-start context cost of loaded files).
- **Output mode:** rewrite the file in place, after copying the original to a backup
  folder (`.compress-md-backups/<timestamp>-<filename>` at the repo root).
- **Aggressiveness:** strictly meaning-preserving. Reword and restructure freely; never
  drop an instruction, rule, constraint, or fact. Expected savings ~20–40%.
- **Structure:** single-file skill (Approach A) with a type router, shared rules,
  per-type playbooks, and a verification gate. Matches the existing v2 house style
  (cf. `skill-lint`).

## Frontmatter

```yaml
name: compress-md
description: <states WHEN — a SKILL.md, CLAUDE.md, or general md doc has grown bloated
  and its token cost should be cut without changing what it instructs>
author: Donal Moloney
tier: v2
supports: [writing-skills, using-superpowers]
type: process
chains-to: skill-lint
```

## Core rule

Compression that loses an instruction is a failure, not a trade-off — restore from
backup and retry.

## Procedure (skill body)

1. **Backup** — copy target to `.compress-md-backups/<UTC timestamp>-<filename>` at the
   repo root (create the folder if absent) before any edit.
2. **Classify** the target:
   - *SKILL.md* — has skill frontmatter (`name` + `description`) or lives in a
     `skills/` directory.
   - *CLAUDE.md-family* — `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md`.
   - *General md* — everything else.
3. **Measure baseline** — token estimate = `chars / 4`; record it.
4. **Shared compression rules** (all types):
   - Delete filler and hedges ("It is important to note that…", restatements,
     intro/outro paragraphs that add no instruction).
   - Convert prose paragraphs to imperative bullets.
   - Use tables for short enumerable facts.
   - Dedupe repeated instructions into one canonical statement at one location.
   - Merge tiny sections; drop decorative headers/rules.
   - Shorten verbose examples but keep at least one example per concept.
   - Never alter code blocks, commands, file paths, or URLs.
5. **Type playbook:**
   - *SKILL.md:* never weaken `description` trigger phrases (they drive activation);
     keep checklists, flowcharts, and tier-required sections (e.g. v1
     `## Supercharged vs upstream`) structurally intact; compress only surrounding
     narrative; frontmatter fields preserved.
   - *CLAUDE.md:* every rule survives; narrative → grouped bullet rules; paths and
     commands verbatim; group by topic.
   - *General md:* front-load a summary; enforce heading hierarchy for retrieval;
     bullets over prose; keep all facts and links.
6. **Verification gate:**
   - Diff against the backup; confirm every instruction, constraint, and fact from the
     original is findable in the compressed file. Any loss → restore the lost content
     before declaring done.
   - If target is a SKILL.md, run the `skill-lint` checklist on the result.
   - Emit a one-line report: file, type, tokens before/after, % saved, backup path,
     lint result (if applicable).

## Guardrails — "Not this skill if"

- Lossy summarization is wanted — out of scope by design.
- Target is read-only source material (e.g. `superpowers2/`) — never compress.
- File is mostly code blocks — savings negligible; skip.

## Bookkeeping

- Add a row to the "Current skills" table in `v2/README.md`.
- Run the `skill-auditor` agent on the new skill before committing.
- Repo is not yet git-initialized; no commit step until that changes.

## Testing

Verification is built into the skill (step 6). Acceptance for this implementation:
the new SKILL.md passes the `skill-auditor` agent with no FAIL findings.
