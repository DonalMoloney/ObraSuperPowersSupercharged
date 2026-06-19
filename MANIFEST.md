# Skill & Plugin Manifest

Generated 2026-06-13 from the filesystem (`SKILL.md` count). The filesystem is the
source of truth — README/CLAUDE.md prose counts may lag behind promotions/removals.
Regenerate counts with `find v1 v2 v3 v4 v5 frontend -name SKILL.md | wc -l`.

**Recent changes (2026-06-13):** three batches landed. (1) **12 fork skills promoted** out of
v5 into the committed tiers (9 → v2, 2 → v3, 1 → v4), so v5 dropped 84 → 72 and the disk
total was unchanged by that batch. (2) **6 net-new idea-sourced skills** designed from
`SelfImprovingAgent/TOPIDEAS.md` (5 → v3 self-improvement loop, 1 → v4 `selective-priming`),
raising the disk total 166 → 172. (3) **Cross-repo import wave** (from `IMPORT-CANDIDATES.md`,
marked ⬇ below): v4 `karpathy-think` + `boris-compound`; v2 `semantic-skill-router`,
`skill-graph`, `eval-driven-dev` (plus previously-undocumented `ubiquitous-language`); and a
new v2 plugin `skill-quality-gate` (skills `skill-evaluator` + `skill-quality-validator`) —
disk total → 180, plugins → 5. See `MANIFESTFLOW.html` for the commitment/build-on view.

> **Snapshot note:** the counts below are a point-in-time census taken 2026-06-13 15:33 local.
> Concurrent sessions are actively importing, so a live `find` may already exceed these —
> regenerate with the command above before relying on exact totals.

## Totals

| Tier | Skills | Plugins | Notes |
|---|---:|---:|---|
| v1 (supercharged obra core) | 14 | 0 | Flat layout, all 14 upstream identities, all supercharged |
| v2 (supporting skills/plugins) | 57 | 5 | 49 standalone skills + 8 skills embedded in 3 of the 5 toolkit plugins |
| v3 (experimental AI ideas) | 19 | 0 | All `status: experimental` |
| v4 (Karpathy/Cherny tools) | 10 | 0 | 5 Karpathy-inspired, 5 Cherny-inspired |
| v5 (Forge fork holding area) | 72 | 0 | 58 flat + 14 nested in 8 fork category folders |
| v7 (tool ports as plugins) | 1 | 1 | autoresearch — Karpathy AutoResearch keep-or-revert loop (1 embedded skill) |
| frontend (domain folder) | 8 | 0 | Browser-tool-driven; clusters: design/verify/debug/perf |
| **Total** | **181** | **6** | |

## v1 — Core workflow backbone (14 skills)

The supercharged obra superpowers core. Every other tier exists to support,
extend, or experiment around these. Impact: defines the engineering loop itself —
ideate → plan → isolate → implement (TDD) → debug → verify → review → finish.

| Group | Skills | Impact |
|---|---|---|
| Ideation & planning | brainstorming, writing-plans, executing-plans | Front-loads intent and design before code is touched |
| Implementation discipline | test-driven-development, systematic-debugging | RED-GREEN rigor and hypothesis-driven bug fixing |
| Verification & review | verification-before-completion, requesting-code-review, receiving-code-review | Evidence before assertions; review as a two-way protocol |
| Parallelism & delegation | dispatching-parallel-agents, subagent-driven-development | Fan-out of independent work to subagents |
| Workspace & completion | using-git-worktrees, finishing-a-development-branch | Isolation per effort; structured merge/PR/cleanup exits |
| Meta | using-superpowers, writing-skills | Skill discovery and skill authoring discipline |

## v2 — Supporting skills (49) and plugins (5)

Every v2 skill names the v1 skill(s) it supports (`supports:` frontmatter).
Impact: multiplies v1 — tighter loops, stronger gates, parallel throughput.
The 2026-06-13 promotion batch added 9 skills (marked ⬆); the cross-repo import
wave added more (marked ⬇).

