# v1 Skill Renaming Options

A decision menu of better-name candidates for each of the 14 v1 skills. Pick at most
one per skill; "Keep" is always a valid choice and is the default for names that
already work.

This menu is deliberately separate from `SUPERCHARGING-OPTIONS.md`: renames change a
skill's *identity*, supercharges change its *content*. Decide them independently —
a rename can land without any supercharge, and vice versa.

> **Tier-rule caveat:** the v1 discipline says supercharged skills *keep the upstream
> skill name*. Adopting any rename below therefore requires one of:
> 1. amending the v1 rule in `CLAUDE.md` to allow renames (recording the upstream name
>    in frontmatter, e.g. `upstream-name:`), or
> 2. using the new name only as a discoverability alias in the description, or
> 3. reserving the new name for a v2+ derivative skill.
> Decide that policy once before adopting any rename.

## Naming criteria (from v1's own `writing-skills`)

- **Verb-first gerunds** for processes: `creating-skills`, not `skill-creation`.
- **Name the goal or core insight, not the mechanism**: `condition-based-waiting`
  beats `async-test-helpers`.
- **Trigger matching**: a future Claude scanning names should recognize "that's my
  situation" — names that read like the moment of use win.
- **Searchability beats elegance**: industry-standard terms (e.g. TDD) carry search
  weight a cleverer name loses.
- **Shorter wins ties.**

## using-superpowers — naming

**Current issue:** Names the brand, not the act — gives zero clue it's the
skill-routing entry point that fires before every response.

- **Option A — `routing-to-skills`.** Verb-first, names exactly what it does: route the
  incoming message to the right skill. Pairs naturally with the routing-table upgrade
  (using-superpowers Option B in `SUPERCHARGING-OPTIONS.md`).
- **Option B — `checking-skills-first`.** Names the discipline (check before ANY
  response) rather than the mechanism. Reads like the rule it enforces.
- **Option C — Keep.** The brand name is what plugin users type and recognize;
  renaming the entry skill has the highest ecosystem-breakage cost of any rename here.

> **Recommended: C (keep).** Entry-point identity is load-bearing for the whole plugin;
> spend the renaming budget elsewhere. A is the best alias if the policy allows one.

## brainstorming — naming

**Current issue:** Generic — "brainstorming" suggests loose idea generation, but the
skill is a gated pipeline ending in an approved spec.

- **Option A — `shaping-ideas-into-specs`.** Names the journey and the artifact; makes
  the terminal state (a spec) visible from the name alone.
- **Option B — `designing-before-coding`.** Names the discipline and the trigger
  moment — about to code without a design? That's the violation symptom.
- **Option C — Keep.** Matches how users actually invoke it ("/brainstorming", "let's
  brainstorm"); natural-language trigger matching is genuinely strong.

> **Recommended: B.** It's trigger-shaped like the tier's other discipline names
> (verification-before-completion) and tells you *when*, not just *what*. Keep
> "brainstorm" as a keyword in the description so invocation habits still match.

## writing-plans — naming

**Current issue:** Mild — "plans" is broad (project plans? test plans?).

- **Option A — `writing-implementation-plans`.** One word longer, removes all
  ambiguity about which kind of plan.
- **Option B — `planning-bite-sized-tasks`.** Names the skill's core insight (2–5
  minute steps), but buries the artifact.
- **Option C — Keep.** Short, verb-first, already conventional.

> **Recommended: C (keep).** A is acceptable if disambiguation ever becomes a real
> problem; B trades clarity for cleverness.

## executing-plans — naming

**Current issue:** Fine alone, but indistinguishable from subagent-driven-development
at the name level — you can't tell from the names that these are two modes of the same
job.

- **Option A — `executing-plans-inline`.** Names the distinguishing property: same
  session, no subagents. Pairs with renaming its twin (see next section) so the pair
  reads as a mode switch.
- **Option B — `executing-plans-solo`.** Same idea, slightly more vivid; "solo" =
  no subagent workforce.
