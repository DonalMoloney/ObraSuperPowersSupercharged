---
name: consensus-decision
description: Use for a contested decision — spawn independent deciders with diverse priors, collect votes plus rationale, and surface WHERE they disagree and why, not just the majority. Feeds decision-ledger and write-adr a real spread.
author: Donal Moloney
track: C
type: process
chains-to: write-adr
---

## Not this skill if
- The decision is uncontested or low-stakes — just decide and note it
- You're generating ideas, not choosing between them — use `mash-ideas`
- You already have a verdict and need to document it — go straight to `write-adr`
- The decision requires live experimentation to resolve — use `spike-it` first

# consensus-decision — disagreement made visible

## Purpose

Replace one confident opinion with a structured panel. The value is the *disagreement map*: knowing
which option wins, by how much, and exactly where reasonable agents diverge. A 9–0 verdict
justifies different confidence than a 5–4 split — this skill makes that spread visible and
actionable before you freeze the decision.

## Core rule

> **Rule:** Report the spread, not just the winner. A 5–4 split and a 9–0 split demand different
> confidence — surface dissent and its reasoning, never bury it.

## Triggers

**Use when:**
- Choosing between two or more architecture options and the team keeps revisiting the choice
- Evaluating a build-vs-buy trade-off with non-obvious cost/risk curves
- Resolving a contested trade-off where different stakeholder lenses (cost, risk, UX, maintenance) pull in different directions
- A decision has been deferred multiple times because no single framing feels conclusive
- You need a defensible record of why option X was chosen over Y and Z

**Don't use when:**
- Only one option is technically viable — a panel adds ceremony without value
- The decision is reversible in under an hour — decide, act, observe
- You have fewer than two meaningfully distinct options — use `challenge-spec` to generate options first
- The disagreement is about missing facts, not trade-offs — gather facts first, then panel

## The pattern

```
panel(
  options,                        // array of candidate choices
  async (prior) => vote(prior),   // map — each agent picks with its own prior
  async (votes) => tally(votes)   // reduce — spread + disagreement map
);
```

Each decider agent receives: the decision statement, the candidate options, its assigned prior
(cost-first / risk-first / user-first / maintenance-first / security-first), and an instruction
to pick one option and state the one load-bearing assumption its choice depends on.

The tally stage clusters rationales across agents, not just counts votes.

## Steps

### 1. Frame the decision

State the decision in one sentence. List the candidate options explicitly — no "other" or "TBD"
entries. Attach any non-negotiable constraints (budget ceiling, deadline, existing contracts) that
all deciders must treat as fixed. A blurry framing produces a blurry spread; sharpen the question
before dispatching agents.

### 2. Assign priors and dispatch the panel (parallel)

Spawn N independent decider agents (minimum 4, typically 5–7 for contested decisions). Assign
each a distinct evaluative prior:

- **Cost-first** — minimise total cost of ownership over 24 months
- **Risk-first** — minimise probability of catastrophic failure or rollback
- **User-first** — maximise end-user experience and reliability
- **Maintenance-first** — minimise ongoing operational burden on the team
- **Security-first** — minimise attack surface and compliance exposure

For decisions with a clear domain bias (e.g., a pure cost question), replace weaker priors with
domain-specific variants. Do not assign two agents the same prior — diversity is the mechanism.
Dispatch all agents in parallel; no agent waits on another's output.

Each agent must return:
- The option it selected
- A two-to-four sentence rationale anchored in its prior
- The single load-bearing assumption its choice depends on (the one fact that, if wrong, would flip its vote)

### 2b. Anonymized peer-review pass (optional, for high-stakes splits)

Before tallying, run one round of blind peer critique. Collect the N rationales, **strip every prior label and shuffle them** (relabel A–E), then send the anonymized set back to the same deciders and ask each to flag the strongest argument *other than their own* and any load-bearing assumption a peer made that they distrust. Anonymizing kills deference to a prior's title ("the security-first agent must be right about risk") and surfaces error-catches the first pass missed. Feed the flags into the disagreement map below.

For multi-round debate, stop early when the vote distribution stops moving: if the spread is unchanged for two consecutive rounds, further rounds just burn tokens — freeze and tally.

### 3. Tally votes and build the disagreement map

Collect all agent responses. Produce:

**Vote tally table**

