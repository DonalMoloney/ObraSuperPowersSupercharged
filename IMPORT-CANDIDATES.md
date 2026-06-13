# Import Candidates — skills & plugins from other PycharmProjects folders

Generated 2026-06-13 by surveying every sibling folder under `~/PycharmProjects/`
(excluding `superpowers2/`, which is already imported wholesale as v5). This is a
**catalog only** — nothing here has been imported or built yet. Each row is a
*candidate to adapt*, not a drop-in file.

## How to read this

- **Only v5 is raw-import** (and it is `superpowers2`-only). Every candidate below
  must be **rewritten to its target tier's contract** before it can land:
  - v1 → keep the upstream obra identity, add a `## Supercharged vs upstream` section.
  - v2 → new identity, `supports:` frontmatter naming the v1 skill(s) it amplifies,
    must not duplicate v1.
  - v3 → `status: experimental` frontmatter.
  - v4 → must cite the specific Karpathy/Cherny idea it builds on.
  - frontend → `cluster:` frontmatter + a `## Verification` section with browser-tool evidence.
- **Dedup against the existing 172 skills** (see `MANIFEST.md`). A candidate that
  *shadows* a core obra skill is **v1 improvement material**, not a new import.
- Paths with spaces are quoted where they appear (`"factory templates"`, `"First Plugins"`).

## Counts at a glance

| Bucket | Count | Disposition |
|---|---:|---|
| v4 candidates (Karpathy/Cherny) | 5 | Strongest fit — thinnest tier |
| v2 candidates (orchestration + authoring) | ~12 | Clear gaps, need `supports:` rewrite |
| v1 improvement material (shadow skills) | ~16 | Mine, don't import as new identities |
| Big pack A — local MCP plugins | 12 | Strategic: quadruples plugin count |
| Big pack B — agile/PM domain | ~28 | Strategic: opens a new subject domain |
| Big pack C — `skills/skills` net-new v2 | ~24 | Good but internally redundant; dedup first |
| Skip (out of scope / Copilot-specific / dup) | many | Not recommended |

---

## 🟢 v4 candidates — Karpathy / Cherny tools (strongest fit)

| Candidate | Source path | Purpose | Cited idea | Note |
|---|---|---|---|---|
| `karpathy-think` | `BorisCherneyKarpathy/NEWTOOLS/skills/karpathy-think` | Per-task pre-coding ritual: surface interpretation, alternatives, open questions, record scope | Karpathy: context discipline / autonomy | Lighter per-task variant of v1 `brainstorming` |
| `boris-compound` | `BorisCherneyKarpathy/NEWTOOLS/skills/boris-compound` | Store interlinked lessons-learned after failures with wiki-links | Cherny: compounding practice | Pairs with v2 `incident-postmortem` |
| `boris-worktrees` | `BorisCherneyKarpathy/NEWTOOLS/skills/boris-worktrees` | Judge task parallelizability; predict/guard shared-state collisions | Cherny: worktrees discipline | Could land v2 instead; overlaps v1 `using-git-worktrees` |
| `injecting-context-with-hooks` | `ClaudeSaiyan/.claude/skills/injecting-context-with-hooks` | Inject dynamic context via SessionStart/UserPromptSubmit hooks; per-platform JSON shapes | Cherny: hooks discipline | Advanced Claude Code pattern |
| `commit-message-writer` | `ProjectsWinSharkTank/self-tuning-skills/skills/commit-message-writer` | Staged diff → conventional-commits message | Karpathy/Cherny: do-the-simple-thing | Tiny, high-leverage |

---

## 🟢 v2 candidates — orchestration & authoring gaps

