# v3 First Population Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the first 12 experimental skills in the v3 tier, per `docs/superpowers/specs/2026-06-10-v3-skills-design.md`.

**Architecture:** Twelve independent SKILL.md files under `v3/skills/<name>/` (flat layout), one per ideated concept across four themes. Each file is an idea capture, not working machinery — no scripts, hooks, or ledgers get built. A README table indexes the tier, and a `skill-auditor` agent run verifies the batch.

**Tech Stack:** Markdown only. Verification via `grep` structure checks and the project's `skill-auditor` agent.

**IMPORTANT — no commits:** This project is intentionally NOT a git repository (see CLAUDE.md). Skip all commit steps; there are none in this plan. Do not run `git init`.

**Every SKILL.md in this plan must satisfy:** frontmatter with `name`, `description` (stating WHEN to use it), `tier: v3`, `status: experimental`; body containing the concept/mechanism, a `## Why this might be crazy enough to work` section, and a `## Known risks / absurdities` section. Full file content is given in each task — write it verbatim.

---

### Task 1: skill-darwin

**Files:**
- Create: `v3/skills/skill-darwin/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: skill-darwin
description: Use when a high-traffic skill feels stale, contested, or chronically half-followed — evolves the skill text itself by maintaining competing variant phrasings and letting session outcomes select the winner.
tier: v3
status: experimental
---

# skill-darwin

Natural selection for skill text. For any skill on its watch list, maintain a
small population of 2–4 variant phrasings — e.g. three different wordings of the
same debugging checklist, one terse, one narrative, one checklist-with-threats.
At session start, a hook (described, not built) rolls dice and loads exactly one
variant. The session proceeds normally.

At session end, a fitness scorer updates a per-variant ledger
(`v3/skills/skill-darwin/fitness.json`, described only) with cheap outcome
signals: did the task pass verification on the first try? How many times did the
user correct course? Did the skill get abandoned mid-session? Variants
accumulate win rates. Periodically, the weakest variant is mutated — Claude
rewrites its lowest-performing section while keeping the skill's intent — and
the cycle repeats. Strong variants breed: their best sections get spliced into
new candidates.

## Why this might be crazy enough to work

A/B testing prompt text is the one optimization loop where the artifact
(markdown) and the mutation operator (Claude rewriting markdown) are the same
medium — zero infrastructure beyond a JSON ledger and a dice-roll hook.

## Known risks / absurdities

The fitness signal is hopelessly noisy at n=5 sessions; you may evolve skills
that won the coin flips, not the arguments. Mitigation to explore at graduation
time: minimum sample sizes per variant before any selection event, and never
mutating the current champion.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/skill-darwin/SKILL.md`
Expected: all four lines print.

### Task 2: skill-scar-tissue

**Files:**
- Create: `v3/skills/skill-scar-tissue/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: skill-scar-tissue
description: Use immediately after a verification failure or user correction — performs a post-incident graft, appending a dated quarantined rule to the skill that should have prevented the failure.
tier: v3
status: experimental
---

# skill-scar-tissue

Checklists that remember how they got hurt. After any session event where the
user corrects Claude or a verification step fails, run a post-incident graft:

1. **Attribute:** identify which skill *should* have prevented this failure.
   If no skill plausibly owns it, stop — do not graft (see risks).
2. **Graft:** append a dated, quarantined `## Scar` block to that skill — one
   line of rule derived from the specific failure, plus the date and a
   one-line incident reference. Scars live at the bottom of the skill,
   clearly marked as probationary.
3. **Promote or prune:** a scar that fires again (same failure pattern caught
   or repeated) gets promoted into the skill body proper, written in the
   skill's own voice. A scar that never fires again decays and is pruned
   after N sessions (suggest N=10, recorded in the scar line itself).

This triggers on failure and correction events, never on a schedule. The skill
evolves only when reality pushes back.

## Why this might be crazy enough to work

It mirrors how human checklists actually evolve — aviation checklists are
literally accident scar tissue — and quarantining new rules in a probation zone
solves the classic "self-edits slowly degrade the skill" problem: nothing enters
the skill body without recurring evidence.

## Known risks / absurdities

