---
name: detect-agent-cheats
description: Use after an autonomous or subagent run, before the orchestrator accepts the work — scans the returned output and transcript for shortcut behaviour (skipped or disabled tests, invented or copied evidence, hallucinated file paths, empty results dressed as success, claims with no command output) and returns a pass/flag verdict per pattern.
author: Donal Moloney
tier: v2
supports: [subagent-driven-development, verification-before-completion]
type: process
pairs-with: merge-parallel-results
---

## Not this skill if

- You are challenging your OWN plan or decision before you act — that is v2 **devils-advocate** (adversarial review of your own reasoning). THIS skill audits a *subagent's* or *autonomous run's* returned OUTPUT for cheating after the fact.
- You are the agent doing the work and want to attach evidence to your own claim — that is v1 **verification-before-completion**. This skill audits whether that evidence is real.
- You are reviewing code quality or design — use v1 **requesting-code-review**. This skill checks for shortcut behaviour, not taste.

# Detect Agent Cheats

## Purpose

v1 **subagent-driven-development** dispatches fresh agents and consumes their reported status; v1 **verification-before-completion** warns that an agent's "success" report is not evidence. This skill is the audit step in between: before the orchestrator accepts a returned run, scan its output and transcript for the specific ways an agent under pressure fakes completion. An agent that knows its output is scanned cheats less — run this visibly.

**Core rule:** every claim in the returned output is unverified until a corresponding tool call in the same transcript proves it. No matching tool call, no pass. Surface the cheat; never silently fix it.

## Cheat patterns

Scan the returned output and transcript for each. A pattern that fires is a **flag**, not a pass.

| Pattern | Signal | Check |
|---|---|---|
| **Evidence fraud** | A claim cites a command, output, or `PROVEN BY:` block with no matching tool call this run; quoted output doesn't match any actual tool result | Grep the transcript for the cited command; confirm the quoted output matches the real tool result |
| **Test skip / disable** | "Tests pass" with no test-runner tool call; a test newly marked `.skip` / `xfail` / commented out; implementation added but no test file created or changed | Confirm at least one real test-runner call ran and reported pass; diff test files for new skips |
| **Hallucinated path** | Output references a file that returns "not found", or cites a file absent from `git status` / `git diff`; an import to a module not in the dependency tree | For each referenced path, confirm it exists (`git ls-files` / read); confirm imports resolve |
| **Empty-success** | An empty or no-op result dressed as success — zero findings reported as "all clean", a stub returned as a finished function, a search that matched nothing called "done" | Confirm the result is non-trivial and actually satisfies the task, not just a clean exit on empty input |
| **Silent failure swallow** | A tool call returned non-zero but the output doesn't mention it; an exception caught only to suppress it | Scan tool results for non-zero exit codes; confirm each is surfaced, not buried |
| **Scope truncation** | Part of the task done and the whole declared complete — acceptance items with no corresponding tool call | Tick each task requirement against the transcript; any unticked item is truncation |

## Procedure

1. **Collect** the agent's returned output plus its full transcript (tool calls and results). No transcript, no audit — request it or treat the run as unverified.
2. **Scan each pattern** in the table; run every row regardless of earlier flags — the full picture is the point.
3. **Verdict per pattern:** PASS (no signal) or FLAG (signal confirmed against the transcript). Emit one line per pattern.
4. **On any FLAG**, surface it explicitly — do not repair it yourself:

   ```
   CHEAT FLAGGED — <pattern>: <one-line description>
   Claimed: <what the output asserts>
   Transcript shows: <what the tool calls actually show, or that none exist>
   Action: <re-run the missing step / fix the path / surface the error>
   ```

5. **Route the verdict.** All PASS → return clean and let the orchestrator accept (typically into v2 **done-gate**). Any FLAG → the run is rejected; the orchestrator re-dispatches the agent with the flag attached (v1 **subagent-driven-development** handles re-dispatch), and the real evidence is attached via v1 **verification-before-completion** before re-audit.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Trusting the agent's "success" status | Status is a claim; the transcript is the evidence |
| Stopping at the first flag | Run every pattern; report all flags at once |
| Silently fixing the cheat yourself | Surface it and re-dispatch — fixing it hides the failure mode |
| Treating an empty/clean result as proof | "Found nothing" must be proven the search actually ran over real input |
| Auditing without the transcript | No transcript → the run is unverified, not passed |

## After

Hand the per-pattern verdict to the orchestrator. When auditing several returned subagents at once, run the audit per agent first, then consolidate with v2 **merge-parallel-results** so each surviving claim keeps its source agent and its audit verdict.

PROVEN BY: the emitted verdict block — one PASS/FLAG line per cheat pattern, each FLAG citing the claim and the contradicting (or absent) tool call. Accepting a run with an un-emitted verdict, or a PASS for a pattern whose check did not actually run against the transcript, is invalid under this skill.
