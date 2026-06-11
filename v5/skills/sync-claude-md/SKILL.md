---
name: sync-claude-md
description: Use when initializing or updating a project's CLAUDE.md — produces a native-format file with structure diagram, setup, architecture, and file-layout sections, or fills missing sections in an existing one.
author: Donal Moloney
track: memory
type: support
chains-to: ~
---

## Not this skill if
- `CLAUDE.md` is already accurate and up to date
- You are making a code change, not updating project documentation

# sync-claude-md — keep CLAUDE.md in sync with the repo

CLAUDE.md is the agent's loaded context for the project. Stale, missing, or marketing-style CLAUDE.md silently corrupts every later turn. Treat it as code.

## When to Use

- A repo has no `CLAUDE.md` and you are about to do non-trivial work in it.
- `CLAUDE.md` exists but the structure diagram, setup steps, or architecture section is missing or out of date with what's actually on disk.
- A milestone just landed: feature merged, dependencies bumped, top-level layout changed.
- The user asks to "init", "audit", "refresh", or "enhance" CLAUDE.md.

## The four required sections

A native-format `CLAUDE.md` carries these, in this order:

1. **Project structure** — fenced tree of top-level directories with one-line purposes.
2. **Setup** — exact commands to install deps and run the project locally. Must run as written.
3. **Architecture** — the system's shape in 3–8 bullets: entry points, layers, where state lives.
4. **File layout / conventions** — naming rules, where new code goes, what each top-level folder owns.

Any section missing or wrong is a defect.

## Rules

1. **Discover before writing.** Read `package.json` / `pyproject.toml` / `go.mod` / the actual top-level tree. Never infer from filenames alone.
2. **Confirm before creating.** On a fresh init, surface the detected stack and structure to the user and wait for confirmation before writing the file.
3. **Diff before enhancing.** For an existing CLAUDE.md, list which of the four required sections are missing or stale, then patch only those — do not rewrite sections that are already correct.
4. **No marketing.** No "intelligent", "comprehensive", "100% compliant", no emoji bullets. State what is true.
5. **Commands must run.** Every shell command in the Setup section must be executable as written from the repo root in a clean checkout. If unsure, run it.
6. **Modular layout only when justified.** Sub-directory `CLAUDE.md` files (e.g. `backend/CLAUDE.md`) are warranted only when a layer has rules that don't apply elsewhere. Default: one root file.

## Discovery checklist

Before writing or patching, capture:

- Language(s) and primary framework (from manifests, not extensions).
- Package manager and lockfile presence.
- Test runner and how to invoke it.
- Entry point(s) — `main`, `index`, `app`, declared `scripts.start`, etc.
- Top-level directories and their purpose (read at least one file per dir if the name is ambiguous).
- Git state — is this a fresh repo, a fork, or active?

## Pairs with

- [`outline-plan`](../outline-plan/SKILL.md) — when CLAUDE.md changes are themselves a multi-step task.
- [`verify-before-done`](../verify-before-done/SKILL.md) — run every Setup command before claiming the file is correct.
- [`proof-gate`](../proof-gate/SKILL.md) — completion of a CLAUDE.md update carries `PROVEN BY:` for the run of each Setup command.
