---
name: headless-claude-pipelines
description: Use when a task is non-interactive and repeats over many items or runs unattended in CI — invoke Claude in headless mode (`claude -p "..."`) as a programmable subroutine in a shell pipeline, instead of opening an interactive session
tier: v4
inspiration: "Cherny — headless mode (`claude -p`) for programmatic / non-interactive use: fan out over a list of items, run as a CI quality gate, build automation pipelines (Claude Code: Best practices for agentic coding, Anthropic engineering blog, April 2025)"
---

# Headless Claude Pipelines

**Not this skill if:**

- You are choosing WHICH tool (CLI vs. composition vs. MCP) for a capability → that is v4 `bash-first-tooling` (C2); this skill assumes the tool is *Claude itself, called as a subroutine*, and only governs when and how to invoke it headless. Reference it, don't restate it.
- The work needs back-and-forth — clarifying questions, judgment calls, exploring an unfamiliar codebase, or anything where you'd want to read Claude's reasoning and steer → keep the interactive session. Headless is for jobs whose success is checkable without a human in the loop.

`claude -p "<prompt>"` runs one non-interactive turn and exits — text on stdin, result on stdout, exit code for the shell. That makes Claude a composable Unix subroutine you can pipe, loop, and gate on. Reach for it only when the job is repetitive or unattended; otherwise an interactive session is the better tool.

## The decision ladder

Walk top to bottom. The first row that matches is your answer — and most rows say *don't* go headless.

| If the job is... | Then... |
|---|---|
| Open-ended, exploratory, or needs your judgment mid-flight | **Interactive session.** Not a headless job. Stop here. |
| One-off and you'd read the output anyway | **Interactive session.** The pipeline setup costs more than it saves. |
| The same prompt applied across many files/items, each independently checkable | **Headless, fan-out:** loop or `xargs` over the list, one `claude -p` per item. |
| A pass/fail check that must run unattended (pre-commit, CI, cron) | **Headless, gate:** `claude -p` emitting a verdict; the shell branches on it. |
| A deterministic transform (lint-fix, codemod, format) Claude can do but no formatter does | **Headless, transform:** stdin → `claude -p` → stdout, then verify with a real tool. |

## The three patterns

**1. Fan-out over items** — same prompt, many independent targets:

```bash
# Classify/label each file; one isolated turn per item
for f in docs/*.md; do
  label=$(claude -p "Reply with ONE word — the primary topic of this file:" < "$f")
  printf '%s\t%s\n' "$f" "$label"
done
```

Each item gets a fresh context (no cross-contamination, no context bloat). Prefer `--output-format json` when a downstream step parses the result, so you read a structured field instead of scraping prose.

**2. CI / pre-commit quality gate** — Claude returns a verdict, the shell decides:

```bash
verdict=$(git diff --cached | claude -p \
  'Review this staged diff. Reply EXACTLY "PASS" or "FAIL: <one-line reason>". No other text.')
case "$verdict" in
  PASS) exit 0 ;;
  *)    echo "$verdict" >&2; exit 1 ;;   # block the commit / fail the build
esac
```

The gate's authority lives in the exit code the shell checks — this is the headless complement to v1 `verification-before-completion` (the leash is now machine-enforced, not prose).

**3. Transform in a pipe** — stdin → Claude → stdout, then verify with a real tool:

```bash
claude -p 'Add type hints to this Python file. Output ONLY the file content.' \
  < module.py > module.py.new \
  && python -m mypy module.py.new \      # a deterministic tool confirms the output
  && mv module.py.new module.py
```

Never trust the transform on Claude's say-so; a linter/compiler/test is the verifier.

## Guardrails

- **Idempotence.** A pipeline may rerun (CI retry, partial failure). Write so a second run is a no-op: emit to a `.new` file and swap only on success; make fan-out skip already-labeled items. Never let `claude -p` edit a file in place inside a loop that might re-run.
- **Constrain the output, then parse it.** Headless output is consumed by a script, not read by a human — pin the format in the prompt (`Reply EXACTLY "PASS" or "FAIL: ..."`, `Output ONLY the file content`) and prefer `--output-format json` for structured fields. Unconstrained prose breaks the pipe.
- **Non-interactive failure handling.** No human will notice a silent wrong answer. Check the exit code, set a per-item timeout, cap retries, and on a malformed/empty result **fail loud** (`exit 1`, log to stderr) — never let the loop swallow it and march on.
- **Cost and blast radius scale with the loop.** N items = N model calls = N× tokens and latency. Test the prompt on one item interactively first; bound the fan-out (a `head -n` cap or a dry-run that just prints what it *would* run) before unleashing it on thousands of files.
- **Don't reach for headless where interactive wins.** If you'd want to see the reasoning, ask a follow-up, or course-correct — that's a session, not a pipeline. Headless trades steerability for automation; only pay that when the job is genuinely unattended and checkable.

## Provenance

- **Idea (Cherny):** Beyond the interactive REPL, Claude Code ships a headless mode — `claude -p "<prompt>"` — for programmatic and non-interactive use. The post highlights it for fanning a prompt out over a list of items (e.g. classifying/labeling many inputs, one isolated call each), wiring Claude into CI and pre-commit as an automated check, and building larger automation pipelines, with `--output-format stream-json` for machine-readable output.
- **Where stated:** "Claude Code: Best practices for agentic coding", Anthropic engineering blog, April 2025, section "Use headless mode to automate your infra" (and its fan-out / pipeline examples); authored by Boris Cherny, Claude Code's creator. Citation confirmed via web search, June 2026 (the live URL now redirects into the Claude Code docs, whose "headless mode" guidance keeps the same advice: use `-p` for CI, pre-commit hooks, and build/automation scripts).
- **How this tool operationalizes it:** It turns "there's a `-p` flag" into a working decision discipline — a top-to-bottom ladder whose default answer is *stay interactive*, three concrete pipeline patterns (fan-out, CI gate, transform-in-a-pipe) wired to exit codes and `--output-format json`, and five guardrails (idempotence, constrained-then-parsed output, loud non-interactive failure, bounded cost/blast-radius, and a hard boundary back to interactive sessions) so Claude-as-a-subroutine fails safe instead of silently.
