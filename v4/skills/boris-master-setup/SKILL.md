---
name: boris-master-setup
description: Use when setting up a new (or under-configured) repo for agentic coding — runs the opinionated "Configure your environment" checklist (CLAUDE.md, permissions allowlist, hooks, custom commands/skills, CLI tools, env tuning) so the project is configured for reliable Claude Code work from day one
tier: v4
inspiration: "Cherny — \"Configure your environment\": a few setup steps (effective CLAUDE.md, permission allowlists, hooks for must-happen rules, CLI tools, custom commands/skills/subagents) make Claude Code significantly more effective across every session (Claude Code: Best practices for agentic coding, Anthropic engineering blog, April 2025)"
---

# Boris Master Setup

**Not this skill if:**

- You already have a configured repo and are mid-task deciding whether to reach for a new MCP server / dependency for ONE capability → v4 `bash-first-tooling` owns the cheapest-tool-that-works ladder. That skill is the narrow "Use CLI tools" rung; THIS skill is the whole "Configure your environment" checklist around it.
- You are choosing how much autonomy a single task gets before a human verifies → v4 `autonomy-slider`.
- You want must-happen verification at the END of a task (run the check before claiming success) → that is a per-task discipline; this skill installs the *standing infrastructure* (a Stop hook, a verify subagent) that makes verification cheap, but doesn't run the loop for you.

This is a one-time-per-repo setup pass. The output is committed config under `.claude/` plus a `CLAUDE.md`, so every future session inherits it. Walk the checklist top to bottom; skip a rung only when the repo genuinely has no use for it (say which and why).

## The checklist

Each rung names the Cherny recommendation, the file it writes, and a stop-rule (when the rung is done). Do the simplest thing that satisfies the rung — do not pre-build config the repo has no use for yet.

| # | Rung | File written | Done when |
|---|------|--------------|-----------|
| 1 | **Effective CLAUDE.md** | `./CLAUDE.md` | The file holds only things Claude can't infer from code (build/test commands, non-default style rules, repo etiquette, env quirks, known gotchas) and is short enough that every line passes "would removing this cause a mistake?" |
| 2 | **Permission allowlist** | `.claude/settings.json` → `permissions.allow` | The handful of safe, repeated commands (test, lint, build, `git commit`) are allowlisted so they stop prompting |
| 3 | **Hooks for must-happen rules** | `.claude/settings.json` → `hooks` | At least the deterministic rules that prose can't guarantee are hooks (e.g. format-after-edit) — not CLAUDE.md sentences |
| 4 | **Verify-the-work infrastructure** | a Stop hook and/or `.claude/agents/` reviewer | Claude has a check it can run unattended (test/build gate as a Stop hook, or a fresh-context review subagent) |
| 5 | **Custom commands / skills** | `.claude/skills/` (or `.claude/commands/`) | Each repeated multi-step workflow (e.g. "verify, then commit, then open PR") is one invocation, not re-typed every time |
| 6 | **CLI tools documented** | `./CLAUDE.md` (Tools section) | The external-service CLIs this repo uses (`gh`, `aws`, `sentry-cli`, project scripts) are named with their invocation — defer the ladder details to `bash-first-tooling` |
| 7 | **Environment tuning** | `.claude/settings.json` → `env` (only if needed) | Any genuinely-needed env var is set in settings, not a shell wrapper — but only add one you can name a reason for |

Probe before you write: run `ls .claude/ 2>/dev/null`, `cat CLAUDE.md 2>/dev/null`, and detect the test/lint/build commands from `package.json` / `pyproject.toml` / `Makefile` / `go.mod`. Configure from what the repo actually is, not a template.

## Rung details

### 1. Effective CLAUDE.md

`/init` generates a starter; refine it. Cherny's rule: CLAUDE.md loads every session, so include only what Claude can't figure out by reading code, and prune ruthlessly — a bloated file gets ignored.

Include: bash commands Claude can't guess, code-style rules that differ from defaults, test runner/instructions, repo etiquette (branch/PR conventions), project-specific architectural decisions, dev-env quirks (required env vars), non-obvious gotchas.

Exclude: anything inferable from code, standard language conventions, detailed API docs (link instead), info that changes often, self-evident advice ("write clean code").

Test per line: *"Would removing this cause Claude to make a mistake?"* If not, cut it. Check the file into git. Use `@path` imports to keep the root file lean (`@README.md`, `@docs/git-instructions.md`).

### 2. Permission allowlist