| Option | Votes | Priors in favour |
|---|---|---|
| Option A | 4 | cost-first, maintenance-first, risk-first, security-first |
| Option B | 2 | user-first, ... |

**Disagreement map** — group rationales by the assumption they depend on, not by the option they
support. Two agents voting for different options but sharing the same underlying assumption are
*latent allies*; two agents voting for the same option but for contradictory reasons signal a
fragile coalition. Label each cluster:

- Assumption: *"latency under 50 ms is achievable with Option A at current traffic"*
  - Agents holding this assumption: cost-first, maintenance-first
  - Agents rejecting this assumption: risk-first

Highlight the one or two assumptions where the camps diverge most sharply — these are the
load-bearing uncertainties the decision actually rests on.

**Classify each divergence** as one of two kinds — the disposition differs:

- **Value tension** — both sides are right, they just weight different goods (cost vs UX, speed vs safety). Preserve it; don't "resolve" it. Record it as a standing trade-off in the ADR's *What you lose* note (whichever option wins, name what the losing camp was protecting).
- **Error catch** — one camp spotted a real flaw the others missed (a broken assumption, an overlooked failure mode). This is decisive evidence, not a tie — let the minority override the majority when its reasoning survives scrutiny.

Conflating the two is the classic failure: treating a genuine error-catch as "just a difference of opinion" buries the one finding that should have flipped the vote.

### 4. Resolve or accept the split

If the spread is 4–1 or wider with a clear assumption cluster, accept the majority verdict and
note the minority assumption as a watch condition. If the split is tight (3–2 or 4–3), do one of:

- Resolve the load-bearing assumption with a spike (`spike-it`) before freezing the decision
- Escalate to a human decision-maker with the disagreement map as the briefing document
- Accept the majority verdict but record the minority assumption as an explicit risk in the ADR

Do not manufacture false consensus. A 4–3 split recorded honestly is more useful than a 7–0
result achieved by homogenising the priors.

### 5. Record and freeze

Log the full spread — vote tally, disagreement map, resolved or accepted uncertainties — to
`decision-ledger`. Then pass the output to `write-adr` to freeze the verdict with its context,
options considered, and consequences. The ADR must reference the disagreement map; a decision
recorded without its dissent is incomplete.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Assigning two agents the same prior | Each agent must have a distinct prior; duplicated priors produce correlated votes that look like consensus but are just echo |
| Reporting only the winning option | Always publish the full vote tally and disagreement map — a 5–4 split is a different signal than a 9–0 |
| Treating load-bearing assumptions as footnotes | Promote the key assumption cluster to the top of the output; it is the actionable finding, not a caveat |
| Spawning agents without fixing the option list | Lock the candidate options before dispatch; agents that invent new options mid-panel produce incomparable rationales |
| Forcing a verdict from a tight split | A 3–2 or 4–3 split often means the load-bearing assumption is unresolved — spike or escalate rather than override dissent |
| Feeding the ADR only the winner | `write-adr` must receive the full spread; an ADR without the options-considered rationale and minority view is an incomplete record |

## Output

- Vote tally table (option | vote count | priors in favour)
- Per-agent rationale summaries
- Disagreement map: assumption clusters, agents per cluster, flip condition per cluster
- Recommended path: majority verdict or escalation trigger
- Input package ready for `decision-ledger` and `write-adr`

## Proof

Hand off to `write-adr` once the disagreement map is complete and the verdict is accepted or
escalated.

The `PROVEN BY:` block must contain:
- Count of agents dispatched and list of priors assigned
- Vote tally (option → vote count) confirming no options were silently excluded
- At least one named load-bearing assumption per split cluster
- Disposition of the split (accepted majority / spiked / escalated) with reason
- Confirmation that `decision-ledger` entry was written before `write-adr` was invoked

## Adapt from
- **`obra/superpowers-skills`** — `skills/communication/` (decision-surfacing framing).
  <https://github.com/obra/superpowers-skills>
- **`composable-models/llm_multiagent_debate`** — multi-agent debate → consensus method.
  <https://github.com/composable-models/llm_multiagent_debate>
- **`ngmeyer/council-review`** (MIT) — anonymized/shuffled peer review (step 2b), value-tension vs
  error-catch classification of disagreements (step 3), and KS-style adaptive early-stop.
  <https://github.com/ngmeyer/council-review>
