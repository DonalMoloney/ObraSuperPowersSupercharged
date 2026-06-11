---
name: skill-dependency-graph
description: Use to audit the skill set — builds the call graph from chains-to / pairs-with edges, ranks skills by structural importance, and flags orphans and routing loops. Feeds audit-dead-skills and the OVERVIEW call-graph.
author: Donal Moloney
track: D
type: support
chains-to: ~
---

## Not this skill if
- You want to rename a skill — use `rename-skill`
- You want to find broken references — use `find-dangling-refs`
- You want to retire unused skills (not just identify them) — use `audit-dead-skills`
- You want to validate that frontmatter field values are well-formed strings — use `cross-skill-health-check`

# skill-dependency-graph — structural audit of the skill set

## Purpose

Replace the hand-maintained call-graph in OVERVIEW.md with a computed one: which skills are load-bearing, which are orphans, and where routing loops exist. This skill reads every `skills/*/SKILL.md`, extracts `chains-to` and `pairs-with` edges from frontmatter, builds a directed graph, and emits a ranked Mermaid diagram plus an orphan list and a cycle report. It changes nothing — its only output is analysis.

## Core rule

> **Rule:** Report structure, change nothing. This is read-only analysis.

## Triggers

**Use when:**
- "Audit the skill set" or "show me the call graph"
- A skill was just added, renamed, or retired and OVERVIEW.md needs updating
- You suspect a routing loop (skill A chains to skill B which chains back to A)
- You want a list of orphan skills — candidates for retirement
- Preparing a release and need to verify the dependency graph is acyclic
- Running `audit-dead-skills` and need structural data to feed it

**Don't use when:**
- You only want to check one skill's outbound edges — read its frontmatter directly
- You want to rename or restructure skills, not just observe them — use `rename-skill`
- You want broken text references inside prose sections fixed — use `find-dangling-refs`

## Algorithm

Build a directed graph from frontmatter `chains-to` / `pairs-with`. **PageRank** ranks load-bearing skills; **inbound-degree = 0** flags orphans; **cycle detection** finds routing loops. Uses `graph-algorithms` (backed by `networkx`).

### Edge semantics
- `chains-to: foo` — directed edge from this skill to `foo`; foo is a downstream dependency
- `pairs-with: foo` — undirected co-use relationship; add edges in both directions
- `chains-to: ~` — no outbound chain; this skill terminates a path (do not add an edge)

## Steps

### Step 1 — Collect frontmatter edges

Read every `skills/*/SKILL.md` file. For each file, extract:
- `name:` — the node identifier
- `chains-to:` — target node for a directed edge (skip `~`)
- `pairs-with:` — co-use partner; add bidirectional edges

Record the full edge list as `(source, target, edge_type)` triples before building the graph. If a `chains-to` or `pairs-with` value names a skill that has no corresponding `skills/*/SKILL.md` file, mark that edge as **dangling** — include it in the output but do not abort.

### Step 2 — Build the directed graph

Construct a `DiGraph` with one node per skill name and one directed edge per `(source, target)` pair. For `pairs-with` edges, add both `(A, B)` and `(B, A)` so they contribute to inbound-degree on both sides.

Label each node with its `type:` frontmatter value (implementation / support / entry / etc.) so the Mermaid output can style node shapes by type.

### Step 3 — Compute metrics

Run three passes over the graph:

**PageRank** — call `networkx.pagerank(G)` with default damping (0.85). A high PageRank score means many skills chain through or pair with this one; treat the top-5 as load-bearing. List the full ranked table in the output.

**Inbound-degree** — for each node, count incoming edges. Any node with inbound-degree = 0 and type != `entry` is an orphan — no skill chains to it or pairs with it. Collect these into the orphan list.

**Cycle detection** — call `networkx.simple_cycles(G)`. Any cycle in the `chains-to` subgraph (directed edges only, excluding bidirectional `pairs-with` edges) is a routing loop. Report each cycle as an ordered list of skill names.

### Step 4 — Emit the report

Produce three sections:

**4a. Ranked call graph (Mermaid)**

Emit a `graph LR` block. Render each edge as `SkillA --> SkillB`. Style load-bearing nodes (top-5 PageRank) with a distinct shape (e.g., `[[ ]]` for round-rectangle). Mark orphan nodes with a comment (`%% orphan`). Keep node IDs lowercase with hyphens matching the skill `name:` field exactly.

**4b. Orphan list**

Emit a markdown table: `| skill | type | track | reason |`. The reason is always "inbound-degree = 0". Flag entry-type skills as exempt — they are expected to have no inbound edges.

**4c. Cycle report**

Emit one bullet per detected cycle: `A → B → C → A`. If no cycles are found, emit "No routing loops detected." Cycles in `chains-to` edges are blocking issues; cycles introduced only by `pairs-with` edges are informational.

### Step 5 — Surface dangling edges

List any edge whose target name has no corresponding `skills/*/SKILL.md` file. These are candidates for `find-dangling-refs` follow-up.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Treating `chains-to: ~` as an edge to a node named `~` | Skip `~` values entirely; they mean "no outbound chain" |
| Including entry-type skills in the orphan list | Check `type: entry` before flagging; router/entry skills have no inbound edges by design |
| Running cycle detection on the full graph including `pairs-with` bidirectional edges | Detect cycles on the `chains-to` subgraph only; `pairs-with` pairs are always bidirectional and will produce false cycles |
| Aborting when a dangling reference is found | Record dangling edges in the output, emit a warning, and continue — the graph is still valid for the edges that resolve |
| Collapsing `v2/skills-to-adapt/` paths into the main `skills/` graph | Only scan `skills/*/SKILL.md`; v2 scaffolds are not published and must not appear as real nodes |
| Emitting a Mermaid block with spaces in node IDs | Sanitize node IDs: replace spaces with hyphens and strip special characters before emitting |

## Verification / Proof

The report is self-verifying: every claim (PageRank score, orphan status, cycle) must be reproducible by re-running the algorithm on the same frontmatter snapshot. Before closing:

1. Confirm that the node count in the Mermaid block matches the count of `skills/*/SKILL.md` files scanned.
2. Confirm that the orphan list excludes all `type: entry` nodes.
3. Confirm that every skill named in a cycle appears as a real node in the graph.
4. Confirm that dangling edges are listed separately and not silently dropped.

Because `chains-to: ~`, this skill does not hand off to a downstream skill. Include the following block at the end of the output:

```
PROVEN BY:
- skills scanned: <N>
- edges collected: <E> (chains-to: <C>, pairs-with: <P>)
- dangling edges: <D> (listed above)
- orphans found: <O> (entry-type exempt: <X>)
- cycles found: <Y> (chains-to subgraph only)
- Mermaid node count matches scanned skill count: yes / no
```

## Adapt from
- **`networkx`** (`pagerank`, `simple_cycles`, in-degree) via `graph-algorithms`. <https://networkx.org>