By default Claude prompts before file writes and Bash commands — safe but tedious, and after the tenth approval you're rubber-stamping. Allowlist the specific, safe, repeated commands via `/permissions` or by hand in `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run test:*)",
      "Bash(npm run lint:*)",
      "Bash(git commit:*)"
    ]
  }
}
```

Allowlist only what you know is safe. (Auto mode and sandboxing exist for broader cases; allowlists are the day-one default.)

### 3. Hooks for must-happen rules

Cherny's distinction: CLAUDE.md instructions are advisory; hooks are deterministic and guarantee the action happens every time. Anything that MUST happen with zero exceptions is a hook, not a sentence. The most common is format-after-edit:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "<your formatter> || true" }]
      }
    ]
  }
}
```

Claude can write hooks for you ("write a hook that runs eslint after every file edit"; "write a hook that blocks writes to the migrations folder"). Browse configured hooks with `/hooks`.

### 4. Verify-the-work infrastructure

Cherny's headline: *"Give Claude a check it can run... the difference between a session you watch and one you walk away from."* Install standing infrastructure so the verification loop closes itself:

- **Deterministic gate** — a `Stop` hook that runs your test/build script and blocks the turn from ending until it passes.
- **Second opinion** — a fresh-context reviewer in `.claude/agents/` (or the bundled `/code-review` skill) that sees only the diff, so the agent doing the work isn't the one grading it.

```markdown .claude/agents/diff-reviewer.md
---
name: diff-reviewer
description: Reviews the current diff in a fresh context for bugs and missing tests
tools: Read, Grep, Glob, Bash
---
Review the staged diff for bugs, missing edge-case tests, and scope creep.
Report only gaps that affect correctness or stated requirements. Do not approve — surface issues.
```

### 5. Custom commands / skills

Turn each repeated multi-step workflow into one invocation under `.claude/skills/` (model-invoked) or `.claude/commands/`. Use `disable-model-invocation: true` for workflows with side effects you want to trigger by hand:

```markdown .claude/skills/ship/SKILL.md
---
name: ship
description: Verify, then commit, then open a PR
disable-model-invocation: true
---
1. Run the test suite and the linter; show the output. Stop if either fails.
2. Review the diff for scope creep.
3. Commit with a message explaining WHY, then open a PR.
```

### 6. CLI tools documented

CLI tools are the most context-efficient way to hit external services. Name the ones this repo uses in CLAUDE.md so they persist:

```markdown
# Tools
- `gh pr create` — open PRs (install gh; avoids unauthenticated API rate limits)
- `sentry-cli issues list --status unresolved` — check production errors
```

The acquisition gate (existing CLI → composition → script → MCP) is `bash-first-tooling`'s job; here you just record what's already in use.

### 7. Environment tuning

If — and only if — the repo genuinely needs an env var, set it in `.claude/settings.json` under `"env"` rather than a shell wrapper, so the whole team inherits it. Add nothing you can't justify.

## Closing the loop

Commit `.claude/settings.json`, `.claude/skills/`, `.claude/agents/`, and `CLAUDE.md` to git. One engineer runs this setup; the whole team and every future session inherits it. CLAUDE.md compounds in value — treat it like code: review it when Claude goes wrong, prune it regularly, and verify a change by watching whether Claude's behavior actually shifts.

## Provenance

- **Idea (Cherny):** "A few setup steps make Claude Code significantly more effective across all your sessions." The post's **"Configure your environment"** section prescribes the standing config a repo should have: an effective CLAUDE.md (only what Claude can't infer, pruned ruthlessly because a bloated file gets ignored), permission allowlists for safe repeated commands, **hooks** for "actions that must happen every time with zero exceptions" (advisory CLAUDE.md vs. deterministic hooks), CLI tools as "the most context-efficient way to interact with external services", and custom skills/subagents for reusable workflows and isolated review. The companion headline — "Give Claude a way to verify its work" — motivates rung 4's Stop-hook gate and review subagent.
- **Where stated:** "Claude Code: Best practices for agentic coding", Anthropic engineering blog, April 2025, authored by Boris Cherny (Claude Code's creator; announced by Cherny via Threads, April 2025). The live URL `anthropic.com/engineering/claude-code-best-practices` now 308-redirects into the Claude Code docs ("Best practices for Claude Code"), whose **"Configure your environment"** section preserves the same subsection headings used as rung names above: "Write an effective CLAUDE.md", "Configure permissions", "Set up hooks", "Use CLI tools", "Create skills", "Create custom subagents". Verified via web fetch of the redirected docs, June 2026.
- **How this tool operationalizes it:** It turns the prose "Configure your environment" section into a seven-rung, probe-first setup checklist — each rung names the Cherny recommendation, the exact `.claude/` file it writes, and a done-when stop-rule — so a fresh repo ends the pass with a committed, team-shared agentic-coding scaffold. It deliberately delegates the narrow "Use CLI tools" acquisition decision to v4 `bash-first-tooling` and the per-task autonomy choice to v4 `autonomy-slider`, keeping one tool to one idea.
