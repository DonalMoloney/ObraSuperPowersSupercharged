# Chaining Options

How the skills in this repo compose into workflows — and the research-grounded
ways to chain them together *better*. This is a reference and decision menu, not a
work-order tracker: it documents the mechanisms that exist today, maps them to the
established agent-workflow research, and lists the options (A–G) for tightening the
glue between skills. Pick from the menu the same way `v1/SUPERCHARGING-OPTIONS.md`
is used; effort bands (Simple / Medium / Advanced) and cross-cutting IDs (CC2, CC5,
CC8) carry the same meaning as in that doc.

> **Scope.** "Chaining" here means one skill handing off to, building on, or running
> alongside another — the wiring *between* skills. The canonical 14-skill workflow
> graph itself is defined by **CC2** in `v1/SUPERCHARGING-OPTIONS.md`; this doc is
> about making that graph (and the v2–v5 / frontend extensions of it) explicit,
> discoverable, and checkable.
>
> **`v6/` is a second chaining surface — out of session.** v6 members are runnable
> GitHub Actions, not skills: they chain through GitHub *events* and a shared composite
> action rather than `chains-to:` frontmatter, and run in CI rather than a Claude Code
> conversation. They get their own section below; the A–G options target the in-session
> skill graph and do not apply to them.

---

## Research grounding

Two sources anchor the options below:

