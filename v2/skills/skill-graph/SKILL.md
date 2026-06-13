---
name: skill-graph
description: Use when you need to answer "which skills are load-bearing, which are dead, and what relations are broken?" across this repo — builds the chains-to / pairs-with / supports call graph from every SKILL.md frontmatter, then runs one diagnostic pass that flags dangling references, inbound-degree-0 orphans, and routing cycles. Run after any rename, deletion, or batch supercharge, and before a release tag.
author: Donal Moloney
tier: v2
supports: [writing-skills, using-superpowers]
type: support
pairs-with: semantic-skill-router
---

## Not this skill if

- **You want to route one task to one skill** — that is v2 **semantic-skill-router**. This skill analyzes the relation graph; it does not pick a workflow.
- **You are checking a single edited SKILL.md for structure** — that is v2 **skill-lint** (frontmatter, sections, tier rules). skill-graph is cross-skill; skill-lint is single-file.
- **The change is one slug rename and you only need the broken targets** — run the v5 `find-dangling-refs` companion directly; this skill is the full graph pass on top of it.
- **You want to act on orphans (retire / rewire), not just find them** — produce the report here, then hand it to the v5 `audit-dead-skills` companion or a human.

# skill-graph — relation-graph diagnostic over skill frontmatter

## Purpose

This repo wires skills together through three frontmatter relation fields — `chains-to`,
`pairs-with`, and (v2-only) `supports` — across five tiers plus `frontend/`. Those links are
declared but never validated, so the catalog drifts from disk: today there are 25 dangling
`chains-to` / `pairs-with` references (all in v5, pointing at Forge-fork slug aliases of v1 skills)
and 80 skills with no declared relations. This skill turns the prose-and-frontmatter relation layer
into a computed graph and reports where it is broken.

It implements **CHAINING-OPTIONS.md option A — machine-readable skill graph**: one read-only
diagnostic that flags dangling references, orphans, and cycles so the relation layer can be verified
instead of trusted.

It supports two v1 skills:

- v1 **writing-skills** — that skill is the TDD loop for authoring a SKILL.md; skill-graph is the
  cross-skill verification that authoring loop lacks. After a skill is added, renamed, or retired,
  run skill-graph to confirm the new relations resolve and no edge was left dangling.
- v1 **using-superpowers** — that skill is the routing entry point whose table must name every
  sibling skill. skill-graph proves the relation graph behind that table is intact: an orphan or a
  dangling `chains-to` is a routing dead end the entry skill cannot see from prose alone.

**Core rule:** Report only — change nothing. skill-graph is read-only analysis; acting on its findings
(retire an orphan, fix a dangling edge) is a separate, deliberate step.

## How it consumes the v5 companions

skill-graph is the v2 orchestration layer over mechanics that already exist in v5 — it does **not**
re-implement them. It reads them as the engine:

| Concern | v5 companion this skill drives | What skill-graph adds |
|---|---|---|
| Extract live slug set + outbound refs, diff to find broken/orphan links | `find-dangling-refs` | Runs it across **all** tiers (v1–v5 + frontend), not one `skills/` tree |
| Build the directed graph, PageRank, inbound-degree, cycle detection | `skill-dependency-graph` | Consumes its per-tier output and merges into one cross-tier graph |
| Graph math (PageRank, SCC, in-degree, `simple_cycles`) | `graph-algorithms` (networkx engine) | Never re-implements math; delegates every computation |
| Act on the orphan list | `audit-dead-skills` | Hands off; skill-graph stops at the report |

If a v5 companion is unavailable in the current environment, fall back to reasoning over the parsed
frontmatter directly — the graph is small enough to walk by hand for the per-skill checks, but always
delegate PageRank and cycle detection to `graph-algorithms` rather than approximating them.

## Inputs

- Every `SKILL.md` in the repo. The relation graph spans tiers, so the scan scope is **all** of:
  `v1/*/SKILL.md`, `v2/skills/*/SKILL.md`, `v3/skills/*/SKILL.md`, `v4/**/SKILL.md`,
  `v5/skills/*/SKILL.md`, and `frontend/**/SKILL.md`.
- From each file, the load-bearing fields: `name` (node id), `chains-to`, `pairs-with`, and `supports`.

If the scan finds fewer than ~5 skills, **STOP** — read the frontmatter directly; the graph buys
nothing at that size.

## Edge semantics

Build a directed graph `G`. One node per skill `name`. Add edges by field:

