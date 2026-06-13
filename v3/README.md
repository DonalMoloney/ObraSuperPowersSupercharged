# v3 — Crazy AI ideas

Experimental, ambitious, weird. The quality bar of v1/v2 does not apply here —
the only requirement is that ideas are captured well enough to evaluate later.

Rules:
- Frontmatter must include `tier: v3` and `status: experimental`.
- Each skill includes a short "Why this might be crazy enough to work" section.
- Graduating a v3 idea means rewriting it to v2 standards and moving it to `v2/`.

## Current skills

| Skill | Theme | One-line hook |
|-------|-------|---------------|
| `skill-darwin` | Self-improving | Skill text evolves via variant A/B testing and fitness-scored mutation |
| `skill-scar-tissue` | Self-improving | Failures graft probationary rules onto the skill that should have prevented them |
| `skill-cannibal` | Self-improving | Skills compete for a token budget; underperformers get eaten or fused |
| `agent-bazaar` | Swarms & ecology | Subagents bid for tasks with sealed cost estimates; blown estimates cost reputation |
| `predator-prey-review` | Swarms & ecology | Adversarial reviewers score only for bugs the author didn't already know about |
| `parliament-of-ghosts` | Swarms & ecology | Five persona-agents vote on big decisions with track-record-weighted ballots |
| `project-hippocampus` | Memory & learning | Episodic session memories with an Ebbinghaus forgetting curve |
| `belief-ledger` | Memory & learning | Load-bearing assumptions tracked as probabilities; collapses trigger decision audits |
| `inherited-instincts` | Memory & learning | A cross-project genome of pattern→emotion reflexes, surfaced as gut feelings |
| `ghost-run` | Simulation | Hallucinate the whole plan execution first; halt the real run on divergence |
| `premortem-multiverse` | Simulation | Parallel doom-genre incident reports; convergent failure chains become tests |
| `branch-historian` | Simulation | Spike the road not taken in throwaway worktrees; return a regret report |
| `semantic-router` | Routing | Embeds the task and kNN-searches a skill-description index to suggest skills — experimental overlay on `using-superpowers` |
| `parallel-judge-panel` | Swarms & ecology | N solutions from different angles, scored by a blind judge panel, then best picked or synthesized |
| `eval-suite-from-git` | Self-improving | Mines bug-fix / reverted commits from git history into a regression eval suite (the fix's own test = the check) |
| `eval-gated-evolution-loop` | Self-improving | Mine→diagnose→propose one harness edit→re-run evals→keep iff score rose, else revert + archive the variant |
| `two-speed-evolution` | Self-improving | Free in-session Haiku friction capture + a separate gated overnight pass; only the gated path may touch the harness |
| `cross-model-harness-transfer` | Self-improving | Evolve the harness cheap on Haiku, freeze, deploy on Opus; a held-out eval slice re-verifies the transfer |
| `meta-evolution` | Self-improving | The loop tunes its own thresholds from tracked metrics, with gaming-detection vetoing suspicious score jumps |

## Idea backlog

Captured but not yet built ideas live in [`IDEAS.md`](IDEAS.md) (mirrors `v4/IDEAS.md`).
Current batch: a **self-improving harness** theme (eval suite from git history → eval-gated
evolution loop → falsification ledger → …), sourced from `SelfImprovingAgent/TOPIDEAS.md`,
with a dedup map against the existing self-improving / memory skills above. **Built 2026-06-13**
via the `moonshot-ideator` agent — the 5 v3 skills now in the table above, plus a v4
`selective-priming` (Karpathy context-as-RAM). Remaining ideas (falsification ledger,
8-component harness, delta-memory/ACE) stay deferred until the loop demonstrably climbs a score.
