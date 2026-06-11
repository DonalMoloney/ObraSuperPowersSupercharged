---
name: boris-master-setup
description: >-
  Complete Claude Code setup guide synthesized from Boris Cherny, Andrej Karpathy,
  Thorsten Ball, Simon Willison, Geoffrey Litt, Paul Copplestone, and Matt Rickard.
  Use when: setting up a new project for Claude Code, creating or improving CLAUDE.md
  or AGENTS.md, asking what hooks/subagents/slash commands to create, configuring
  permissions, choosing a model/effort level, asking about worktrees or parallel
  sessions, building a skill, or troubleshooting context rot or doom loops.
  Triggers: "set up Claude Code", "what should be in my CLAUDE.md", "hooks to add",
  "best practices", "how should I configure", "Karpathy rules", "Boris setup".
---

# Master Claude Code Setup — Boris + Karpathy + Community

Everything actionable from the full IAMBoris research library. Organized by what to do, not by who said it.

---

## Quick-Start Checklist

- [ ] Create `CLAUDE.md` with `@AGENTS.md`
- [ ] Create `AGENTS.md` with: test command, TDD instruction, task classification, context limit, failure recovery, check-in protocol, git discipline
- [ ] Add formatter hook to `.claude/settings.json`
- [ ] Add pre-approved permissions for test/lint commands
- [ ] Create `code-simplifier` and `verify-app` subagents in `.claude/agents/`
- [ ] Create `/go` slash command in `.claude/commands/`
- [ ] Add Playwright MCP: `claude mcp add playwright npx '@playwright/mcp@latest'`
- [ ] Set `CLAUDE_CODE_AUTO_COMPACT_WINDOW=400000` in settings.json env
- [ ] Build a Product Verification skill for your specific app
- [ ] Run `/fewer-permission-prompts` after first week to tune allowlist

---

## 1. CLAUDE.md + AGENTS.md Structure

**CLAUDE.md** — keep it minimal, just a pointer:
```
@AGENTS.md
```

**AGENTS.md** — full template to start with:

```markdown
# Project: <name>

## Running the project
<exact command to start dev server>

## Running tests
<exact test command — e.g. uv run pytest / npm test / go test ./...>

## Code style
- Run <formatter> before committing

## TDD — always
Write a failing test. Watch it fail. Make it pass. Commit test + implementation together.

## Task classification
- For secondary tasks (docs, TypeScript fixes, exploratory spikes): work autonomously
- For core design decisions or critical path changes: stop and ask before proceeding
- When unsure: ask

## Context discipline
- Start a new conversation thread if context exceeds 100k tokens
- Do not attempt to continue from a degraded context window

## Verification
- After every fix, verify it actually works — run the test, start the server, take a screenshot
- A fix without verification is incomplete

## Failure recovery
- If an approach fails after 2–3 attempts, stop and reconsider
- Try a different method, check documentation, inspect the error carefully
- Do not loop on the same failing approach

## Check-in protocol
- After completing each logical unit of work, pause and summarize: what was done, what decision was made and why, what comes next
- Do not chain multiple units silently

## Git discipline
- Stage successful changes immediately after each working step
- Use git diff to review your own work before marking a task complete
- Remove debug statements in a separate thread after verification

## Task framing (required for complex tasks)
- When given a complex task, confirm before starting: Goal + Constraints (what not to touch) + Acceptance criteria (how completion will be verified)
```

---

## 2. Hooks — Add to .claude/settings.json

```json
{
  "env": {
    "CLAUDE_CODE_AUTO_COMPACT_WINDOW": "400000"
  },
  "permissions": {
    "allow": [
      "Bash(<your-test-command>:*)",
      "Bash(<your-lint-command>:*)",
      "Edit(/docs/**)",
      "Edit(/tests/**)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [{ "type": "command", "command": "<your formatter> || true" }]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "echo $CLAUDE_TOOL_INPUT | python3 -c \"import sys,json; cmd=json.load(sys.stdin).get('command',''); bad=['rm -rf /',': > /etc','dd if=']; [exit(2) or print(f'Blocked: {b}',file=sys.stderr) for b in bad if b in cmd]\""
        }]
      }
    ],
    "SessionStart": [
      {
        "hooks": [{ "type": "command", "command": "echo \"{\\\"additionalContext\\\": \\\"Branch: $(git branch --show-current) | Last: $(git log -1 --oneline)\\\"}\"" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": "osascript -e 'display notification \"Claude finished\" with title \"Claude Code\"'" }]
      }
    ]
  }
}
```

