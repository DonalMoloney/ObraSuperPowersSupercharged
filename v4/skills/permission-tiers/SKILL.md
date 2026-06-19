---
name: permission-tiers
description: Use when you need to ENFORCE an autonomy level — write the .claude/settings.json allow/ask/deny lists and permission mode that make L0–L3 deterministic instead of advisory
tier: v4
inspiration: "Cherny — .claude/settings.json allowlists, permission modes, and deliberate --dangerously-skip-permissions (Claude Code: Best practices for agentic coding, Anthropic engineering blog, April 2025)"
---

# Permission Tiers

**Not this skill if:** you are deciding *which* level to grant or when to downgrade → v4 `autonomy-slider` owns that policy; you need a must-happen runtime rule that no settings file can express (e.g. "block any edit touching `migrations/`") → that is a PreToolUse hook, bundled by the `autonomy-control` plugin, not a settings allowlist.

`autonomy-slider` decides the level. This skill makes the level *real*. A declared "L1" means nothing if the agent can still run `rm -rf` unprompted; the enforcement lives in `.claude/settings.json`, where prose is advisory but the permission engine is deterministic. Pick the template that matches the declared level, write it, and the level becomes a boundary the agent cannot cross by accident.

## The pattern

Each `autonomy-slider` level maps to one settings template: a `permissions` block (`allow` / `ask` / `deny` lists) plus a `defaultMode`. `deny` wins over `allow`; anything matched by neither falls to `ask`. Tighter levels deny more and ask more.

### Level → settings template

| Level | `defaultMode` | `allow` (auto, no prompt) | `ask` (prompt every time) | `deny` (always blocked) |
|-------|---------------|---------------------------|---------------------------|-------------------------|
| **L0** suggest-only | `plan` | (none — read-only) | — | `Edit`, `Write`, `MultiEdit`, `Bash`, `NotebookEdit` |
| **L1** single-file | `default` | `Read`, `Grep`, `Glob`, `Bash(git status:*)`, `Bash(git diff:*)` | `Edit`, `Write`, `Bash` | `Bash(rm:*)`, `Bash(git push:*)`, `Bash(git reset:*)`, `Write(*/migrations/**)` |
| **L2** checkpointed | `acceptEdits` | `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Bash(npm test:*)`, `Bash(pytest:*)`, `Bash(git diff:*)`, `Bash(git status:*)` | `Bash`, `Bash(git commit:*)` | `Bash(rm -rf:*)`, `Bash(git push:*)`, `Bash(*--force*)`, `Write(*/migrations/**)`, `Bash(*:prod*)` |
| **L3** full task | `acceptEdits` | `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Bash(npm *:*)`, `Bash(pytest:*)`, `Bash(git add:*)`, `Bash(git commit:*)`, `Bash(git diff:*)` | `Bash(git push:*)` | `Bash(rm -rf /:*)`, `Bash(*--force-with-lease*)`, `Bash(*:prod*)`, `Bash(curl * \| sh:*)` |

L3 is *not* `--dangerously-skip-permissions`. That flag bypasses the engine entirely — reserve it for a sandboxed, network-isolated container with a git-clean tree, and even then keep the `deny` list above by running it with these settings present. A declared L3 in a normal worktree still asks before `git push` and still denies the irreversible commands.

### Example: write the L2 template

`.claude/settings.json`:

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Read", "Grep", "Glob", "Edit", "Write",
      "Bash(npm test:*)", "Bash(pytest:*)",
      "Bash(git diff:*)", "Bash(git status:*)"
    ],
    "ask": [
      "Bash", "Bash(git commit:*)"
    ],
    "deny": [
      "Bash(rm -rf:*)", "Bash(git push:*)", "Bash(*--force*)",
      "Write(*/migrations/**)", "Bash(*:prod*)"
    ]
  }
}
```

### How to apply a template

1. **Confirm the level first.** Read the one-line `autonomy-slider` declaration for this task (e.g. `Autonomy: L2`). Never pick a template independently of that policy.
2. **Pick the scope.** Project-wide enforcement → `.claude/settings.json` (checked in). Personal, uncommitted override → `.claude/settings.local.json`. The local file overrides the project file.
3. **Write the matching template** from the table above; trim `allow` entries the task does not need and add project-specific `deny` rules (data-destructive scripts, deploy commands).
4. **Verify it loaded, do not assume.** Run `/permissions` in the session (or `claude` shows it on start). If a tool you expect to be denied is not, the file did not parse — fix it before the first edit.
5. **On downgrade** (when `autonomy-slider` drops a level mid-task), rewrite the file to the lower-level template; the new `deny`/`ask` entries take effect on the next tool call.

### Settings precedence (tightest wins)

Enterprise managed policy → CLI flags → `.claude/settings.local.json` → `.claude/settings.json` → user `~/.claude/settings.json`. Within a resolved `permissions` block, `deny` beats `ask` beats `allow`. A `deny` you cannot override from a lower-precedence file is the deterministic floor — that is the point.

## Provenance

- **Idea:** Cherny's guidance is that agentic productivity comes from explicitly defining safety boundaries rather than leaving them implicit — curate the tool allowlist (via the permissions prompt, `/allowed-tools`, or `settings.json`), and treat `--dangerously-skip-permissions` as a deliberate, sandboxed exception rather than a default. The permission engine is deterministic where prose guidance is not.
- **Where stated:** "Claude Code: Best practices for agentic coding", Boris Cherny, Anthropic engineering blog, April 2025 — the "a. Tune your tool allowlist" / managing permissions section (verified via web search, June 2026).
- **How this tool operationalizes it:** It turns the allowlist advice into four ready-to-write `.claude/settings.json` templates — one per `autonomy-slider` level — with explicit `allow`/`ask`/`deny` lists and `defaultMode`, an apply-and-verify procedure, and an explicit rule that L3 is settings-enforced rather than `--dangerously-skip-permissions`. It is the deterministic mechanism (settings) under the policy (which level); it pairs with `autonomy-slider` and does not restate level-selection logic. For must-happen rules a settings file cannot express, the `autonomy-control` plugin adds PreToolUse hook enforcement on top of these templates.
