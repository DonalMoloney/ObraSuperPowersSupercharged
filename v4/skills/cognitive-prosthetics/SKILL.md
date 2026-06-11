---
name: cognitive-prosthetics
description: Use when entering unfamiliar territory (a new domain, a new codebase area, or any factual claim) — match the situation to a known LLM cognitive deficit and apply the corresponding compensation before proceeding
tier: v4
inspiration: "Karpathy — LLM cognitive deficits (Dwarkesh Patel podcast, October 2025)"
pairs-with: [decision-ledger]
---

# Cognitive Prosthetics

**Not this skill if:**
- You need the decision-memory prosthetic specifically → **v2 decision-ledger**. This skill is the map; the ledger is one territory on it. Apply the ledger directly when the only deficit in play is decisions evaporating between sessions.
- You are debugging a concrete failure that already happened → **v1 systematic-debugging**. Prosthetics prevent deficit-driven errors; they do not diagnose existing ones.

## Core procedure

LLMs have known, recurring cognitive deficits. Do not work around them ad hoc — recognize the trigger, name the deficit, apply the standard prosthetic. One row fires per trigger; multiple rows can be active at once.

| Deficit | Prosthetic | Trigger condition |
|---------|-----------|-------------------|
| **Anterograde amnesia** — no continual learning; nothing consolidates after training, only the context window persists, and it resets | Write durable notes/ledgers to files the moment the knowledge exists. Decisions, constraints, and discovered gotchas go in a ledger or project notes file (see v2 decision-ledger), never only in conversation. | Any decision or discovery that must survive the current session. |
| **Jagged intelligence** — expert-level on some tasks, inexplicably wrong on adjacent simple ones; competence does not transfer smoothly | Never extrapolate competence across domains. When the domain changes, drop assumed skill back to zero: re-verify basics (run `--help`, read the actual file, check the actual schema) before acting on "obvious" knowledge. | First action in an unfamiliar domain, language, framework, or codebase area. |
| **Confident hallucination** — fluent, plausible, wrong; confidence carries no signal | Cite-or-check rule: every factual claim gets either a source (file path, doc URL, command output already in context) or a verification command run before the claim is stated. No third option. | Stating any fact not directly visible in the current context. |
| **Context-window limits** — working memory is finite RAM; long tasks silently evict early state | Externalize working state to files: a checklist, a scratch plan, or a status file updated as you go. The file is the working memory; the context window is just the cache. | Task state exceeds what one screen can show (more than ~5 live items, files, or pending steps). |

### Applying a row

1. Notice the trigger (the right column is the watchlist — scan it at task start and at every domain/area switch).
2. Say which deficit is in play, in one line.
3. Apply the prosthetic **before** the at-risk action, not after the mistake.

## Provenance

- **Idea:** Karpathy describes today's LLMs as having concrete cognitive deficits: they are like a coworker with anterograde amnesia — no continual learning, no consolidation of knowledge after training, only a short-term-memory context window — alongside hallucination and jagged, unevenly distributed capability.
- **Where stated:** Andrej Karpathy interviewed on the Dwarkesh Patel podcast, released October 17, 2025 (the episode's "LLM cognitive deficits" chapter, ~0:30); verified via web search. "Jagged intelligence" is Karpathy's own earlier coinage, from his X post of July 25, 2024 (x.com/karpathy/status/1816531576228053133), naming the fact that state-of-the-art LLMs solve hard problems while failing simple adjacent ones.
- **How this tool operationalizes it:** It turns each named deficit into a standing compensation with an explicit trigger condition, so the agent applies the matching prosthetic (durable notes, basics re-verification, cite-or-check, externalized state) the moment a deficit-prone situation arises, rather than discovering the deficit through a failure.