| Candidate | Source path | Purpose | Supports (v1) | Dedup note |
|---|---|---|---|---|
| `parallel-patterns` | `ClaudeWorkflows/plugin/skills/parallel-patterns` | Library of 5 orchestration patterns (adversarial-verify, loop-until-dry, judge-panel, multi-modal-sweep, completeness-critic) | dispatching-parallel-agents | High value; partial overlap w/ v3 `parallel-judge-panel` |
| `dynamic-workflows` | `ClaudeWorkflows/plugin/skills/dynamic-workflows` | JS dynamic workflows with resume + live `/workflows` UI | dispatching-parallel-agents | New substrate vs v1 |
| `headless-orchestration` | `ClaudeWorkflows/plugin/skills/headless-orchestration` | Parallel `claude -p` sessions via shell (CI-friendly fan-out) | dispatching-parallel-agents | Shell variant |
| `error-handling` | `ClaudeWorkflows/plugin/skills/error-handling` | Handle agent failures in workflow scripts (filter(Boolean), defensive schema) | dispatching-parallel-agents | Best-practice codification |
| `orchestrating-parallel-teams` | `ClaudeSaiyan/parallel-worktree-teams/skills/orchestrating-parallel-teams` | 9-phase parallel-team orchestration in isolated worktrees + verification gate | dispatching-parallel-agents, using-git-worktrees | Richer than v1; can coexist |
| `writing-claude-md` | `ClaudeSaiyan/claude-md-authoring/skills/writing-claude-md` | Author effective CLAUDE.md (<200 lines, prune bloat, test rules) | writing-skills | No current equivalent |
| `optimizing-markdown-tokens` | `ClaudeSaiyan/optimizing-markdown-tokens` | Reduce Markdown token count, preserve meaning; backup+diff+approval | writing-skills | Overlaps v2 `compress-md` — compare first |
| `nested-agents-md` | `ultraGithubCopilot/.claude-plugin/skills/nested-agents-md` | Progressive-disclosure AGENTS.md trees with workspace scoping | writing-skills, subagent-driven-development | No dup |
| `smart-init` (plugin) | `"First Plugins"/smart-init` | Project-tailored CLAUDE.md generator (better than `/init`) | writing-skills | Plugin |
| `handoff` | `Handoff/skills/handoff` | Context transfer between AI sessions; save/resume state | session-handoff (v2) | **Overlaps** existing `session-handoff` — mine, don't dup |
| `knowledge-graph` | `KG/skills/knowledge-graph` | Persistent memory layer; mines co-change patterns; distributed CLAUDE.md nodes | — | Maybe; overlaps memory; audit first |
| `capturing-screen` | `screen_capture/skills/capturing-screen` | PNG every display on demand; timestamped evidence | (frontend) visual-verification-loop | Maybe → frontend tier |

### v2 candidates — the "factory" authoring-QA cluster

All under `"factory templates"/skills/`. Cohesive quality-gate set atop existing
`skill-lint` / `skill-test-harness`.

| Candidate | Purpose |
|---|---|
| `agent-factory` | Generate agent definitions with YAML frontmatter |
| `agent-quality-validator` | Validate agent quality (YAML completeness, examples) |
| `command-quality-validator` | Validate slash-command quality vs rubric |
| `hook-factory` | Wire lifecycle hooks with safety + template validation |
| `hook-quality-validator` | Validate hook safety (no secrets, timeout config) |
| `skill-evaluator` | Score skills against an 8-point content rubric |
| `skill-quality-validator` | Score skill structure completeness |
| `slash-command-factory` | Scaffold slash commands with YAML + validation |

---

## 🟡 v1 improvement material — shadow skills (mine, do NOT import as new identities)

These shadow the core obra 14. Per tier rules they are supercharging fuel: read
against upstream obra 5.1.0, fold the best ideas into the existing v1 skill's
`## Supercharged vs upstream` section.

| Shadow skill | Source path | Shadows v1 |
|---|---|---|
| `blueprint` | `skills/skills/blueprint` | executing-plans / writing-plans |
| `brainstorm` | `skills/skills/brainstorm` | brainstorming |
| `clean-commit` | `skills/skills/clean-commit` | finishing-a-development-branch |
| `debug-root-cause` | `skills/skills/debug-root-cause` | systematic-debugging |
| `execute-plan` | `skills/skills/execute-plan` | executing-plans |
| `feature-builder` | `skills/skills/feature-builder` | writing-plans (Explorer→Architect→Reviewer) |
| `finish-branch` | `skills/skills/finish-branch` | finishing-a-development-branch |
| `git-worktree` | `skills/skills/git-worktree` | using-git-worktrees |
| `parallel-subagents` | `skills/skills/parallel-subagents` | dispatching-parallel-agents |
| `push-and-pr` | `skills/skills/push-and-pr` | finishing-a-development-branch |
| `receive-review` | `skills/skills/receive-review` | receiving-code-review |
| `request-review` | `skills/skills/request-review` | requesting-code-review |
| `review-code` | `skills/skills/review-code` | (review flow) |
| `tdd-workflow` | `skills/skills/tdd-workflow` | test-driven-development |
| `verify-before-done` | `skills/skills/verify-before-done` | verification-before-completion |
| `brainstorming-pro` | `ObraSuperPowerBrainstorming/brainstorming-pro` | brainstorming (React companion, agent vision, diff tools) |

`CopilotBetter/library/skills/code-review-advanced` is also v1-improvement-adjacent
(checklist-driven review w/ severity-ranked findings) but is Copilot-flavored — low priority.

---

## 📦 Big pack A — local-first MCP plugins (strategic decision)