- `chains-to: foo` — directed edge `this → foo` (downstream dependency).
- `pairs-with: foo` — undirected co-use; add both `this → foo` and `foo → this`.
- `supports: [v1-skill, …]` — directed edge `this → v1-skill` (a v2 skill points at the v1 skill it
  strengthens). These edges give every v1 skill its inbound support degree.
- `chains-to: ~` (or empty) — no outbound chain; the skill terminates a path, add no edge.

A relation value naming a slug with **no** corresponding `SKILL.md` anywhere in scope is a **dangling
edge**: record it, do not abort.

## Steps

### 1 — Collect the live slug set and the edge list

Drive the v5 `find-dangling-refs` mechanics across all six scan scopes above. Parse frontmatter (not
plain grep) to extract every `name`, and every `chains-to` / `pairs-with` / `supports` value as a
`(source, target, edge_type)` triple. Record the full edge list before building the graph.

Tag each target as **resolved** (its slug is in the live set) or **dangling** (no `SKILL.md` exists
for it). Forge-fork aliases in v5 that point at renamed v1 slugs are the expected dangling class —
group them by missing slug so the report shows the alias → real-skill mapping at a glance.

### 2 — Build the graph and compute metrics

Hand the resolved edge list to `graph-algorithms` (via `skill-dependency-graph`) and run three passes:

1. **PageRank** (`networkx.pagerank`, damping 0.85) → **load-bearing** skills. Treat the top-N as the
   skills that take the most workflows down if broken. Report the full ranked table.
2. **Inbound-degree = 0** → **orphans**: skills nothing chains to, pairs with, or supports. Each is
   either a retirement candidate or a missing inbound edge that should exist.
3. **Cycle detection** (`networkx.simple_cycles`) on the **`chains-to` subgraph only** → **routing
   loops**: chains that can route into themselves and never terminate.

### 3 — Apply the orphan exemptions

Do **not** flag as orphans, even at inbound-degree 0:

- Skills marked `type: entry` (e.g. v1 **using-superpowers**, v2 **semantic-skill-router**) — they are
  invoked by the user, not by other skills.
- A skill's own self-reference never counts toward its inbound degree.

### 4 — Emit the report

Read-only markdown, four sections:

- **A. Load-bearing** — top-N by PageRank, each with score.
- **B. Orphans** — `| skill | tier | reason |`, reason always "inbound-degree = 0"; entry-type skills
  listed separately as exempt.
- **C. Routing loops** — one bullet per cycle as a path (`a → b → c → a`); or "No routing loops
  detected."
- **D. Dangling edges** — grouped by missing target slug, each with the `(file, source-skill)` that
  cites it. This is the section that surfaces the 25 v5 → v1-alias breaks. Hand it to a human or to a
  rename pass; skill-graph does not fix it.

If B, C, and D are all empty, emit: `Graph clean — no dangling edges, no orphans, no routing loops.`

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Scanning only `v2/skills/` | The relation graph is cross-tier; scan all six scopes or you miss the v5 → v1 dangling edges entirely |
| Re-implementing PageRank or cycle detection inline | Delegate to `graph-algorithms`; this skill is the reader + reporter, not the math |
| Treating `chains-to: ~` as an edge to a node named `~` | Skip `~` and empty values; they mean "no outbound chain" |
| Flagging entry-type skills as orphans | Exempt `type: entry`; they have no inbound edges by design |
| Running cycle detection on `pairs-with` edges | Bidirectional pairs always look like 2-cycles; detect cycles on the `chains-to` subgraph only |
| Editing a skill to fix a dangling edge mid-report | Report-only. Acting on findings is a separate step via `audit-dead-skills` or a rename |

## Verification

The report is self-verifying: every claim must be reproducible by re-running the algorithm on the same
frontmatter snapshot. Before closing, confirm:

1. The node count equals the number of `SKILL.md` files scanned across all six scopes.
2. The orphan list excludes every `type: entry` node.
3. Every skill named in a cycle is a real node in the graph.
4. Dangling edges are listed in section D, never silently dropped.

PROVEN BY: a terminal block of the form

```
PROVEN BY:
- skills scanned: <N> across v1–v5 + frontend
- edges collected: <E> (chains-to <C>, pairs-with <P>, supports <S>)
- dangling edges: <D> (grouped by missing target, listed in section D)
- orphans: <O> (entry-type exempt: <X>)
- routing loops: <Y> (chains-to subgraph only)
- node count matches scanned file count: yes / no
- files modified: 0
```
