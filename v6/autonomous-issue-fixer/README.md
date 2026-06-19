# Autonomous Issue Fixer

Label an issue `claude-fix` (or mention `@claude` in an issue comment) and Claude Code
posts a plan, implements the fix on an isolated branch, and opens a **draft** PR linked
to the issue. Built on the official [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action).

## Install

| From (this folder) | To (consuming repo) |
|--------------------|---------------------|
| `workflow.yml` | `.github/workflows/issue-fixer.yml` |

No helper scripts and **no cost-guardrail** — `claude-code-action` runs its own agent
loop and billing. Add the `ANTHROPIC_API_KEY` secret, and create a `claude-fix` label.
Optional variable: `CLAUDE_FIXER_MODEL` (default `claude-opus-4-8`, passed as the
Claude Code `--model` flag).

## Permissions

```yaml
permissions:
  contents: write
  pull-requests: write
  issues: write
```

## Security model — read before enabling

This workflow has **write access** and is triggered by issue activity, so the trigger
gate *is* the security boundary:

- **`claude-fix` label** — applying a label requires write/triage access, so only
  trusted users can trigger the label path. This is the recommended entry point.
- **`@claude` in a comment** — restricted to issues (not PRs) **and** to commenters
  whose `author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR`. This guard is
  enforced in the job `if:` by default — without it, any GitHub user could trigger an
  autonomous agent holding `contents`/`pull-requests`/`issues` write and the
  `ANTHROPIC_API_KEY` just by commenting `@claude`. Loosen it only if you fully trust
  everyone who can comment.
- The PR is opened as a **draft** — a human reviews and marks it ready; nothing merges
  automatically.

## Notes

- `claude_args` are Claude Code CLI flags; PR creation is driven by the `prompt`, which
  the action carries out using its built-in git/GitHub tools. See the action's docs for
  advanced configuration (allowed tools, base branch, cloud providers).
- Concurrency is **serialized** per issue (`cancel-in-progress: false`) so a second
  trigger doesn't abort an in-flight fix mid-commit.
- This is the only v6 template that writes to `contents` — keep its trigger gate strict.