Blame attribution is the hard part — Claude may graft scars onto the wrong
skill, slowly turning every skill into a junk drawer of irrelevant warnings.
The "no plausible owner → no graft" rule is the only brake; whether it holds is
exactly what this experiment tests.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/skill-scar-tissue/SKILL.md`
Expected: all four lines print.

### Task 3: skill-cannibal

**Files:**
- Create: `v3/skills/skill-cannibal/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: skill-cannibal
description: Use monthly, or whenever the total skill corpus exceeds a context-budget threshold — runs a metabolism pass where skills compete for a fixed token budget and underperformers get eaten.
tier: v3
status: experimental
---

# skill-cannibal

Skills compete for a scarce resource: tokens in the context window. On each
metabolism pass:

1. **Score** every skill in the repo on invocations-per-week versus token
   weight (a ledger of invocation counts is described, not built).
2. **Eat** underperformers: extract the one or two genuinely useful lines from
   a low-scoring skill, absorb them into the strongest related skill, and move
   the husk to an `archive/` directory with a note naming where its organs
   went. Nothing is deleted — archival is reversible.
3. **Fuse:** when the ledger shows two skills habitually loaded together,
   propose fusing them into a hybrid offspring with a new name; the parents
   get archived with pointers to the child.

The pass produces a written digestion report (what was eaten, what absorbed
what, proposed fusions awaiting human approval) — eating and fusing are
proposals to the human, never autonomous deletions.

## Why this might be crazy enough to work

Context windows are a real scarce resource, and scarcity is the only forcing
function that ever produces genuine consolidation instead of endless accretion.
Every skill collection grows monotonically until something is allowed to eat.

## Known risks / absurdities

It might eat a low-frequency, high-criticality skill — the fire extinguisher
you use once a year — because frequency is a terrible proxy for value. The
human-approval gate and reversible archiving are load-bearing, not optional.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/skill-cannibal/SKILL.md`
Expected: all four lines print.

### Task 4: agent-bazaar

**Files:**
- Create: `v3/skills/agent-bazaar/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: agent-bazaar
description: Use as an alternative dispatch mode when a plan has 4+ parallelizable tasks — an auctioneer posts each task and competing subagents bid for the work with sealed approach-plus-cost estimates.
tier: v3
status: experimental
---

# agent-bazaar

A market instead of an assignment. When a plan contains 4 or more
parallelizable tasks:

1. **Post:** an auctioneer agent lists each task with an estimated price — a
   complexity budget in turns/tokens.
2. **Bid:** 3–5 bidder subagents each submit a sealed bid: a short approach
   sketch plus their own cost estimate. Bids are sealed — no bidder sees
   another's bid before submitting.
3. **Award:** the cheapest *credible* bid wins each task. Credibility is
   judged by the auctioneer against the approach sketch, not the price alone.
4. **Settle:** bidders who blow their estimate get a reputation penalty
   recorded in a ledger (described, not built) that handicaps their future
   bids; accurate estimators earn trust.

The losing bids are not waste: they are free plan review. Divergent approach
sketches for the same task are a signal the task is underspecified.

## Why this might be crazy enough to work

Forcing agents to commit to a cost estimate *before* working is a known
calibration trick — the bid itself is a cheap plan-quality signal, and you get
multi-perspective plan review for free from the losing bids.

## Known risks / absurdities

The economy may be theater — all bidders are the same model, so price
competition may just select for the most overconfident hallucinated estimate.
The reputation ledger is the proposed corrective; whether same-model agents can
develop genuinely distinct bidding track records is the open question.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/agent-bazaar/SKILL.md`
Expected: all four lines print.

### Task 5: predator-prey-review

**Files:**
- Create: `v3/skills/predator-prey-review/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: predator-prey-review
description: Use on request as an adversarial alternative to standard code review — co-evolving predator agents hunt for bugs the prey agent did not already know about.
tier: v3
status: experimental
---

# predator-prey-review

Two co-evolving agent lineages per project:

- **Prey** agents write the code — and simultaneously write a *private*
  "weaknesses I'm hiding" note listing every shortcut, doubt, and known soft
  spot. The note is sealed from the predator.