Commit `.claude/settings.json` to git. One engineer configures it, the whole team gets it.

---

## 3. Subagents — Create in .claude/agents/

**code-simplifier.md**
```markdown
---
name: code-simplifier
description: Clean up code after changes. Remove duplication, simplify names, fix style issues. Do not change behavior.
---
Review the recent changes and simplify. Focus on: removing duplication, improving variable names, reducing nesting, fixing style. Do not change logic or behavior.
```

**verify-app.md**
```markdown
---
name: verify-app
description: End-to-end verification of the running application.
---
<Detailed instructions for starting your app, what URLs to hit, what to check, what passing looks like. Be specific to your project.>
```

**code-architect.md**
```markdown
---
name: code-architect
description: Review proposed changes for architectural soundness before implementation.
---
Review the proposed approach for: architectural fit with the existing codebase, potential edge cases, scalability concerns, simpler alternatives. Report findings before implementation begins.
```

**pr-reviewer.md**
```markdown
---
name: pr-reviewer
description: Review the current diff before a PR is opened.
---
Review the staged diff for: bugs, edge cases, missing tests, style violations, security issues. Report findings as a list. Do not approve — surface issues only.
```

---

## 4. Slash Commands — Create in .claude/commands/

**/go.md** — the most valuable single command (Boris):
```markdown
Run end-to-end verification of the current changes, then run /simplify, then open a PR with a description of what was done and why.
```

**/batch.md** — for large refactors:
```markdown
Plan the migration interactively first. Then fan out to parallel agents in isolated worktrees, one per logical chunk. Each agent tests and creates its own PR. Report when all are complete.
```

**/btw.md** — side query without interrupting:
```markdown
Answer the following question using full context, in a single turn, without using tools: $ARGUMENTS
```

---

## 5. The Karpathy 4 Rules — Paste Into Every CLAUDE.md

Mistake rate: 41% (no rules) → 11% (these 4) → 3% (extended 12 below).

```markdown
## 1. Think Before Coding
Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes
When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution
Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"
For multi-step tasks, state a brief plan with a verify step for each:
  1. [Step] → verify: [check]
  2. [Step] → verify: [check]
```

---

## 6. Extended 12 Rules (for long sessions + agent loops)

```markdown
## 5. Use code for deterministic transforms, Claude for judgment
Reserve Claude for classification, drafting, summarization. Use code for formatting, normalization, regex.

## 6. Token discipline
Enforce token budgets: 4,000 tokens per task, 30,000 per session.
If approaching the limit, stop, summarize progress, start a new thread.

## 7. Surface contradictions
When you find contradictory patterns in the codebase, surface them — don't blend silently. Ask which convention to follow.

## 8. Read before writing
Read existing code in a file before writing new code in it. Never assume what's there — check first.

## 9. Write tests that encode WHY
Tests should encode why behavior matters, not just what it does.

## 10. Checkpoint after each significant step
Complete a step → verify it → git stage → proceed. Never chain steps without verifying each one.

## 11. Match conventions, even when you disagree
Match the codebase's conventions exactly. Flag disagreement separately.

## 12. Surface uncertainty explicitly
When not sure, say so. "I'm not certain whether X or Y is correct here — which do you prefer?"
```

---

## 7. CLAUDE.md 4-Section Structure (Boris — from real business use)

```markdown
## Critical Laws
[Rules built from actual costly mistakes — non-negotiable. Each law traces to a real failure.]

## Project Invariants
[Non-negotiable constraints: never mix data, never skip migrations, all DB queries parameterized, etc.]

## Common Commands & Data Sources
[The 10 most-used commands + 5 key files. Eliminates exploratory overhead every session.]
- Run tests: <command>
- Dev server: <command>
- Lint: <command>

## Personal Preferences
[Non-mandatory style defaults.]
```

Keep total CLAUDE.md under **200 lines / ~2,500 tokens**. Longer files lose compliance as context dilutes instruction priority.

---

## 8. @-Include Fragment Pattern

Instead of adding behavioral rules inline, use `@`-includes. Root CLAUDE.md stays minimal:

```markdown
# My Project

@karpathy-rules.md
@boris-verification.md
@autonomy-spectrum.md
@context-discipline.md
```

Fragment files live in `.claude/`. Reference templates are in:
`~/PycharmProjects/IAMBoris/INSIGHTS/claudemd/`

