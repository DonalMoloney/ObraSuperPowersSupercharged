---
name: compress-md
description: Use when a SKILL.md, CLAUDE.md, or other markdown doc has grown bloated and its token cost should be cut without changing what it instructs — rewrites the file in place, meaning-preserved, with a backup and a verification gate.
author: Donal Moloney
tier: v2
supports: [writing-skills, using-superpowers]
type: process
chains-to: skill-lint
---

## Not this skill if
- Lossy summarization is wanted — this skill is strictly meaning-preserving, out of scope by design
- Target is read-only source material (e.g. `superpowers2/`) — never compress
- File is mostly code blocks — savings negligible; skip

# compress-md — token compression for markdown, zero instruction loss

## Purpose

Rewrite a bloated markdown file into a Claude-optimized form: same instructions, fewer
tokens. Expected savings 20–40%.

Supports v1 **writing-skills**: keeps SKILL.md files lean so the authoring TDD cycle
ends with a tight artifact, not narrative sprawl. Supports v1 **using-superpowers**:
every file loaded at session start costs tokens; compressing them cuts that recurring
cost directly.

**Core rule:** Compression that loses an instruction is a failure, not a trade-off —
restore from backup and retry.

## Procedure

1. **Backup.** Copy the target to `.compress-md-backups/<UTC timestamp>-<filename>` at
   the repo root. Create the folder if absent. No edit before the backup exists.
2. **Classify** the target:
   - *SKILL.md* — has skill frontmatter (`name` + `description`) or lives in a `skills/` directory
   - *CLAUDE.md-family* — `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md`
   - *General md* — everything else
3. **Measure baseline.** Token estimate = `chars / 4`. Record it.
4. **Apply shared rules** (all types):
   - Delete filler and hedges ("It is important to note that…", restatements, intro/outro paragraphs that add no instruction)
   - Convert prose paragraphs to imperative bullets
   - Use tables for short enumerable facts
   - Dedupe repeated instructions into one canonical statement at one location
   - Merge tiny sections; drop decorative headers and rules
   - Shorten verbose examples; keep at least one example per concept
   - Never alter code blocks, commands, file paths, or URLs
5. **Apply the type playbook:**

   | Type | Rules |
   |---|---|
   | SKILL.md | Never weaken `description` trigger phrases — they drive activation. Keep checklists, flowcharts, and tier-required sections (e.g. v1 `## Supercharged vs upstream`) structurally intact; compress only surrounding narrative. Preserve all frontmatter fields. |
   | CLAUDE.md-family | Every rule survives. Narrative becomes grouped bullet rules; group by topic. Paths and commands verbatim. |
   | General md | Front-load a summary. Enforce heading hierarchy for retrieval. Bullets over prose. Keep all facts and links. |

6. **Verification gate:**
   - Diff against the backup. Verify every instruction, constraint, and fact from the
     original is findable in the compressed file. Any loss → restore the lost content
     before declaring done.
   - If the target is a SKILL.md, run the v2 **skill-lint** checklist on the result.
   - Emit the report (below).

## Output report

One line per compressed file:

```
compress-md: <path> | type: <skill|claude|general> | tokens: <before> → <after> (-<percent>%) | backup: <backup path> | lint: <PASS|FAIL|n/a>
```

## Pairs with

- v1 **writing-skills** — compress after authoring; lint gates the result
- v1 **using-superpowers** — compress files in the session-start load path first; biggest recurring payoff
- v2 **skill-lint** — mandatory post-compression check when the target is a SKILL.md

PROVEN BY: the step 6 diff against the backup — done means every original instruction is findable in the compressed file and the report shows measured token savings.