- **Predator** agents hunt the code for bugs, and score points **only** for
  finding issues NOT on the prey's note. Re-reporting what the author already
  knew earns nothing — the predator must hunt past the obvious.

After each round, both lineages update from the kill log: the predator's
hunting playbook gains the patterns that scored, the prey's defensive
checklist gains the weaknesses that got caught. Both playbooks persist across
sessions, so the arms race compounds.

**Boundary:** v2 `red-team-spec` attacks specs pre-implementation, one-shot.
This skill is post-implementation, on code, and co-evolutionary — the
adversaries learn each other across rounds.

## Why this might be crazy enough to work

The "score only for unlisted bugs" rule breaks the lazy equilibrium where
adversarial reviewers re-report obvious issues, and the two persistent
playbooks mean the arms race compounds across sessions instead of resetting.

## Known risks / absurdities

Goodharting — predators learn to manufacture exotic non-issues, prey learn to
write deliberately bug-dense decoy code, and the ecosystem optimizes for drama
over correctness. A human judge over the kill log is probably required before
any score counts.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/predator-prey-review/SKILL.md`
Expected: all four lines print.

### Task 6: parliament-of-ghosts

**Files:**
- Create: `v3/skills/parliament-of-ghosts/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: parliament-of-ghosts
description: Use when a decision is flagged irreversible or expensive — convenes five persistent persona-agents who debate, vote with track-record-weighted ballots, and file dissents that get re-read on failure.
tier: v3
status: experimental
---

# parliament-of-ghosts

For any major architectural decision, convene a fixed parliament of five
persistent persona-agents:

- **The Maintainer-in-Five-Years** — argues from future maintenance cost.
- **The Security Paranoiac** — argues from attack surface.
- **The Intern Who Inherits This** — argues from learnability.
- **The User at 3 AM** — argues from failure-mode experience.
- **The Accountant** — argues from cost and scope.

They debate, form coalitions, and vote. Crucially, each persona keeps a
cross-session memory file of its past votes and *whether reality vindicated
them* — a persona whose warnings keep coming true gains voting weight; one
whose doom never arrives loses it. The parliament is a slow ensemble learner
tuned to this specific project's failure modes.

Outvoted personas file written dissents. When a decision later causes a
failure, the dissents on that decision are mandatorily re-read — the ghosts
get to say "I told you so," and their weights update accordingly.

## Why this might be crazy enough to work

Weighted voting with track-record feedback turns a gimmicky persona debate
into a slow ensemble learner — the personas that predict this project's actual
failure modes literally accumulate power.

## Known risks / absurdities

Five personas sampled from one model may be a parliament with one voter wearing
five hats — correlated errors defeat ensembles. The dissent files could also
balloon into a haunted house of grudges nobody reads. Vindication-checking is
manual and honest only if the human plays referee.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/parliament-of-ghosts/SKILL.md`
Expected: all four lines print.

### Task 7: project-hippocampus

**Files:**
- Create: `v3/skills/project-hippocampus/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: project-hippocampus
description: Use via session start/end hooks — consolidates each session into episodic memories and replays the relevant ones as a briefing next time the same area is touched, with a forgetting curve.
tier: v3
status: experimental
---

# project-hippocampus

Episodic memory for a project, with biology's garbage collector.

**Consolidation (session end):** write 3–5 episodes to a memory directory
(described, not built). Each episode is situation → action → outcome, with
concrete file paths and an emotional valence tag (`frustrating`, `smooth`,
`surprising`). Episodes are small, dated, and specific.

**Recall (session start):** retrieve episodes relevant to the current task and
inject a one-paragraph briefing: "last time we touched this area, X happened,
we did Y, it went Z." The briefing is context, not instruction.

**Forgetting curve:** unrecalled episodes lose detail over sessions — they get
summarized down, then merged, then dropped. Recalled episodes get reinforced
and re-detailed. This Ebbinghaus mechanic is the point: the store cleans
itself, and what survives is what keeps being relevant.

## Why this might be crazy enough to work

The decay-unless-recalled mechanic is a self-cleaning filter that solves
memory's real failure mode — not forgetting, but drowning in stale notes —
using nothing but periodic re-summarization.