| Group | Count | Skills | Impact |
|---|---:|---|---|
| Planning & ideation amplifiers | 11 | red-team-spec, scouter, fusion-dance, write-adr, decision-ledger, scope-decomposition, track-assumption, compile-goal-to-contract, spec-from-codebase ⬆, database-migration-planner ⬆, ubiquitous-language | Stress-test specs, record decisions/assumptions, decompose scope, reverse-spec undocumented code, risk-assess migrations, extract a DDD ubiquitous-language glossary |
| Debugging amplifiers | 8 | loop-until-green, zenkai-boost, instant-transmission, dragon-radar, kaioken, incident-postmortem, delta-debugger, hypothesis-ranker ⬆ | Faster fault isolation, post-incident learning, shrink-the-repro, Bayesian hypothesis ranking |
| Verification & quality gates | 9 | done-gate, blast-radius, devils-advocate, security-audit, gravity-chamber, evidence-trail ⬆, test-impact-analysis ⬆, detect-agent-cheats ⬆, eval-driven-dev ⬇ | Hard "done" criteria, impact analysis, adversarial self-review, security pass, hash-chained evidence, test selection, subagent-cheat audit, eval-suite-driven iteration for LLM features |
| Parallel & subagent orchestration | 7 | merge-parallel-results, parallel-plan-executor, shenron-wish, dispatch-triage, reviewer-lenses, migrate-codebase, conflict-graph-scheduler ⬆ | Plan-level fan-out, result merging, multi-lens review, bulk migration, pre-dispatch independence/conflict analysis |
| Skill authoring & meta | 7 | compress-md, skill-lint, house-rules, hyperbolic-time-chamber, skill-test-harness ⬆, semantic-skill-router ⬇, skill-graph ⬇ | Keeps the skill library lean, linted, consistent, behaviorally tested, uncertainty-aware-routed, and graph-validated |
| Git workflow | 2 | spike-in-worktree, hoi-poi-capsule | Throwaway spikes and workspace capture/restore on top of worktrees |
| Session continuity | 2 | session-handoff, senzu-bean | Survive context loss; recover mid-plan execution |
| Review flow | 1 | review-clarification-gate | Blocks acting on ambiguous review feedback |
| Retro & delivery | 2 | post-merge-retro, write-release-notes ⬆ | Closes the loop after merge; drafts user-facing release notes at finish time |

| Plugin | Components | Supports (v1) | Impact |
|---|---|---|---|
| verification-gate | Stop + PostToolUse hooks, `/verify-status` | verification-before-completion, test-driven-development | Enforces verification mechanically — can't claim done without evidence |
| bug-hunter | 6 hunter agents, 1 verifier agent, `/hunt-bugs` | systematic-debugging, requesting-code-review | Parallel adversarial bug sweep with independent verification |
| chrome-devtools-toolkit | 3 skills: browser-evidence-debugging, performance-trace-audit, memory-leak-hunt | systematic-debugging, verification-before-completion | DevTools-MCP-driven evidence for browser bugs, perf, and leaks |
| playwright-toolkit | 3 skills: ui-verification-loop, bug-reproduction-script, e2e-test-generation | verification-before-completion, systematic-debugging, test-driven-development | Playwright-MCP-driven UI proof, repro scripts, and E2E generation |
| skill-quality-gate ⬇ | PostToolUse hook, `/skill-score`, 2 skills: skill-evaluator, skill-quality-validator | writing-skills, skill-lint, skill-test-harness | Mechanical pre-merge skill-quality scoring (structural shape + content rubric); warns by default, can block |

## v3 — Experimental AI ideas (19 skills)

All `status: experimental`; creativity over polish. Impact: an idea pipeline —
graduates rewrite to v2 standards. The 2026-06-13 work added 7 skills (⬆ promoted
from v5; ★ net-new, designed from `SelfImprovingAgent/TOPIDEAS.md`).

| Theme | Count | Skills |
|---|---:|---|
| Self-improving skills | 3 | skill-darwin, skill-scar-tissue, skill-cannibal |
| Self-improving harness loop | 5 | eval-suite-from-git ★, eval-gated-evolution-loop ★, two-speed-evolution ★, cross-model-harness-transfer ★, meta-evolution ★ |
| Swarms & ecology | 4 | agent-bazaar, predator-prey-review, parliament-of-ghosts, parallel-judge-panel ⬆ |
| Memory & learning | 3 | project-hippocampus, belief-ledger, inherited-instincts |
| Simulation | 3 | ghost-run, premortem-multiverse, branch-historian |
| Routing | 1 | semantic-router ⬆ |

## v4 — Karpathy/Cherny-inspired tools (10 skills)

Each cites its source idea (`inspiration:` frontmatter + Provenance section).
Impact: operationalizes published agentic-coding doctrine as concrete tools.
The 2026-06-13 work added boris-master-setup ⬆ (promoted from v5) and
selective-priming ★ (net-new, Karpathy context-as-RAM, from SelfImprovingAgent ideas);
the cross-repo import wave then added karpathy-think ⬇ (think-before-coding ritual) and
boris-compound ⬇ (compounding lessons-learned).