---

## 9. Workflow Patterns

### Parallel sessions via worktrees
```bash
claude --worktree task1 --tmux
claude --worktree task2 --tmux
claude --worktree task3 --tmux
```
Each worktree is isolated — no conflicts across 3–5 simultaneous tasks.

### Autonomy spectrum (Geoffrey Litt)

| Task | Autonomy | Approach |
|------|----------|----------|
| Core design, architecture | Low | Hands-on, supervised |
| Feature implementation | Medium | Interactive with check-ins |
| Docs, TypeScript fixes, tests | High | Background agent, async |
| Exploratory spikes | High | Overnight/async, report back |

### Tutorial doc first (Geoffrey Litt)
For significant features, before implementation:
```
Write a detailed Markdown tutorial explaining how to implement [feature] in this codebase.
Include: specific file paths, exact changes needed, order of operations, edge cases.
```
Then implement from the tutorial. Retain understanding; no mystery code to debug later.

### Oracle subagent (Thorsten Ball)
Hard problems: **Opus writes the plan**, **Sonnet executes it**. Explicit split.

### Plan Mode + "Grill Me" (Boris)
1. Shift+Tab → Plan Mode
2. Describe the task
3. "Grill me on this plan — hardest questions about edge cases and failure modes"
4. Iterate until solid
5. Shift+Tab again → implement

---

## 10. Context Management

| Context % | Action |
|-----------|--------|
| 50–70% | Run `/compact` |
| 70%+ | Start a fresh session |
| 100k tokens | Always start fresh — doom loops begin |

- `/rewind` (double-tap Esc) when off-track — drops the failure entirely
- `CLAUDE_CODE_AUTO_COMPACT_WINDOW=400000` — force compaction before rot zone

### Thinking budget triggers (Simon Willison)

| Phrase | Budget | When |
|--------|--------|------|
| `think` | 4k tokens | Simple reasoning |
| `think hard` | 10k tokens | Medium complexity |
| `ultrathink` | 32k tokens | Architecture, hardest bugs |

---

## 11. Model Selection

| Model | Use For |
|-------|---------|
| Opus 4 | Architecture, complex debugging, long autonomous sessions |
| Sonnet 4 | Daily coding, refactoring, most feature work (~70% of tasks) |
| Haiku | Batch operations, CI loops, quick checks |

**Counterintuitive:** Opus costs less end-to-end for hard problems — better reasoning finishes in fewer turns.

---

## 12. Safety and Verification

### The #1 Boris rule
> "Give Claude a way to verify its work. If Claude has that feedback loop, it 2-3x the quality of the final result."

- **Backend**: Claude knows how to start the service and hit an endpoint
- **Frontend**: Playwright MCP for screenshot-based verification
- **Tests**: test command always available, always run before declaring done

### Semantic correctness check (Matt Rickard)
Before merging agent output, two separate checks:
1. **Technical**: tests pass, compiles, lints clean (agents pass automatically)
2. **Semantic**: does it solve the right problem in the right way? (only you verify this)

---

## 13. Key CLI Flags

```bash
claude --permission-mode plan        # Read-only exploration
claude --permission-mode dontAsk     # Skip all permission prompts
claude -w feature-auth               # Isolated git worktree
claude -c                            # Resume most recent session
claude --name "auth-refactor"        # Name session for easy resume
claude --effort xhigh                # Set effort level
claude --bare                        # 10x faster startup (skips auto-discovery)
claude -p "query"                    # Non-interactive SDK mode
claude --add-dir /path/to/other-repo # Access additional folder
```

---

## 14. Critical Environment Variables

```bash
CLAUDE_CODE_AUTO_COMPACT_WINDOW=400000  # Force compaction (prevent context rot)
MAX_THINKING_TOKENS=<n>                 # Override thinking token budget
CLAUDECODE=1                            # Auto-set inside Claude — use in scripts
```

Set in `~/.claude/settings.json` under `"env"` instead of shell wrappers.

---

## 15. Anti-Patterns to Stop Now

| Anti-pattern | Fix |
|---|---|
| Summarizing bugs for Claude | Paste raw CI output and stack traces verbatim |
| Bloated CLAUDE.md (>150 lines) | Delete rules you can't say what mistake they prevent |
| Correcting Claude in chat when off-track | Use `/rewind` — drops the failure entirely |
| Multiple unrelated features in one long session | One task per context; separate worktrees |
| `--dangerously-skip-permissions` on your main machine | Docker containers only |
| Imperative commands in CLAUDE.md ("You must use pytest") | Use factual statements ("Tests use pytest: `uv run pytest`") |