## Known risks / absurdities

Retrieval is keyword-grade without embeddings, so the hippocampus may
confidently brief you about the wrong "last time," and a false memory presented
as a briefing is worse than no memory. Valence tags could also bias work
("dread" episodes making Claude avoid files that were fixed long ago).
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/project-hippocampus/SKILL.md`
Expected: all four lines print.

### Task 8: belief-ledger

**Files:**
- Create: `v3/skills/belief-ledger/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: belief-ledger
description: Use whenever an assumption is stated during debugging or planning, and at session end — tracks the project's load-bearing beliefs as explicit probabilities and audits decisions when a belief collapses.
tier: v3
status: experimental
---

# belief-ledger

Decisions get recorded; the *evidence under them* silently rots. This skill
makes belief revision a first-class event.

**Capture:** whenever Claude states a load-bearing assumption during debugging
or planning — "the flaky test is timing-related," "users never hit the legacy
path" — record it in a ledger (described, not built) as a probabilistic
statement: the claim, a probability, the date, and what currently rests on it.

**Update:** every session ends with one question: did anything observed today
move any belief? Adjust probabilities with a one-line justification. "Huh,
weird" moments are exactly the trigger — weirdness is evidence.

**Collapse audit:** when a belief crosses below 50%, a mandatory audit fires:
list every decision that was built on this assumption — what is now standing
on sand? The audit output is a punch list, not automatic rework.

**Boundary:** v2 `decision-ledger` records decisions made and why. This skill
records the *evidence and assumptions underneath* decisions, with explicit
uncertainty. A decision cites beliefs; a belief collapse re-opens decisions.

## Why this might be crazy enough to work

Making belief revision a first-class event converts "huh, weird" moments into
structural updates — which is the actual mechanism of expertise, normally
locked inside a senior engineer's head.

## Known risks / absurdities

The probabilities are vibes wearing a number costume, and the collapse audit
could trigger paralyzing re-litigation over a belief that drifted to 49%.
Hysteresis (audit at 40%, not 50%) and a cap on audit frequency are probably
needed before this is usable.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/belief-ledger/SKILL.md`
Expected: all four lines print.

### Task 9: inherited-instincts

**Files:**
- Create: `v3/skills/inherited-instincts/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: inherited-instincts
description: Use as a pre-task scan in any repo — surfaces firing instincts from a cross-project genome of pattern-to-emotion reflexes, presented as gut feelings rather than directives.
tier: v3
status: experimental
---

# inherited-instincts

Cross-project transfer fails when you copy rules, because context differs. But
*instincts* — terse, context-free pattern→emotion pairs — are exactly the part
of senior-engineer intuition that does transfer:

- `dread: config that works locally`
- `twitch: any function named process()`
- `comfort: a test that failed before it passed`

The genome lives in a single global instinct file (described, not built) that
travels across all repos. Before starting a task, scan the genome: any instinct
whose pattern matches the current situation *fires* and is surfaced as a gut
feeling — "something here smells like config drift" — never as a directive.

**Selection:** an instinct that fires and proves right gets strengthened
(dominant). One that fires and proves wrong in the new context gets marked
recessive — still carried, no longer surfaced, revivable if it starts being
right again. New instincts are bred from repeated episodes (a natural output
of project-hippocampus, if both exist).

## Why this might be crazy enough to work

Instincts are deliberately context-free pattern→emotion pairs, which is the
transferable core of intuition — and the dominant/recessive mechanic handles
negative transfer instead of pretending it won't happen.

## Known risks / absurdities

This is deliberately engineering prejudices into the model. A wrong dominant
instinct ("dread: ORMs") could silently bias every project's architecture for
months before enough contradicting evidence demotes it. The genome needs an
occasional human eugenics review, which is as uncomfortable as it sounds.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/inherited-instincts/SKILL.md`
Expected: all four lines print.

### Task 10: ghost-run

**Files:**
- Create: `v3/skills/ghost-run/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: ghost-run
description: Use as an optional gate between writing-plans and executing-plans — hallucinate the entire plan execution into a ghost transcript first, then halt real execution wherever reality diverges from the prediction.
tier: v3
status: experimental
---