- **Option C — Keep.** Shortest; relies on descriptions to disambiguate.

> **Recommended: A.** The supercharging direction already recommended for this skill
> (degraded-mode twin, executing-plans Option C in `SUPERCHARGING-OPTIONS.md`) makes
> the pairing explicit — the names should too.

## subagent-driven-development — naming

**Current issue:** Noun-phrase (violates the gerund convention) and names the
mechanism (subagents) rather than the job (executing a plan).

- **Option A — `executing-plans-with-subagents`.** Verb-first, names the job AND the
  mechanism, and makes the mode-switch relationship with executing-plans readable
  straight from the directory listing.
- **Option B — `orchestrating-task-subagents`.** Verb-first, emphasizes the
  controller/orchestrator role the skill actually teaches.
- **Option C — Keep.** "Subagent-driven development" has brand recognition in the
  superpowers ecosystem and reads like a methodology name (like TDD).

> **Recommended: A.** Biggest clarity win of any rename in the tier: the two execution
> skills become `executing-plans-inline` / `executing-plans-with-subagents` — the
> choice between them is self-documenting.

## dispatching-parallel-agents — naming

**Current issue:** Almost none — verb-first, accurate. Slight overlap confusion with
subagent-driven-development ("don't both use agents?").

- **Option A — `parallelizing-independent-work`.** Names the trigger condition
  (independent work items) instead of the mechanism; the decision test in the skill is
  literally "are they independent?"
- **Option B — `fanning-out-agents`.** Vivid and short; "fan-out" is the standard
  distributed-work term.
- **Option C — Keep.**

> **Recommended: C (keep).** The current name is accurate and searchable; A's
> trigger-naming is the only upgrade worth considering if confusion with SDD persists.

## test-driven-development — naming

**Current issue:** None worth fixing — it's the industry-canonical term.

- **Option A — Keep.** Maximum searchability, zero re-learning.
- **Option B — `writing-tests-first`.** Verb-first and trigger-shaped, but throws away
  the most recognized acronym in the discipline.
- **Option C — `red-green-refactor`.** Names the cycle; cute, but a worse search target
  for someone thinking "I need to add a feature".

> **Recommended: A (keep).** Searchability beats convention here, decisively.

## systematic-debugging — naming

**Current issue:** "Systematic" is a quality adjective, not a goal — the skill's actual
iron law is *root cause before fixes*.

- **Option A — `debugging-to-root-cause`.** Names the destination the iron law
  enforces; "root cause" is exactly what a violating agent is about to skip.
- **Option B — `finding-root-causes`.** Shortest goal-named option, but loses the
  word "debugging", which is the term agents search when a test fails.
- **Option C — Keep.** Established within the obra ecosystem; "systematic" deliberately
  contrasts with the random-fixes anti-pattern.

> **Recommended: A.** Keeps the searchable word "debugging", adds the core insight, and
> stays verb-first. C is a respectable second.

## verification-before-completion — naming

**Current issue:** Noun chain (violates gerund convention) and a mouthful — though the
meaning is clear.

- **Option A — `verifying-before-claiming-done`.** Gerund form of the same idea;
  "claiming done" is the precise violation moment, sharper than "completion".
- **Option B — `evidence-before-claims`.** Names the core principle verbatim from the
  skill's own overview; shortest and most memorable.
- **Option C — Keep.** The name is already well-known and the description carries the
  trigger.

> **Recommended: A.** Same meaning, convention-compliant, and the violation moment
> ("about to claim done") is exactly when the name needs to surface.

## requesting-code-review — naming

**Current issue:** Minimal — accurate and verb-first. Only nit: the skill is really
about *dispatching a reviewer subagent with crafted context*, not asking a human.

- **Option A — `dispatching-code-reviewers`.** Accurate about the mechanism (subagent
  reviewers) and parallel with dispatching-parallel-agents.
