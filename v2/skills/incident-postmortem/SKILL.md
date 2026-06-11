---
name: incident-postmortem
description: "Use when an incident, outage, or significant failure has occurred and you need to produce a structured blameless postmortem: timeline, root cause, contributing factors, and prevention actions."
author: Donal Moloney
tier: v2
supports: [systematic-debugging]
type: analysis
chains-to: verification-before-completion
---

## Not this skill if
- The incident is still ongoing — stabilise and mitigate first; do not write the postmortem mid-fire.
- You only need to identify the root cause without a full report — use v1 **systematic-debugging** instead.
- The failure was a known flaky test or non-production noise with no user impact — skip the postmortem; file a ticket.
- You are reviewing speculative future risk rather than a real event — use v2 **blast-radius** instead.

# Incident Postmortem

## Purpose

Produce a complete blameless postmortem document for a real incident: reconstruct the timeline, identify the root cause and contributing factors, and define concrete prevention actions with owners and due dates. The output is a durable written record that can be shared, reviewed, and acted on.

## Triggers

**Use when:**
- A production outage, data loss event, security breach, or significant degradation has occurred.
- A near-miss was caught before user impact but exposed a systemic gap that needs documenting.
- A team retrospective or review meeting requires a structured written input.
- A prior postmortem action item needs a follow-up audit — re-run this skill scoped to that item.
- Stakeholders or on-call teams request a written explanation of what happened and what changes.

**Don't use when:**
- The incident has not been resolved and recovery is still in progress.
- The scope is a single code bug with no timeline complexity — use v1 **systematic-debugging** for that.
- The purpose is speculative pre-incident risk mapping — use v2 **blast-radius** instead.
- You have fewer than two confirmed facts about the incident; gather evidence first.

## The pattern

A postmortem has five distinct stages: assemble evidence, build the timeline, derive root cause and contributing factors, define actions, and write the document. Never collapse stages — each gate feeds the next.

### Stage 1 — Assemble evidence

Collect all available raw signal before drawing any conclusions:
- Gather monitoring alerts, on-call pages, and the exact timestamps they fired.
- Pull relevant log excerpts: error rates, exception traces, deployment events, config changes.
- Collect chat/incident-channel threads in chronological order.
- Note who was on-call and when they engaged.
- Record the customer-impact window: when did degradation begin, peak, and resolve?

Do not interpret yet. Only gather and timestamp. Flag any evidence gaps (missing logs, coverage holes) explicitly — do not paper over them.

### Stage 2 — Build the timeline

Construct a single linear timeline in UTC from the earliest evidence to the final all-clear:

- One line per event: `HH:MM UTC — <what happened>`.
- Include automated events (alert fired, auto-scale triggered, deploy rolled back) alongside human actions.
- Mark the **detection point** (when someone first knew), the **impact start** (when users were affected), and the **mitigation point** (when impact stopped, even if root cause was not yet known).
- If two events happened simultaneously, list both with the same timestamp.
- Keep timeline entries factual — no blame language, no "should have".

### Stage 3 — Identify root cause and contributing factors

Apply the Five Whys from the first symptom visible in the timeline. Stop when you reach a system-level or process-level cause that, if fixed, would prevent recurrence. Record each Why step explicitly.

Distinguish:
- **Root cause** — the single most proximate systemic cause.
- **Contributing factors** — conditions that made the root cause possible or made detection slower. List each as a separate bullet with a brief explanation.
- **Non-causes** — things that looked suspicious but were ruled out. Document these to save future investigators time.

Avoid stopping at "human error" — if a human made a mistake, ask why the system allowed that mistake to have impact.

### Stage 4 — Define prevention actions

Each action must be:
- Specific — name the system, file, or process being changed.
- Owned — assign a name or role, not a team.
- Time-bound — set a target date.
- Categorised as one of: `Prevent` (stops recurrence), `Detect` (catches it faster), `Mitigate` (reduces blast radius), or `Process` (improves response).

Write each action as a single row in a table:

| Action | Category | Owner | Due |
|---|---|---|---|
| Add alert for X dropping below Y threshold | Detect | @oncall-eng | YYYY-MM-DD |

Aim for 3–8 actions. Fewer than 3 suggests the analysis was not deep enough. More than 8 usually means the scope has drifted — split into a follow-up ticket rather than bloating the postmortem.

### Stage 5 — Write the document

Assemble the postmortem document in this order:

1. **Summary** — two to four sentences: what broke, how long, how many users affected, and one-line root cause.
2. **Impact** — quantify: duration, user count or percentage, error rate peak, revenue or SLA impact if known.
3. **Timeline** — the full UTC timeline from Stage 2.
4. **Root Cause** — the Five Whys chain ending at the root cause statement.
5. **Contributing Factors** — bulleted list from Stage 3.
6. **What Went Well** — at least two items. Blameless postmortems recognise responders who acted correctly under pressure.
7. **What Could Be Improved** — at least two items distinct from the action items.
8. **Action Items** — the table from Stage 4.
9. **Appendix** — raw log excerpts, alert screenshots, or links to monitoring dashboards.

Use plain prose for sections 1–2 and 6–7. Use tables and lists for sections 3, 5, and 8. Do not editorialize or assign blame in any section.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Stopping the Five Whys at "human error" | Ask why the system made the human error consequential; reach a structural cause |
| Writing the postmortem during the incident | Wait until mitigation is confirmed; premature analysis locks in wrong root causes |
| Vague action items with no owner or date | Every row in the actions table must have a specific owner name and due date |
| Omitting "What Went Well" to save time | Include it; it reinforces correct behaviours and keeps the document blameless |
| Conflating root cause with contributing factors | Root cause is singular and proximate; contributing factors are plural and contextual — list them separately |
| Timeline gaps left unexplained | Note missing evidence explicitly ("No logs available for 14:05–14:12 UTC; reason unknown") |
| Action items that duplicate existing tickets without linking them | Either link the existing ticket or close the duplicate; orphan actions never get done |

## Evidence

Hand off to v1 **verification-before-completion** once the postmortem document is written.

The output must contain:
- Summary section with quantified impact (duration + affected scope).
- Full UTC timeline with detection point, impact start, and mitigation point labelled.
- Five Whys chain ending at a structural root cause (not "human error").
- Contributing factors list with at least one entry.
- Action items table with owner and due date for every row.
- "What Went Well" section with at least two entries.

`EVIDENCE:` block spec — the block must include: the incident ID or incident date, the root cause statement (one sentence), the count of action items generated, and confirmation that every action item has an owner and due date. Example form:

```
EVIDENCE:
- Incident: YYYY-MM-DD <short title>
- Root cause: <one-sentence structural cause>
- Actions: N items, all with owner and due date
- Document sections complete: Summary, Impact, Timeline, Root Cause, Contributing Factors, What Went Well, What Could Be Improved, Action Items
```

## Adapt from

No direct external upstream. Pattern synthesised from standard blameless postmortem practice (Google SRE, PagerDuty) and the Five Whys method. No verbatim copy; `author: Donal Moloney` applies.