# ghost-run

A surprised plan is a wrong plan. Before executing any multi-step plan:

1. **Simulate:** a simulator agent steps through every plan item and writes a
   ghost transcript — concretely *predicting* what each command will output,
   which files will conflict, where tests will fail, what each diff will look
   like. The predictions must be specific enough to be wrong.
2. **Execute with a tripwire:** during real execution, diff reality against
   the ghost at each step. Small divergences (line numbers, timing) pass.
   Divergence beyond threshold — a command failing that the ghost passed, a
   file the ghost didn't know existed, a test failing differently — HALTS
   execution.
3. **Diagnose before resuming:** a halt means the world-model that wrote the
   plan is wrong somewhere. Update the understanding (and usually the plan)
   before continuing. The halt fires *before* the misunderstanding compounds.

## Why this might be crazy enough to work

The value isn't in the simulation being right — it's that
divergence-from-prediction is a cheap, automatic "your model of this codebase
is wrong, stop" tripwire, and it fires at the first symptom instead of three
broken steps later.

## Known risks / absurdities

The ghost is generated from the same flawed world-model that wrote the plan,
so they may share every blind spot — the diff then catches only trivia while
radiating false confidence. Threshold tuning is also unsolved: too tight and
every run halts on noise, too loose and the tripwire never fires.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/ghost-run/SKILL.md`
Expected: all four lines print.

### Task 11: premortem-multiverse

**Files:**
- Create: `v3/skills/premortem-multiverse/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: premortem-multiverse
description: Use when a change touches data, auth, money, or anything flagged irreversible — parallel obituary agents each write the future incident report from a different doom genre, and convergent failure chains become mandatory tests.
tier: v3
status: experimental
---

# premortem-multiverse

Forward "what could go wrong?" brainstorming reliably misses risks that
backwards reasoning from a stipulated disaster finds — the premortem effect.
This skill industrializes it:

1. **Fork doom worlds:** spawn 3–4 parallel obituary agents, each assigned a
   different doom genre — data-loss world, performance-collapse world,
   security-breach world, angry-user world.
2. **Write the incident report:** each agent is told: *it is six months later
   and this change destroyed the project — write the incident report
   explaining exactly how.* Reports MUST cite real files and real code paths
   in the actual codebase; uncited doom is discarded.
3. **Mine for convergence:** failure chains that two or more independent
   reports cite through the same code are the signal. Each convergent chain
   becomes a mandatory test or a plan amendment before the change proceeds.

## Why this might be crazy enough to work

Backwards reasoning from a stipulated disaster reliably extracts risks that
forward brainstorming misses, and forcing citations to real files keeps the
fiction anchored to the actual codebase instead of generic catastrophe.

## Known risks / absurdities

