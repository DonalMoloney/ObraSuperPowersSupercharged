# Skill & Plugin Manifest

Generated 2026-06-11 from the filesystem (`SKILL.md` count). The filesystem is the
source of truth — README/CLAUDE.md prose counts may lag behind promotions/removals.

## Totals

| Tier | Skills | Plugins | Notes |
|---|---:|---:|---|
| v1 (supercharged obra core) | 14 | 0 | Flat layout, all 14 upstream identities, all supercharged |
| v2 (supporting skills/plugins) | 42 | 4 | 36 standalone skills + 6 skills embedded in 2 toolkit plugins |
| v3 (experimental AI ideas) | 12 | 0 | All `status: experimental` |
| v4 (Karpathy/Cherny tools) | 6 | 0 | 3 Karpathy-inspired, 3 Cherny-inspired |
| v5 (Forge fork holding area) | 84 | 0 | 70 flat + 14 nested in 8 fork category folders |
| frontend (domain folder) | 8 | 0 | Browser-tool-driven; clusters: design/verify/debug/perf |
| **Total** | **166** | **4** | |

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

## v2 — Supporting skills (36) and plugins (4)

Every v2 skill names the v1 skill(s) it supports (`supports:` frontmatter).
Impact: multiplies v1 — tighter loops, stronger gates, parallel throughput.

| Group | Count | Skills | Impact |
|---|---:|---|---|
| Planning & ideation amplifiers | 8 | red-team-spec, scouter, fusion-dance, write-adr, decision-ledger, scope-decomposition, track-assumption, compile-goal-to-contract | Stress-test specs, record decisions/assumptions, decompose scope before execution |
| Debugging amplifiers | 7 | loop-until-green, zenkai-boost, instant-transmission, dragon-radar, kaioken, incident-postmortem, delta-debugger | Faster fault isolation, post-incident learning, automated shrink-the-repro |
| Verification & quality gates | 5 | done-gate, blast-radius, devils-advocate, security-audit, gravity-chamber | Hard "done" criteria, impact analysis, adversarial self-review, security pass |
| Parallel & subagent orchestration | 6 | merge-parallel-results, parallel-plan-executor, shenron-wish, dispatch-triage, reviewer-lenses, migrate-codebase | Plan-level fan-out, result merging, multi-lens parallel review, bulk migration |
| Skill authoring & meta | 4 | compress-md, skill-lint, house-rules, hyperbolic-time-chamber | Keeps the skill library itself lean, linted, and consistent |
| Git workflow | 2 | spike-in-worktree, hoi-poi-capsule | Throwaway spikes and workspace capture/restore on top of worktrees |
| Session continuity | 2 | session-handoff, senzu-bean | Survive context loss; recover mid-plan execution |
| Review flow | 1 | review-clarification-gate | Blocks acting on ambiguous review feedback |
| Retro | 1 | post-merge-retro | Closes the loop after merge |

| Plugin | Components | Supports (v1) | Impact |
|---|---|---|---|
| verification-gate | Stop + PostToolUse hooks, `/verify-status` | verification-before-completion, test-driven-development | Enforces verification mechanically — can't claim done without evidence |
| bug-hunter | 6 hunter agents, 1 verifier agent, `/hunt-bugs` | systematic-debugging, requesting-code-review | Parallel adversarial bug sweep with independent verification |
| chrome-devtools-toolkit | 3 skills: browser-evidence-debugging, performance-trace-audit, memory-leak-hunt | systematic-debugging, verification-before-completion | DevTools-MCP-driven evidence for browser bugs, perf, and leaks |
| playwright-toolkit | 3 skills: ui-verification-loop, bug-reproduction-script, e2e-test-generation | verification-before-completion, systematic-debugging, test-driven-development | Playwright-MCP-driven UI proof, repro scripts, and E2E generation |

## v3 — Experimental AI ideas (12 skills)

All `status: experimental`; creativity over polish. Impact: an idea pipeline —
graduates rewrite to v2 standards.

| Theme | Count | Skills |
|---|---:|---|
| Self-improving skills | 3 | skill-darwin, skill-scar-tissue, skill-cannibal |
| Swarms & ecology | 3 | agent-bazaar, predator-prey-review, parliament-of-ghosts |
| Memory & learning | 3 | project-hippocampus, belief-ledger, inherited-instincts |
| Simulation | 3 | ghost-run, premortem-multiverse, branch-historian |

## v4 — Karpathy/Cherny-inspired tools (6 skills)

Each cites its source idea (`inspiration:` frontmatter + Provenance section).
Impact: operationalizes published agentic-coding doctrine as concrete tools.

| Originator | Count | Tools |
|---|---:|---|
| Karpathy | 3 | fast-verify-loop, autonomy-slider, cognitive-prosthetics |
| Cherny | 3 | verification-target-first, fresh-context-review, bash-first-tooling |

## v5 — Forge fork holding area (84 skills)

Imported verbatim from `superpowers2/skills/`; no tier discipline. Impact:
raw material — promotion candidates for v1–v4, idea fodder elsewhere.
Note: CLAUDE.md says 88 and v5/README says 100; on-disk count is 84
(drift from promotions/removals is expected here).

70 flat skills, grouped by function:

| Group | Count | Skills |
|---|---:|---|
| Multi-agent orchestration & parallel execution | 18 | agent-handoff, agent-harness, agent-watchdog, autonomous-issue-runner, background-runner, conflict-graph-scheduler, context-variable-relay, find-parallel-split, hook-message-bus, map-reduce-sweep, orchestrate-feature, parallel-judge-panel, parallel-layer-orchestrator, parallel-run-dashboard, pipeline-parallel, task-dag-planner, wave-runner, worktree-pool |
| Skill ecosystem meta-management | 16 | adaptive-skill-router, analyse-routing, audit-dead-skills, compose-skill-chain, generate-skill-stub, index-skills, judge-skill, pick-skill-path, rename-skill, self-review-skill, semantic-router, skill-dependency-graph, skill-test-harness, smarter-routing-overlay, test-skill, upstream-watcher |
| Verification, judging & integrity | 10 | challenge-implementation, ci-fan-out-gate, consensus-decision, detect-agent-cheats, evidence-trail, exhaustive-audit, hypothesis-ranker, merkle-proof-checkpoint, proof-chain-validator, test-impact-analysis |
| Codebase maintenance & delivery | 10 | bulk-rename, database-migration-planner, dependency-risk-sweep, deprecation-ledger, feature-intake-pipeline, fetch-open-issues, find-dangling-refs, improve-codebase-architecture, spec-from-codebase, write-release-notes |
| Context & communication | 8 | claude-md-watcher, format-markdown-for-claude, format-markdown-for-confluence, progressive-context-recovery, reword-for-clarity, salience-compressor, sample-context-fairly, sync-claude-md |
| Loops & autonomy | 4 | ralph-loop-adapted, scheduled-maintenance, self-pacing-poller, self-repair-loop |
| Utilities & misc | 4 | blastoise, boris-master-setup, graph-algorithms, telemetry-hook |

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