| Originator | Count | Tools |
|---|---:|---|
| Karpathy | 5 | fast-verify-loop, autonomy-slider, cognitive-prosthetics, selective-priming ★, karpathy-think ⬇ |
| Cherny | 5 | verification-target-first, fresh-context-review, bash-first-tooling, boris-master-setup ⬆, boris-compound ⬇ |

## v5 — Forge fork holding area (72 skills)

Imported verbatim from `superpowers2/skills/`; no tier discipline. Impact:
raw material — promotion candidates for v1–v4, idea fodder elsewhere.
Note: CLAUDE.md says 88 and v5/README says 100; on-disk count is 72 after the
2026-06-13 promotion of 12 skills into v1–v4 (drift from promotions/removals is
expected here).

58 flat skills, grouped by function:

| Group | Count | Skills |
|---|---:|---|
| Multi-agent orchestration & parallel execution | 16 | agent-handoff, agent-harness, agent-watchdog, autonomous-issue-runner, background-runner, context-variable-relay, find-parallel-split, hook-message-bus, map-reduce-sweep, orchestrate-feature, parallel-layer-orchestrator, parallel-run-dashboard, pipeline-parallel, task-dag-planner, wave-runner, worktree-pool |
| Skill ecosystem meta-management | 14 | adaptive-skill-router, analyse-routing, audit-dead-skills, compose-skill-chain, generate-skill-stub, index-skills, judge-skill, pick-skill-path, rename-skill, self-review-skill, skill-dependency-graph, smarter-routing-overlay, test-skill, upstream-watcher |
| Verification, judging & integrity | 6 | challenge-implementation, ci-fan-out-gate, consensus-decision, exhaustive-audit, merkle-proof-checkpoint, proof-chain-validator |
| Codebase maintenance & delivery | 7 | bulk-rename, dependency-risk-sweep, deprecation-ledger, feature-intake-pipeline, fetch-open-issues, find-dangling-refs, improve-codebase-architecture |
| Context & communication | 8 | claude-md-watcher, format-markdown-for-claude, format-markdown-for-confluence, progressive-context-recovery, reword-for-clarity, salience-compressor, sample-context-fairly, sync-claude-md |
| Loops & autonomy | 4 | ralph-loop-adapted, scheduled-maintenance, self-pacing-poller, self-repair-loop |
| Utilities & misc | 3 | blastoise, graph-algorithms, telemetry-hook |

14 skills nested in the fork's 8 category folders:

| Category folder | Count | Skills |
|---|---:|---|
| problem-solving/ | 5 | when-stuck, simplification-cascades, meta-pattern-recognition, inversion-exercise, scale-game |
| debugging/ | 2 | root-cause-tracing, defense-in-depth |
| testing/ | 2 | testing-anti-patterns, condition-based-waiting |
| architecture/ | 1 | write-adr |
| collaboration/ | 1 | multi-agent-architecture-patterns |
| context/ | 1 | memory-systems-design |
| documentation/ | 1 | summarize-session |
| research/ | 1 | tracing-knowledge-lineages |

## frontend — Domain folder (8 skills)

Browser-tool-driven (Chrome DevTools MCP / Playwright MCP); every skill ends with
a `## Verification` section. Impact: proven-not-asserted frontend quality across
design, verification, debugging, and performance.

| Cluster | Count | Skills | Impact |
|---|---:|---|---|
| design | 2 | design-direction-first, design-system-first | Direction and system tokens settled before pixels are pushed |
| verify | 2 | visual-verification-loop, a11y-and-audit-gate | Screenshot/audit evidence gates on every UI change |
| debug | 2 | frontend-bug-forensics, layout-break-hunt | Console/network/layout evidence-driven bug isolation |
| perf | 2 | web-vitals-triage, render-and-bundle-discipline | Trace-backed vitals triage and render/bundle budgets |

## v7 — Tool ports as runnable plugins (1 skill, 1 plugin)

Ports of specific published AI tools/artifacts into installable Claude Code plugins —
distinct from v4, which distills *ideas*. Each port preserves the source's core invariant
and ships a deterministic, runnable example. Impact: real, installable tools rather than
guidance.

| Plugin | Skill | Source artifact | What it does |
|---|---|---|---|
| autoresearch | autoresearch-loop | Karpathy AutoResearch (open-sourced 2026-03-07) | Domain-general keep-or-revert optimization loop: the harness owns accept/reject, a fresh `claude -p` proposer edits one artifact per iteration inside an isolated git worktree, kept only if a measurable metric improves. Ships a `/autoresearch` command and a deterministic `hillclimb` example. |
