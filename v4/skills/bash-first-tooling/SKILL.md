---
name: bash-first-tooling
description: Use when tempted to add an MCP server, dependency, or custom integration for a capability — walks the cheapest-tool-that-works ladder (existing CLI → bash one-liner → repo script → only then MCP/dependency) before anything new gets installed
tier: v4
inspiration: "Cherny — bash as the universal tool: Claude Code inherits your bash environment, so prefer existing CLI tools, taught via --help and CLAUDE.md, over new integrations (Claude Code: Best practices for agentic coding, Anthropic engineering blog, April 2025)"
---

# Bash-First Tooling

**Not this skill if:**

- You already chose the tool and need the simplest IMPLEMENTATION with it → that is general YAGNI discipline (`v1/brainstorming`'s simplicity principle), not a tool-acquisition question.
- You need to know THIS project's canonical verify commands (test/lint/build) → `v2/verify-command-suggester` (v2).

## The ladder

You need a capability (talk to GitHub, query a database, convert a file, hit an
API). Walk the rungs in order. Each rung has a stop-rule: if it fires, **stop —
you have your tool**. You may only descend to the next rung after showing, in
the conversation, why the current rung failed.

| Rung | Tool | Probe before deciding | Stop-rule (stop here if...) |
|---|---|---|---|
| 1 | An existing CLI already on the machine | `which <tool>`; `<tool> --help` to learn flags you don't know | The CLI exists and `--help` shows it covers the operation (e.g. `gh` for GitHub, `psql` for Postgres, `jq` for JSON, `curl` for HTTP) |
| 2 | A bash one-liner composing existing CLIs | Run the pipeline once on real input and read the output | The pipeline produces correct output (e.g. `gh pr list --json title \| jq ...`) — pipes, `xargs`, and `grep` are composition, not a new tool |
| 3 | A small script committed to the repo | Write it, run it on real input, show the output | The capability needs >1 line, loops, or reuse across sessions — a `scripts/*.sh` (or `.py`) file under version control covers it |
| 4 | An MCP server or new dependency | None — this rung requires justification, not a probe | Last resort. Only with a stated reason in the conversation: `RUNGS 1–3 FAILED: <which CLI is missing / why composition can't do it / why a script can't (auth handshake, persistent connection, binary protocol)>` |

Rules that keep the ladder honest:

- **Probe, don't assume.** "There's probably no CLI for this" is not a rung-1
  result; `which`/`--help` output in the conversation is. Claude is effective at
  learning unfamiliar CLIs from `--help` — run it before declaring the tool unknown.
- **One rung at a time.** Reaching for an MCP server before showing rung 1–3
  output is skipping the ladder.
- **The justification is mandatory at rung 4.** No `RUNGS 1–3 FAILED:` line in
  the conversation, no new dependency. A vague "it'll be cleaner" does not count;
  name the specific failure.
- **Cost asymmetry is the point.** Rungs 1–2 cost nothing and add zero context
  overhead or install surface. Rung 4 costs setup, permissions, tool-definition
  tokens in every future session, and a maintenance obligation. Pay it only when
  the cheaper rungs demonstrably cannot.

## Teach the tool

Closing step — when a CLI you learned at rung 1–3 earns regular use (second or
third time this project needed it):

1. Add its invocation to the project's CLAUDE.md so it persists across sessions:

   ```markdown
   # Tools
   - `sentry-cli issues list --status unresolved` — check production errors
   - `scripts/reset-fixtures.sh` — rebuild test fixtures after schema changes
   ```

2. One line per tool: the exact command plus when to use it. Claude can't guess
   custom tools' existence; a documented invocation is the difference between
   re-deriving it every session and having it on rung 1 next time.

## Provenance

- **Idea (Cherny):** Claude Code's working substrate is your existing shell — "Claude Code inherits your bash environment, giving it access to all your tools." For unfamiliar or custom tools, the post recommends telling Claude the tool name with usage examples, telling it to run `--help` to read the tool's own documentation, and documenting frequently used tools in CLAUDE.md — i.e., teach existing CLIs rather than build new integrations.
- **Where stated:** "Claude Code: Best practices for agentic coding", Anthropic engineering blog, April 2025, section "Give Claude more tools" → "a. Use Claude with bash tools"; authored by Boris Cherny, Claude Code's creator. Verified against an archived copy of the original post (the live URL now redirects into the Claude Code docs, whose "Use CLI tools" section keeps the advice: prefer `gh`/`aws`/`gcloud`-style CLIs as "the most context-efficient way to interact with external services", and learn unknown CLIs via `--help`). Secondary source, verified: Cherny on the Latent Space podcast, "Claude Code: Anthropic's Agent in Your Terminal", May 2025 — Claude Code framed as a Unix utility built on "do the simple thing first."
- **How this tool operationalizes it:** It turns "bash is already the universal tool" into a four-rung acquisition gate — existing CLI, then composition, then a committed script, then (only with a written `RUNGS 1–3 FAILED` justification) an MCP server or dependency — and closes Cherny's loop by writing regularly-used invocations into CLAUDE.md so the taught tool persists across sessions.
