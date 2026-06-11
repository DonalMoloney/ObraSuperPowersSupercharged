# v4 — Karpathy / Cherny-inspired Claude Code tools

Claude Code tools (skills, agents, hooks) built on the published ideas of
Andrej Karpathy and Boris Cherny.

Rules:
- Frontmatter must include `tier: v4` and `inspiration:` naming the specific idea
  and its originator, e.g. `inspiration: "Karpathy — LLM as OS / context as RAM"`.
- Idea pools to draw from:
  - **Karpathy:** LLM as operating system, autonomy sliders, Software 2.0/3.0,
    context-window-as-RAM discipline, agents that verify their own work, vibe coding
    guardrails.
  - **Cherny (Claude Code creator):** verification loops before claiming success,
    hooks for must-happen rules, do-the-simplest-thing-first, bash-as-universal-tool,
    CLAUDE.md as behavior steering.
- Each tool's SKILL.md includes a "Provenance" section: the idea, where it was stated
  (talk/post/interview), and how the tool operationalizes it.

## Current tools

| Tool | Originator | Idea (source) | Relations |
|------|-----------|---------------|-----------|
| verification-target-first | Cherny | Verification targets before implementation (best-practices post, Apr 2025) | boundary: test-driven-development (v1) |
| fast-verify-loop | Karpathy | Generation–verification loop speed (YC AI Startup School keynote, Jun 2025) | chains-to: loop-until-green (v2) |
| autonomy-slider | Karpathy | Autonomy slider / partial autonomy (YC AI Startup School keynote, Jun 2025) | — |
| fresh-context-review | Cherny | Multi-Claude: one writes, one reviews (best-practices post, Apr 2025) | composes with reviewer-lenses (v2) |
| cognitive-prosthetics | Karpathy | LLM cognitive deficits (Dwarkesh Patel podcast, Oct 2025) | pairs-with: decision-ledger (v2) |
| bash-first-tooling | Cherny | Bash as the universal tool (best-practices post, Apr 2025) | — |
