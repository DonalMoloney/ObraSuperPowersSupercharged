---
name: index-skills
description: Use when the Pinecone skill index needs to be built or refreshed — reads every SKILL.md in the skills directory, embeds name + description + trigger conditions, and upserts into the superpowers-skills index. Run after any skill is added, renamed, or retired.
author: Donal Moloney
track: D
type: support
chains-to: route-to-skill
---

## Not this skill if
- Pinecone is not configured — set PINECONE_API_KEY and the index name first
- You are only querying the index — use `route-to-skill` for queries
- A single skill changed and a full reindex is too slow — upsert that one record directly

# index-skills — Pinecone skill catalog indexer

## Purpose

`route-to-skill` depends on a populated Pinecone index to do semantic matching. This skill builds and maintains that index. Run it after any change to `skills/**/SKILL.md` to keep routing accurate.

## Core rule

> **Rule:** Index the content the router will query — name, description, trigger phrases. Do not index step-by-step instructions; they add noise without helping routing.

## Steps

### 1. Discover skill files

```bash
find skills/ -name "SKILL.md" | sort
```

Collect the list. Skip any file under `agents/` or `dont look/`.

### 2. Extract indexable content per skill

For each SKILL.md, extract:

```
id:      <skill-name>           # from frontmatter name:
text:    <name> | <description> | <trigger phrases from ## Triggers or ## Not this skill if>
track:   <frontmatter track>
type:    <frontmatter type>
chains:  <frontmatter chains-to>
```

The `text` field is what gets embedded — keep it to the first 300 tokens of meaningful content. Do not include step bodies, pitfall lists, or code examples.

**Example record:**
```
id:   outline-plan
text: outline-plan | Use when you have a spec or requirements document for a multi-step task
      and need a concrete implementation plan before any code is written | multi-step task |
      implementation plan | spec to plan | writing plans
track: A
type: process
chains: execute-plan
```

### 3. Check for stale records

Query the index for the current record count. Compare against the number of SKILL.md files found.

If the index has more records than files, the extra records are from retired skills — delete them:

```
pinecone delete ids: [<retired-skill-names>]
```

### 4. Upsert all records

Use `pinecone:upsert-records` (or the Pinecone MCP tool) to upsert all extracted records into the `superpowers-skills` index.

Batch in groups of 50. Report the total upserted.

### 5. Verify

Query the index with a known skill's description and confirm it returns that skill as the top hit:

```
query: "use when a task, fix, build, or test is about to be marked done"
expected top result: proof-gate
```

Emit:

```
index-skills: 35 records upserted to superpowers-skills.
Verification: query returned proof-gate (similarity: 0.94). PROVEN BY: pinecone query → proof-gate rank 1
```

## Hook integration

A `PostToolUse Write` hook on `skills/**/*.md` should trigger this skill automatically. If the hook is not configured, run manually after any SKILL.md change.

Hook configuration (hookify format):
```json
{
  "event": "PostToolUse",
  "tool": "Write",
  "match": "skills/**/*.md",
  "action": "invoke index-skills"
}
```

## Pitfalls

- Embedding full SKILL.md content — routing needs trigger phrases, not implementation steps. Long embeddings dilute the signal.
- Forgetting to delete stale records for retired skills — they pollute routing results.
- Running without verifying the top-hit query — a misconfigured embedding model will index silently and route badly.
- Indexing `agents/` subdirectories — those are subagent specs, not invocable skills.

## Pairs with

- [`route-to-skill`](../route-to-skill/SKILL.md): consumes this index for semantic routing
- [`analyse-routing`](../analyse-routing/SKILL.md): telemetry analysis that complements the index
- [`judge-skill`](../judge-skill/SKILL.md): quality gate; run before indexing a new skill