Four creative-writing exercises may converge on generic doom ("the migration
had no rollback") and add ceremony to every scary-sounding change. The
convergence filter is the only defense — if the reports agree on something
boring, the answer is a boring test, not a longer ritual.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/premortem-multiverse/SKILL.md`
Expected: all four lines print.

### Task 12: branch-historian

**Files:**
- Create: `v3/skills/branch-historian/SKILL.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: branch-historian
description: Use when a project feels stuck or rotten, or when architecture stalls keep recurring — walks past decisions backwards and actually spikes the road not taken in throwaway worktrees, returning a regret report.
tier: v3
status: experimental
---

# branch-historian

A time-travel debugger for decisions. When a project feels stuck:

1. **Walk backwards:** read the decision history (v2 `decision-ledger` if
   present, otherwise commit messages and specs) and pick the 2–3 most
   contested past decisions — the ones with real alternatives rejected.
2. **Build the counterfactual:** for each, spawn an agent in a throwaway git
   worktree to *actually partially build* the road not taken, on a fixed
   budget (e.g. 30 minutes: "spike what this module looks like if we'd chosen
   SQLite"). The spike mechanics compose with v2 `spike-in-worktree` — this
   skill decides WHAT to spike and WHY; that skill handles the worktree
   discipline.
3. **File the regret report:** for each counterfactual — better / worse /
   same, with the artifact attached. The report either vindicates the past
   decision (now with evidence, not sunk-cost rationalization) or recommends
   a heresy: deliberately re-deciding it.

## Why this might be crazy enough to work

Worktrees make counterfactual histories *materially cheap* — instead of
arguing about the road not taken, you build 5% of it and look at it,
converting unfalsifiable hindsight debates into artifacts.

## Known risks / absurdities

Regret-driven development: a 30-minute spike always looks cleaner than three
months of accumulated reality, so the alternate timeline systematically wins
and the skill becomes a rewrite-everything machine. The regret report must
weight the champion's battle scars (handled edge cases, fixed bugs) or it is
structurally biased toward heresy.
```

- [ ] **Step 2: Verify structure**

Run: `grep -E '^(tier: v3|status: experimental|## Why this might be crazy enough to work|## Known risks / absurdities)' v3/skills/branch-historian/SKILL.md`
Expected: all four lines print.

### Task 13: v3 README skill index

**Files:**
- Modify: `v3/README.md` (currently 9 lines; append a table at the end)

- [ ] **Step 1: Append the "Current skills" table**

Append to the end of `v3/README.md` (after the existing Rules list, with a blank line before the heading):

```markdown

## Current skills

| Skill | Theme | One-line hook |
|-------|-------|---------------|
| `skill-darwin` | Self-improving | Skill text evolves via variant A/B testing and fitness-scored mutation |
| `skill-scar-tissue` | Self-improving | Failures graft probationary rules onto the skill that should have prevented them |
| `skill-cannibal` | Self-improving | Skills compete for a token budget; underperformers get eaten or fused |
| `agent-bazaar` | Swarms & ecology | Subagents bid for tasks with sealed cost estimates; blown estimates cost reputation |
| `predator-prey-review` | Swarms & ecology | Adversarial reviewers score only for bugs the author didn't already know about |
| `parliament-of-ghosts` | Swarms & ecology | Five persona-agents vote on big decisions with track-record-weighted ballots |
| `project-hippocampus` | Memory & learning | Episodic session memories with an Ebbinghaus forgetting curve |
| `belief-ledger` | Memory & learning | Load-bearing assumptions tracked as probabilities; collapses trigger decision audits |
| `inherited-instincts` | Memory & learning | A cross-project genome of pattern→emotion reflexes, surfaced as gut feelings |
| `ghost-run` | Simulation | Hallucinate the whole plan execution first; halt the real run on divergence |
| `premortem-multiverse` | Simulation | Parallel doom-genre incident reports; convergent failure chains become tests |
| `branch-historian` | Simulation | Spike the road not taken in throwaway worktrees; return a regret report |
```

- [ ] **Step 2: Verify the table**

Run: `grep -c '^| \`' v3/README.md`
Expected: `12`

### Task 14: Batch audit

**Files:** none created — verification only.

- [ ] **Step 1: Structural sweep over the whole batch**

Run:
```bash
for f in /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v3/skills/*/SKILL.md; do
  for p in '^tier: v3$' '^status: experimental$' '^name: ' '^description: ' '^## Why this might be crazy enough to work$' '^## Known risks / absurdities$'; do
    grep -q "$p" "$f" || echo "MISSING $p in $f"
  done
done; echo SWEEP-DONE
```
Expected: only `SWEEP-DONE` (no MISSING lines), and `ls v3/skills | wc -l` is 12.

- [ ] **Step 2: Run the skill-auditor agent**

Dispatch the project's `skill-auditor` agent over `v3/skills/` with this prompt:
"Audit all 12 skills in /Users/donalmoloney/PycharmProjects/ObraSuperPowersSupercharged/v3/skills/ against the v3 tier rules (v3/README.md): frontmatter must include name, description stating WHEN, tier: v3, status: experimental; body must include a 'Why this might be crazy enough to work' section. v1/v2 quality bars do NOT apply — flag only rule violations, not polish issues. Report findings; do not fix anything."
Expected: clean report, or a findings list. Fix any rule violations it reports in the affected SKILL.md and re-run the Step 1 sweep.

- [ ] **Step 3: No commit**

This project is intentionally not a git repository. Do not commit; the plan is complete when the audit passes.
