# Advanced algorithms — orchestration & parallel upgrades

Algorithmic upgrades for the skill framework, ranked by leverage and grounded in the
skill each one plugs into. The first block targets routing/scheduling/debugging across
all skills; the second targets `orchestrate-feature` specifically; the third is 10
concrete scenarios spanning orchestration and parallel execution.

---

## Framework-wide upgrades

### 1. Semantic routing with vector search + reranking — `skill-router` / `index-skills`
Highest-leverage move; already half-built (Pinecone, `index-skills`, planned `route-to-skill`).
- **Today:** keyword/heuristic matching — 35 skills compete, near-misses get skipped.
- **Algorithm:** embed each skill's `name + description + trigger phrases`, then **kNN over
  cosine similarity + cross-encoder reranking** on the top-k. Add a **confidence threshold +
  margin check**: if top-1 and top-2 scores are within ε, the router *asks* instead of guessing.
- **Payoff:** routing stops being keyword-fragile; principled "no skill applies" signal.

### 2. Conflict-graph scheduling — `run-agents-in-parallel`
The independence gate is a manual "do file scopes overlap?" eyeball check — it's a graph problem.
- **Algorithm:** undirected graph, nodes = tasks, edges = shared file scope. **Connected
  components** = batches that must serialize; independent components run in parallel.
  **Greedy graph coloring** packs maximally-parallel non-conflicting batches under the 5–6 cap.
- **Payoff:** turns "I think these are independent" into a provable partition; auto-detects overlap.

### 3. Task-DAG + critical path — `outline-plan` / `spawn-subagent`
Plans are linear lists; the real structure is a dependency DAG.
- **Algorithm:** **topological sort** validates ordering and surfaces cycles; **Critical Path
  Method (CPM)** finds the longest dependency chain — the true minimum completion time and the
  exact tasks to parallelize for the biggest win.
- **Payoff:** `outline-plan` emits a schedule, not just a checklist; `spawn-subagent` dispatches by layer.

### 4. Delta debugging / bisection — `diagnose-bug` / `find-root-cause`
- **Algorithm:** **ddmin (delta debugging)** auto-shrinks a failing input to its minimal repro;
  **automated `git bisect`** localizes the introducing commit; **Bayesian hypothesis ranking** in
  `decision-ledger` updates a posterior per REFUTED entry instead of just counting to "3 strikes".
- **Payoff:** the "write hypothesis verbatim" discipline gains a quantitative ranking; repro minimization becomes mechanical.

### 5. Salience-based compression — `shrink-context` / `detect-context-rot`
Described by compression *ratios* (40–90%) but the *method* is hand-waved.
- **Algorithm:** **TextRank / centrality** for extractive keep-selection; **MinHash/SimHash** for
  near-duplicate removal; for rot detection, an **information-theoretic drift signal**
  (entropy/perplexity of recent output vs. baseline) to *detect* "lost-in-middle".
- **Payoff:** the compression claim becomes measurable and reproducible — fits `PROVEN BY:`.

### 6. Skill-graph analytics — new skill (`skill-dependency-graph`)
35 skills with `chains-to` / `pairs-with` edges and no structural analysis.
- **Algorithm:** **PageRank** over the call graph finds load-bearing skills; **inbound-degree = 0**
  detects orphans (`audit-dead-skills`); **cycle detection** finds routing loops.
- **Payoff:** data-driven retirement and a real dependency map instead of a hand-maintained one.

### 7. Multi-armed bandit routing feedback — `adaptive-skill-router`
- **Algorithm:** **Thompson sampling / UCB** over a log of invoked vs. skipped/overridden skills,
  proposing routing-rule changes that reduce friction.
- **Payoff:** the router learns from session history instead of being statically tuned.

---

## Orchestration-layer upgrades (`orchestrate-feature`)

The chain is a fixed serial DAG with gate loop-backs and a telemetry log — a workflow DAG with a
hand-coded policy. Both the DAG and the policy can be made algorithmic.