- **Anthropic — [Building Effective AI Agents](https://www.anthropic.com/research/building-effective-agents).**
  Five canonical workflow patterns: **prompt chaining**, **routing**,
  **parallelization** (sectioning + voting), **orchestrator-workers**, and
  **evaluator-optimizer**. Each is already implemented somewhere in this repo (see
  the pattern catalog below) — the opportunity is in the wiring, not in inventing new
  patterns.
- **Skill-chaining best practices** —
  [Claude Code skill collaboration / chaining](https://www.mindstudio.ai/blog/claude-code-skill-collaboration-chaining-workflows)
  and [skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).
  Three rules that shape good chains:
  1. **Memo, not report** — each skill returns structured, *minimal* output carrying
     only the fields the next step needs.
  2. **Test the seams** — verify pairs of connected skills, then the full chain, so a
     break localizes to one handoff.
  3. **Log received / did / returned** — a handoff is debuggable only if each end
     records what crossed it. Proven chains can then be promoted to a Routine.

---

## What we already have — the 4-layer chaining stack

Chaining is not new here; it is expressed across four layers. The options exist to
make these layers consistent and machine-checkable, not to replace them.

| Layer | Mechanism | Where |
|---|---|---|
| **1 — Frontmatter relations** | `supports: [v1-skill, …]`, `chains-to: <skill>`, `pairs-with: <skill>` | v2 declares `supports:` for all 42 skills; `chains-to`/`pairs-with` appear across v2/v4/v5 |
| **2 — Prose handoffs** | "invoke X skill", `REQUIRED SUB-SKILL` headers, mermaid decision flowcharts | v1 core chain (`brainstorming` → `writing-plans` → `executing-plans`/`subagent-driven-development` → `finishing-a-development-branch`) |
| **3 — Registries** | hand-maintained catalogs of skills and their support relations | `MANIFEST.md` (all 166 skills by tier/function), `v2/README.md` (the `supports` table) |
| **4 — Orchestrators** | skills that sequence other skills | `orchestrate-feature` (full route→scope→plan→execute→verify→review→finish chain), `parallel-plan-executor`, `subagent-driven-development` wave algorithm |

**Known gaps** (what the options close):

- No machine-readable graph — the `chains-to`/`supports`/`pairs-with` links are never
  validated, so a renamed or deleted skill can leave dangling references.
- `compose-skill-chain` specifies a named-chain registry (`*.chain.md`) but **no chain
  files exist on disk**.
- The routing entry point (`skill-router`) lives only in v5 prose.
- `frontend/` declares its links to v1 skills in prose ("extends v1
  verification-before-completion"), not in the frontmatter vocabulary the other tiers
  use.
- Handoff payloads are ad-hoc — there's no fixed "memo" format a skill emits on exit
  and the next consumes on entry.

---

## Pattern catalog — Anthropic's five patterns → repo skills

Use this to place a new or chained skill: identify which pattern the handoff is, then
follow the skills that already implement it.

| Pattern | What it is | Implemented here by |
|---|---|---|
| **Prompt chaining** | Each step's output feeds the next | `brainstorming` → `writing-plans` → `executing-plans` → `finishing-a-development-branch`; `chains-to:` frontmatter |
| **Routing** | Classify the task, dispatch to the right chain | `using-superpowers` (skill discovery); `orchestrate-feature` / `skill-router` (v5, prose only) |
| **Parallelization** | Independent subtasks fan out (sectioning); repeated runs vote (voting) | `dispatching-parallel-agents`, `parallel-plan-executor`, `subagent-driven-development` (sectioning); `reviewer-lenses`, `red-team-spec` (voting/multi-lens) |
| **Orchestrator-workers** | A controller decomposes dynamically and synthesizes | `orchestrate-feature`, `subagent-driven-development` wave construction, `merge-parallel-results` (fan-in) |
| **Evaluator-optimizer** | Generate, then critique/score in a loop | `loop-until-green`, `done-gate`, `devils-advocate`, `reviewer-lenses`, `verification-before-completion` |

---

## v6 — CI-side chaining (out of session)

The `v6/` tier chains too, but on a different surface: its members are runnable GitHub
Actions, so they compose through **GitHub events** and a **shared composite action**
rather than `chains-to:` frontmatter, and they run in CI instead of a conversation. The
three best-practice rules still hold — they just take CI forms:

- **The seam is `_cost-guardrail`.** The reviewer and triage actions both hand their
  prompt to one composite action and read back its `response-file` / `spent-usd`
  outputs — "memo, not report" as a reusable worker, not per-action HTTP.
- **The handoff state is a sticky-comment marker.** Each action records what it did in a
  hidden marker (`<!-- last-sha=… -->`, `<!-- claude-ci-triage:… -->`) that the next run
  reads — "log received / did / returned" made idempotent.
- **Testing the seam** is `actionlint` + `node --check` on the helper scripts, before
  the workflow goes live.

Each v6 action is the **headless / CI mirror** of an in-session skill chain:

| v6 action | Chains via | Anthropic pattern | In-session mirror |
|---|---|---|---|
| `_cost-guardrail` | reused by the reviewer + triage actions | shared worker (infra seam) | — |
| `incremental-pr-reviewer` | `pull_request` → build → guardrail → post → sticky summary | prompt chaining + evaluator-optimizer | `requesting-code-review` / `receiving-code-review` |
| `self-healing-ci-triage` | `workflow_run` failure → guardrail → diagnosis comment | evaluator-optimizer | `systematic-debugging` |
| `autonomous-issue-fixer` | `claude-fix` label / authorized `@claude` → branch → draft PR | routing (trigger gate) + orchestrator-workers | the `brainstorming → … → finishing-a-development-branch` chain, run headless via `anthropics/claude-code-action` |

v6 is intentionally **outside the A–G scope below**: those options target the frontmatter
skill graph, and v6 templates carry no skill frontmatter, so the machine-readable graph
(option A) neither includes nor validates them. Treat this table as v6's pattern catalog
and keep it current as the tier grows (menu items #4–#10 in the design spec are deferred).

---

## Options for chaining better (A–G)

Each option names what it is, the research pattern it serves, the gap it closes, and
an effort band. They are independent — adopt any subset.

### A — Machine-readable skill graph *(Advanced)*
Generate one `skills.graph.json` from the `supports` / `chains-to` / `pairs-with`
frontmatter across all tiers, plus a lint that flags dangling references (a
`chains-to` target that doesn't exist), orphans (skills nothing reaches), and cycles.
- **Pattern:** prompt chaining + validation. **Closes:** no graph, no cross-ref check.
- **Why:** turns the four prose/frontmatter layers into something a script can verify
  and a `MANIFEST` can be generated *from*, so the catalog can't drift from disk.

### B — Canonical relationship vocabulary *(Simple)*
Document the three relation fields once and require **every** tier — including
`frontend/`, which uses prose today — to declare chaining the same way.
- **Pattern:** consistency (precondition for A). **Closes:** frontend prose-only links.
- **Why:** a graph (A) is only as good as the uniformity of its inputs.

### C — Named-chain registry *(Medium, CC8)*
Actually implement `compose-skill-chain`: record proven sequences (e.g.
`feature-build` = brainstorm → plan → execute → verify → finish) as reusable
`*.chain.md` artifacts with explicit entry/exit contracts, written to a predictable
repo path.
- **Pattern:** prompt chaining → promote to Routine. **Closes:** registry specced but
  empty on disk.
- **Why:** the best practice "promote a proven chain" needs the chain to exist as a
  durable artifact, not as conversation memory.

### D — Routing entry skill *(Medium)*
Promote `skill-router` / `orchestrate-feature` out of v5 prose into a real tier as the
single dispatcher: read the task, classify it, pick the chain.
- **Pattern:** routing. **Closes:** router exists only in v5.
- **Why:** today routing is implicit in `using-superpowers`; an explicit dispatcher
  makes the entry point first-class and testable.

### E — Handoff contract / evidence envelope *(Medium, CC5)*
Define a fixed "memo" block a skill emits on exit and the next skill consumes on
entry — the structured-minimal-output rule made concrete. Formalizes the CC5 evidence
format so the *output of one skill is literally the input of the next*.
- **Pattern:** structured minimal output ("memo, not report"). **Closes:** ad-hoc
  payloads per skill.
- **Why:** clean seams are what make a chain debuggable and a break localizable.

### F — Evaluator-gate rule *(Simple)*
Document the convention that every implementation chain must terminate in an evaluator
loop (`loop-until-green` / `done-gate` / `reviewer-lenses`) before `finishing-a-development-branch`.
- **Pattern:** evaluator-optimizer. **Closes:** gating is per-skill, not a rule.
- **Why:** makes "evidence before done" a property of the chain, not a habit.

### G — Pattern catalog *(Simple)*
Keep the table above (five patterns → repo skills) current as a living map, so an
author knows which pattern a new skill plugs into and which existing skills to chain
with.
- **Pattern:** all five. **Closes:** no pattern-level orientation.
- **Why:** lowest-effort, highest-orientation; the entry point for everything else.

---

## Authoring a chain — the checklist

When you wire two or more skills together (drawn from the best-practice sources above):

1. **Name the pattern** (catalog above) — chaining, routing, parallel, orchestrator,
   or evaluator. The pattern dictates the handoff shape.
2. **Declare the relation** in frontmatter — `supports` / `chains-to` / `pairs-with`
   (option B vocabulary), so the link is discoverable, not prose-only.
3. **Define the seam** — what the upstream skill emits and the downstream consumes
   (option E / CC5). Keep it a memo: minimal, structured.
4. **Test the seam, then the chain** — verify the pair in isolation before the whole
   sequence, so a failure localizes to one handoff.
5. **Terminate in a gate** (option F) — no chain ends without an evaluator step.
6. **If it's reusable, record it** (option C) as a named `*.chain.md`, and consider
   promoting it to a Routine.

---

## Status at a glance

| Option | Band | State today |
|---|---|---|
| A — Machine-readable graph | Advanced | Not built; frontmatter exists to feed it |
| B — Relationship vocabulary | Simple | Partial — v2 uniform, frontend prose-only |
| C — Named-chain registry | Medium | Specced (`compose-skill-chain`), no files on disk |
| D — Routing entry skill | Medium | v5 prose only |
| E — Handoff contract | Medium | Ad-hoc; CC5 drafted in SUPERCHARGING-OPTIONS |
| F — Evaluator-gate rule | Simple | Convention exists per-skill, not documented as a rule |
| G — Pattern catalog | Simple | Documented above; keep current |