- **Option B — `requesting-review-early`.** Bakes in the core principle ("review early,
  review often") at the cost of vagueness.
- **Option C — Keep.**

> **Recommended: C (keep).** The human-facing phrasing is friendlier and the mechanism
> may evolve (risk-scaled depth, per `SUPERCHARGING-OPTIONS.md`); don't name the
> plumbing.

## receiving-code-review — naming

**Current issue:** Passive-sounding; the skill's content is active triage — verify,
classify, push back. "Receiving" undersells the rigor.

- **Option A — `triaging-review-feedback`.** Active, names the actual process (classify
  each item, act per class) and matches the evidence-gated-triage supercharge direction
  recommended in `SUPERCHARGING-OPTIONS.md`.
- **Option B — `evaluating-review-feedback`.** Softer than triage; emphasizes
  verify-before-implement.
- **Option C — Keep.** Symmetric with requesting-code-review, which has real value:
  the pair reads as two halves of one loop.

> **Recommended: C (keep), unless the evidence-gated triage supercharge lands — then A,
> so the name matches the new mechanic.** The requesting/receiving symmetry is worth
> preserving by default.

## using-git-worktrees — naming

**Current issue:** The strongest mis-name in the tier — the skill explicitly says
*prefer native isolation tools; git worktrees are the fallback*. The name advertises
the fallback mechanism as the headline.

- **Option A — `isolating-workspaces`.** Names the goal (isolation), which is what the
  skill actually guarantees regardless of mechanism. Verb-first, short.
- **Option B — `setting-up-isolated-workspaces`.** Same goal-naming, more explicit
  about being a setup step; longer.
- **Option C — Keep.** "Worktree" is what users and docs say; high search weight.

> **Recommended: A.** Mechanism-naming actively misleads here (the #1 red flag in the
> skill is *using git worktrees* when a native tool exists). Keep "git worktrees" as a
> keyword in the description for search.

## finishing-a-development-branch — naming

**Current issue:** Longest name in the tier (31 chars) and "development branch" is
redundant — every branch you'd finish is one.

- **Option A — `landing-a-branch`.** "Land" is standard engineering vernacular for
  merge/integrate; half the length, verb-first, vivid.
- **Option B — `finishing-a-branch`.** Minimal edit: drop the redundant word, keep the
  established verb.
- **Option C — Keep.** Zero migration cost; the name is clear, just long.

> **Recommended: A.** It names all four exit paths (merge, PR, keep, discard) better
> than "finishing" does, and it's the kind of name agents recognize from real
> engineering culture.

## writing-skills — naming

**Current issue:** Nearly none — short, verb-first, accurate. Only nit: the skill's
thesis (TDD for documentation, test before deploying) is invisible in the name.

- **Option A — `writing-and-testing-skills`.** Surfaces the half of the skill people
  skip — testing — at the cost of length.
- **Option B — `creating-skills`.** The skill's own CSO section cites this as a good
  name; marginally more inclusive of non-writing work (testing, structuring).
- **Option C — Keep.**

> **Recommended: C (keep).** The testing discipline belongs in the description and the
> iron law, not crammed into the name.

## Naming decision tracker

| Skill | Recommended | Chosen | Status |
|---|---|---|---|
| using-superpowers | Keep | — | pending |
| brainstorming | `designing-before-coding` | — | pending |
| writing-plans | Keep | — | pending |
| executing-plans | `executing-plans-inline` | — | pending |
| subagent-driven-development | `executing-plans-with-subagents` | — | pending |
| dispatching-parallel-agents | Keep | — | pending |
| test-driven-development | Keep | — | pending |
| systematic-debugging | `debugging-to-root-cause` | — | pending |
| verification-before-completion | `verifying-before-claiming-done` | — | pending |
| requesting-code-review | Keep | — | pending |
| receiving-code-review | Keep (A if triage supercharge lands) | — | pending |
| using-git-worktrees | `isolating-workspaces` | — | pending |
| finishing-a-development-branch | `landing-a-branch` | — | pending |
| writing-skills | Keep | — | pending |