### A. Parallel-layer DAG execution instead of a serial chain
Step 5 (`execute-plan`) hides a whole task DAG. Combine **topological layering** (#3) with the
**conflict graph** (#2): the orchestrator fans out each layer of non-conflicting tasks to the agent
pool, joins at a barrier, then advances. The serial chain becomes a **fork/join DAG executor**.

### B. Telemetry as a Markov policy + bandit
`.forge/telemetry.jsonl` logs `{skill, gate_blocked, task_hash}` — training data. Model skill
transitions as a **Markov chain** (which chains succeed vs. loop) and let `analyse-routing` use a
**contextual bandit (Thompson sampling)** to pick the chain variant per task class. Gate-block
frequency is the reward signal — the orchestrator learns which chains waste loops.

### C. Saga pattern with compensation for gate failures
Gates loop back (verify→review→apply→verify) with no rollback. Formalize the chain as a **saga**:
each step registers a compensating action, so a hard gate failure unwinds cleanly (revert commits,
discard branch) instead of looping unboundedly. Pair with a **circuit breaker** so the verify↔review
loop trips to `try-different-approach` after N oscillations.

---

## 10 examples (scenario → algorithm → where it plugs in)

1. **"Implement auth: 8 tasks, 3 touch `db.ts`."** → Build conflict graph; **connected components**
   isolate the 3 db tasks into one serial batch, the other 5 run as a parallel layer. →
   `orchestrate-feature` step 5 + `run-agents-in-parallel`.

2. **"This 12-task plan — what's the fastest it can finish?"** → **Critical Path Method** on the
   task DAG returns the longest dependency chain (1→4→9→12); everything off-path is slack to
   parallelize. → `outline-plan`.

3. **Human is reviewing the spec (gate open).** → **Speculative execution**: pre-run
   `see-big-picture` and draft the plan against the current spec; discard/rebase if the approved
   spec diverges. → `orchestrate-feature` step 2→4 overlap.

4. **verify→review→apply loop has run 4× on the same finding.** → **Circuit breaker** trips,
   escalates to `try-different-approach`; **exponential backoff** on retries prevents thrash. →
   gate behaviour table.

5. **6 micro-services each need the same lint fix.** → **Map-reduce**: map one fix-agent per service
   (work-stealing over the 5–6 cap), reduce into a single consolidated review. →
   `run-agents-in-parallel`.

6. **Telemetry shows `challenge-spec` is skipped 70% of the time for "fix" tasks.** →
   **Thompson-sampling bandit** proposes a "fix" chain variant that drops `challenge-spec`; A/B's it
   against the full chain on gate-block rate. → `analyse-routing`.

7. **Agent pool of 6, 14 independent tasks queued.** → **Work-stealing scheduler**: idle agents pull
   from a shared queue instead of static round-robin, keeping all 6 saturated. → `spawn-subagent`.

8. **Three plausible architectures, none clearly best.** → **Speculative fan-out + tournament**:
   spike all three in parallel worktrees, score with parallel judges, keep the winner, discard the
   rest. → `spike-it` + `run-agents-in-parallel` + `keep-both-sides`.

9. **Two parallel agents both edited `config.yaml`.** → Detect the conflict-graph edge that was
   missed; **optimistic concurrency** — let both proceed, **3-way merge** at the join barrier,
   re-dispatch only on true conflict. → `run-agents-in-parallel` "When overlap happens anyway".

10. **`finish-branch` merge fails CI after 4 parallel features landed.** → **Saga compensation**
    unwinds the failing feature's commits without touching the other 3; **git bisect** localizes
    which merge broke CI. → `orchestrate-feature` step 8 + `finish-branch`.

---

## Suggested build order

1. **Parallel-layer DAG executor** (A / #1 / #2 / #3) — upgrades `orchestrate-feature` step 5 and
   reuses conflict-graph + topological-sort work as one coherent piece. Cleanest first build.
2. **Semantic routing** (#1 framework) — already scaffolded; single point every request flows through.
3. **Bandit/Markov policy** (B / #6) — highest long-term payoff, but needs telemetry to accumulate
   real data first. Phase 2.