12 production-ready TypeScript MCP servers under `PluginIdeas/plugins/`. Importing
all would take the repo from 4 → 16 plugins. Different artifact type (servers, not
skills) with its own maintenance surface.

| Plugin | Purpose |
|---|---|
| `bugtrace` | Bug classification + structured root-cause analysis |
| `codescan` | Severity-weighted review triage + finding suppression |
| `diagnose` | Symptom analysis + diagnostic hypothesis ranking |
| `doclock` | Version-pinned package-doc fetcher/cacher |
| `memstore` | SQLite local memory store w/ TF-IDF retrieval |
| `pagescrape` | Local URL→markdown scraper w/ change-diff |
| `prwriter` | Conventional-commit + PR-body generator from diffs |
| `refactor` | Code-smell detector + refactor-plan generator |
| `scaffold` | Project-scaffold validator + style detector |
| `shipcheck` | Task classifier + checklist pre-ship verdict |
| `taskqueue` | Dependency-aware task queue w/ token-budget tracking |
| `tokentrim` | Text compression w/ real token counting + budget |

---

## 📦 Big pack B — agile / PM domain pack (strategic decision)

~28 skills under `Docs/agile-roles/` (+ vendored copies that duplicate these — import
the toolkit originals only). Opens a subject domain the repo does not currently cover.

**Product-owner-toolkit** (`Docs/agile-roles/product-owner-toolkit/skills/`):
`okr-goal-setting`, `prioritization` (RICE/ICE/WSJF/MoSCoW/Kano), `epic-decomposition`
(SPIDR), `discovery-synthesis`, `prd-spec-author`, `roadmap-builder`, `persona-jtbd`,
`user-story-writer` (INVEST), `backlog-grooming`, `release-notes`, + niche
(`competitive-analysis`, `stakeholder-update`, `sprint-goal`).

**Scrum-master-toolkit** (`Docs/agile-roles/scrum-master-toolkit/skills/`):
`facilitate-retrospective`, `track-impediments`, `detect-agile-antipatterns`,
`plan-capacity`, `measure-flow-metrics`, `analyze-retro-patterns`,
`check-definition-of-done-ready`, `synthesize-daily-standup`,
`manage-dependencies-risks`, `prep-sprint-review`, `facilitate-sprint-planning`.

Highest-value subset if adopted: `epic-decomposition` + `prioritization` +
`roadmap-builder` (idea→plan bridge) and `facilitate-retrospective` +
`detect-agile-antipatterns` + `track-impediments` (feedback loop).

---

## 📦 Big pack C — `skills/skills` net-new v2 set (dedup before import)

~24 non-shadow skills under `skills/skills/`. Good, but **internally redundant**
(four overlapping debug skills; three overlapping review skills) and some overlap
existing v2 — needs a dedup pass before any land.

`claude-lint`, `completion-audit`, `coverage-gaps`, `create-skill`, `cut-the-release`,
`diagnose-bug`, `edit-settings`, `fewer-prompts`, `find-silent-failures`,
`fix-failing-test`, `generate-hooks`, `incident-lead`, `init-project`,
`map-test-coverage`, `pipeline-builder`, `pr-scope-check`, `quick-review`,
`refactor-code`, `refine-claude-md`, `root-cause-diagnosis`, `security-scan`,
`simplify-code`, `skill-spec`, `test-smells`, `trace-bug`.

Overlap flags: `diagnose-bug`/`trace-bug`/`root-cause-diagnosis`/`debug-root-cause`
all overlap (and v1 `systematic-debugging`); `quick-review`/`review-code`/`pr-scope-check`
overlap; `security-scan` overlaps v2 `security-audit`.

---

## ⛔ Skip (not recommended)

| Source | Reason |
|---|---|
| `CopilotBetter/library/skills/*` (~25) | GitHub-Copilot-specific; not portable to Claude Code |
| `ultraGithubCopilot/.../pr-review-optimizer` | Copilot-specific |
| `Marp/skills/creating-marp-decks` | Domain-specific (presentation tooling) |
| `ClaudeSaiyan/pdf-to-markdown` | Domain utility; weak fit for a skill-engineering repo |
| `screen_capture` plugin (beyond `capturing-screen`) | Niche OS utility |
| `understandanything2.0/nexus-plugin` | Niche KG visualization |
| `Swarm` plugin | Overlaps `dynamic-workflows`; likely redundant |
| `webscrape`, `CustomPlaywrightMCP`, `knowledgegraph` | In-progress; no publishable SKILL.md |
| anything under `superpowers2/` | Already imported as v5 |
| `TestSkillsPlugin`, `cc-plugin-eval`, `MathSkillsPlugins` | Test fixtures / unrelated harness / algorithm notes |