---

## 16. Skill Building Priority Order

1. **Product Verification skill** — drives your running app to verify changes (highest ROI)
2. **Library/API Reference skill** — internal libs, SDKs, gotchas for your stack
3. **Code Quality/Review skill** — adversarial review against your specific style rules
4. **CI/CD skill** — commit → push → deploy pipeline, safely

### Skill SKILL.md template:
```markdown
---
name: <technology>
description: "Use when doing ANY task involving <technology>. Triggers: <specific APIs, patterns, file types>"
---

# <Technology>

## Core Principles
1. Verify against docs — do not rely on training knowledge.
2. Verify your work after every change.
3. If an approach fails after 2–3 attempts, stop and try something different.

## Security / Non-Negotiable Rules
<Domain-specific rules Claude regularly gets wrong>

## Commands and CLI
<Exact commands. Never guess — always --help first.>

## Known Gotchas
<The highest-signal section — what Claude regularly gets wrong here>
```

---

## 17. Beast Mode Plugin Stack

```bash
/plugin marketplace add code-review           # 5 parallel agents, reports 80+/100 findings only
/plugin marketplace add pr-review-toolkit     # 6 specialized agents
/plugin marketplace add ralph-wiggum          # prevents premature stopping
/plugin marketplace add security-guidance     # blocks 9 dangerous patterns
/plugin marketplace add hookify               # auto-generates prevention hooks
```

**Context7 MCP — live docs for 1000+ libraries:**
```bash
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
```

---

## 18. CLAUDE.md Memory Hierarchy

```
1. Enterprise policy (immutable)
2. CLI arguments (session-level)
3. .claude/settings.local.json (personal, gitignored)
4. .claude/settings.json (project, team-shared)
5. ./src/auth/CLAUDE.md (directory-level — only loads in that directory)
6. ./CLAUDE.md (project root)
7. ~/.claude/CLAUDE.md (global personal defaults)
```

More specific overrides less specific. Directory-level CLAUDE.md only loads when working in that directory.

---

## 19. 6 Customization Layers

| Layer | Reliability | Use For |
|-------|-------------|---------|
| CLAUDE.md | ~80% | General guidance, conventions |
| Skills | ~80% | Domain-specific expertise, loaded on demand |
| Subagents | ~80% | Isolated specialists, fresh context window |
| Hooks | 100% | Things that MUST happen — never use an LLM instruction for this |
| Commands | ~80% | Reusable prompt templates for repeated workflows |
| Plugins | ~80% | Bundled packages for distribution |

---

## 20. The 5-Step Meta-Pattern

```
1. RESEARCH   — Read relevant codebase sections before writing a line
2. PLAN       — Plan Mode + "Grill Me". Iterate until solid.
3. EXECUTE    — Fresh agents, atomic tasks, one thing at a time
4. VERIFY     — Run tests, lint, read the diff, take screenshots
5. SHIP       — Clean commit explaining WHY, open PR with /go
```

Never let Claude skip from step 1 to step 3.

---

## 21. May 2026 Verified Additions (Boris)

- **Self-verification = 2-3x quality multiplier** — *"probably the most important thing"*
- **Loop patterns**: `/loop 5m /babysit` (auto-address code review), `/loop 30m /slack-feedback`
- **Scale proof**: Boris shipped 49 PRs in 2 days, 5 terminal instances, 100% written by Claude
- **Agentic search > RAG**: glob/grep outperforms vector DBs for codebase context — don't add vector DBs
- **"Coding is solved"**: Boris frames intent→code translation as a solved problem (Sequoia AI Ascent 2026)

### Karpathy — program.md Pattern
For overnight/background tasks, create `loop-program.md` with:
```
NEVER STOP: Once the experiment loop has begun, do NOT pause to ask the human if you
should continue. The human might be asleep and expects you to continue working indefinitely
until manually stopped.
```

### Simon Willison — Three Subagent Roles
1. **Code reviewer** — bugs and design weaknesses
2. **Test runner** — hides verbose output, surfaces only failures
3. **Debugger** — isolates reproduction steps, determines root cause

**Curl verification rule**: After tests pass, start the dev server and curl the API before declaring done.

---

*Full source: `~/PycharmProjects/IAMBoris/MASTER_APPLY.md` — 37 sections of adversarially verified research.*
