# v1 Supercharging Options

A decision menu for supercharging the 14 core obra skills. For each skill: pick **one
option** (or a noted combination), hand it to the `skill-supercharger` agent as a work
order, and the completed work lands in that skill's `## Supercharged vs upstream`
section. The tracker table at the bottom records progress.

Options reference the cross-cutting upgrades (CC1–CC6) below by ID instead of restating
them. Skill *renaming* is a separate decision — see `RENAMING-OPTIONS.md`.

## Complexity bands

Every option is filed under one band so effort is visible before choosing:

- **Simple** — content-only: tables, worked examples, checklists, prose tightening.
  No new mechanics; lowest risk; an afternoon of writing.
- **Medium** — process and interaction changes: structured choices (CC1), tracked
  todos (CC4), evidence formats (CC5), restructuring (CC6), fast-paths (CC7), durable
  artifacts (CC8). Changes how the skill *runs*, but ships no code.
- **Advanced** — shipped code or platform coupling: helper scripts (CC3), hooks,
  harness-native rewrites (CC2 at the platform level). Highest leverage, needs
  maintenance.

Option letters are stable IDs — A–C are carried over from the previous revision of
this doc (the tracker references them), D+ were added next, and the 2026-06-10
expansion appended three Simple + one Medium option per skill after each skill's
last existing letter, and a second 2026-06-10 pass appended one Medium + one Advanced
option per skill (citing the new CC7–CC8) — so letters appear out of alphabetical
order within the bands.

---

## Cross-cutting upgrades (CC1–CC8)

Conventions any skill can adopt. Defined once here; per-skill options cite them.

- **CC1 — Native choice points.** Wherever a skill says "ask the user" or presents a
  numbered menu in prose, use structured multiple-choice (AskUserQuestion-style) with a
  recommended default. Prose menus get misread; structured choices don't.
- **CC2 — Explicit handoff states.** Every skill declares its entry condition ("you have
  an approved spec") and its exit skill ("invoke finishing-a-development-branch").
  Upstream has partial wiring (e.g. executing-plans → finishing); make it total, so the
  14 skills form one connected workflow graph: brainstorming → writing-plans →
  subagent-driven-development / executing-plans → requesting/receiving-code-review →
  verification-before-completion → finishing-a-development-branch, with
  systematic-debugging and TDD as inner loops.
- **CC3 — Executable helpers.** Ship scripts next to SKILL.md so the skill *does* the
  mechanical work instead of describing it. Prose decision trees become `setup-*.sh` /
  `check-*.sh`; the skill text shrinks to judgment calls.
- **CC4 — Checklist enforcement.** Checklists and phase sequences become tracked todos
  (TodoWrite/TaskCreate), one per item, instead of prose the agent can skim past.
- **CC5 — Evidence capture.** Any claim a skill requires ("tests pass", "spec
  compliant", "agents didn't conflict") must embed the literal command + output that
  proves it, in a fixed format other skills can consume.
- **CC6 — Token discipline.** Lean SKILL.md (<200 words for always-loaded skills, <500
  otherwise), with depth moved to reference files loaded on demand. Upstream's own
  writing-skills preaches this; several v1 skills violate it.
- **CC7 — Proportional ceremony.** Any gate, ledger, or todo mechanism must define its
  own trivial-case fast-path: the threshold that qualifies and the reduced procedure
  that still applies. Discipline that scales with stakes gets followed; discipline
  that doesn't gets skipped wholesale. Several existing options' trade-offs ask for
  exactly this — CC7 names the convention once.
- **CC8 — Durable artifacts.** Ledgers, logs, baselines, and evidence blocks are
  written to predictable repo paths (default `docs/superpowers/artifacts/`) instead of
  living only in the conversation, so later sessions and sibling skills can consume
  them. Conversation-only artifacts die with the context window.

---

## brainstorming (164 lines)

**Current state:** Solid checklist + visual companion, but mockup fidelity is one-size
(simple wireframes, "keep mockups simple") and spec depth doesn't respond to how much
visual exploration happened.

### Simple

- **Option C — Auto-matched fidelity.** Skill infers fidelity from the question type
  (layout question → wireframe, look-and-feel question → hi-fi). *Trade-off:* zero
  friction but can guess wrong and burn tokens, and has no explicit fidelity↔spec-depth
  link.
- **Option D — Spec exemplar gallery.** Add a short good-vs-bad gallery: one
  underspecified spec excerpt and its repaired version per common failure mode (missing
  edge cases, UI described in adjectives, no out-of-scope section). *Trade-off:*
  lengthens the file; cap at three pairs or move to a reference file (CC6).
- **Option G — Clarifying-question bank.** A categorized bank of the highest-yield
  questions (purpose, constraints, success criteria, out-of-scope) with the single
  strongest opener per category, so the one-question-at-a-time loop starts strong
  instead of generic. *Trade-off:* canned questions can read as boilerplate; treat as a
  menu, not a script.
- **Option H — YAGNI strike pass.** Before presenting any design section, run one
  explicit "what can be removed" pass and name what was cut — makes "YAGNI ruthlessly"
  a step instead of a vibe. *Trade-off:* a cut the user wanted resurfaces as a revision
  round.
- **Option I — Decision-log convention.** One line per accepted *or rejected*
  alternative (choice, alternatives considered, why) appended to the spec, so "why
  didn't we do X?" is answerable months later. *Trade-off:* discipline-dependent;
  nothing enforces an entry.

### Medium

- **Option A — Fidelity contract** *(uses CC1)*. At companion-accept time, ask one
  structured question: **wireframe pass** or **visual design pass**. The answer sets
  mockup fidelity for the whole session *and* selects the spec template: wireframe pass
  → fast structural mockups and a lean spec (flows + layout only); visual design pass →
  high-fidelity mockups throughout (real palette, type, spacing, component states) and a
  spec with a full visual-design chapter the implementation can build from directly.
  *Trade-off:* one extra up-front question; all-or-nothing per session.
  *Extension:* add Option B's per-screen "level up" action as an escape hatch so a
  wireframe session can still promote individual screens.
- **Option B — Fidelity ladder.** Every mockup starts as a wireframe; each screen offers
  a clickable "show me this in high fidelity" action, and only leveled-up screens get
  deep spec sections. *Trade-off:* cheap by default but adds a round-trip per screen,
  and the user has to know to ask.
- **Option J — Question-coverage todos** *(uses CC4)*. The four understanding areas
  (purpose, constraints, success criteria, out-of-scope) become tracked todos; the
  design cannot be presented while one is open. *Trade-off:* ceremony on tiny features;
  needs a fast-path for trivial scopes.
- **Option K — Assumption register** *(uses CC8)*. Whenever the user answers "whatever
  you think" or a question is skipped for scope reasons, record the assumption made on
  their behalf in a register that travels into the spec as its own section — so a
  post-ship surprise traces to a named assumption, not a silent one. *Trade-off:*
  register bloat with highly-deferential users; cap entries to assumptions that change
  the design.

### Advanced

- **Option E — Mockup scaffolder** *(uses CC3)*. `scaffold-mockup.sh` generates the
  visual companion's HTML shell (navigation, screen list, level-up control) from a
  screen manifest, so each iteration edits only screen content instead of rebuilding
  the page. *Trade-off:* ties mockups to one companion layout; manifest is one more
  artifact to keep current.
- **Option F — Spec compiler** *(uses CC3, CC5)*. A script assembles the final spec
  from the session's artifacts — accepted mockup files, the decision log, the fidelity
  choice — into the selected template, so the spec cannot silently omit a screen that
  was mocked and approved. *Trade-off:* requires the session to keep artifacts in
  predictable paths; compiler output still needs a human read-through.
- **Option L — Prior-art scan** *(uses CC3)*. A script that greps the repo, the specs
  directory, and recent commits for features touching the same nouns before questioning
  starts, and surfaces what already exists — so brainstorming refines or extends prior
  work instead of unknowingly redesigning it. *Trade-off:* keyword matching misses
  renamed concepts; treat hits as prompts, not verdicts.

> **Recommended: A (with the B escape hatch).** Chosen by Donal during the 2026-06-10
> brainstorm — strongest coupling between mockup fidelity and spec depth, which was the
> stated goal, with predictable token cost.

## dispatching-parallel-agents (182 lines)

**Current state:** Good pattern (one agent per independent domain) but written against a
generic `Task("...")` API; conflict detection is "review and hope"; agent output format
is freeform.

### Simple

- **Option D — Dependency-smell table.** A table of independence-killers — shared
  file, shared fixture/database, ordering assumption, output-of-one-feeds-the-other —
  each with the call to make (merge domains vs serialize vs proceed). Turns "are they
  independent?" from a vibe into a checklist. *Trade-off:* judgment aid only; catches
  nothing mechanically.
- **Option E — Worked dispatch examples.** Two or three full transcripts (domain split,
  per-agent prompts, merged result), including one negative example where overlap
  forced a merge. *Trade-off:* lengthens the skill; reference-file material (CC6).
- **Option G — Dispatch prompt card.** The minimal seven-field prompt template every
  dispatch must fill: goal, context, file boundary, verification command, output
  format, explicit non-goals, return protocol. *Trade-off:* template discipline only;
  nothing checks the fields are honest.
- **Option H — Fan-out sizing table.** Rows mapping task shape to agent count
  (N independent domains → N agents, cap 4; serial chain → 1; one big domain → 1 plus
  an optional research sidekick), including the "one agent would be faster" row.
  *Trade-off:* numbers are defaults, not laws; judgment still rules the margins.
- **Option I — Read/write split.** Tag each dispatched agent read-only (research,
  audit) or write (implementation); only write agents need isolation and collision
  checks, halving the pre-flight cost of mixed fan-outs. *Trade-off:* a "read-only"
  agent that quietly writes breaks the assumption; state that the tag is a contract.

### Medium

- **Option C — Structured result contract** *(uses CC5)*. Every dispatched agent must
  return a fixed schema: root cause, files changed, verification command + literal
  output. The controller's integration step becomes mechanical diff-and-merge instead of
  reading freeform summaries. *Trade-off:* schema discipline adds prompt weight per
  dispatch.
- **Option F — Dispatch ledger** *(uses CC4)*. One tracked todo per dispatched agent
  with status (dispatched / returned / integrated / verified), so a forgotten agent
  result is structurally impossible. *Trade-off:* bookkeeping overhead on two-agent
  cases.
- **Option J — Timeout-and-retry policy** *(uses CC5)*. Every dispatch carries a
  time/token budget and the one-retry rule: a failed or overrun agent gets exactly one
  re-dispatch with tightened scope and the failure evidence attached; a second failure
  escalates to the human. *Trade-off:* budgets guessed wrong kill healthy agents; start
  generous.
- **Option K — Merge-order protocol** *(uses CC5)*. Returned write-agents integrate one
  at a time in dependency order, re-running the verification command after each merge —
  so a conflict implicates exactly one agent instead of the whole batch. *Trade-off:*
  serial integration gives back some of the time parallel execution won.

### Advanced

- **Option A — Harness-native dispatch** *(uses CC2)*. Rewrite around real Claude Code
  semantics: multiple Agent calls in a single message for true concurrency,
  `isolation: "worktree"` per agent so they physically cannot conflict,
  `run_in_background` for long investigations, and SendMessage to continue an agent
  instead of re-dispatching cold. *Trade-off:* more platform-specific; needs a fallback
  paragraph for other harnesses.
- **Option B — Independence pre-flight** *(uses CC3)*. Ship a script that maps each
  failing test/domain to the source files it touches and flags overlap *before*
  dispatch; overlapping domains get merged into one agent. Removes the biggest failure
  mode (two agents editing the same file) mechanically. *Trade-off:* heuristic file
  mapping won't catch semantic coupling.
- **Option L — Dispatch archive** *(uses CC8)*. Persist each dispatch's prompt and
  returned result to a durable artifacts path, so failed fan-outs can be forensically
  reviewed and effective prompt patterns reused instead of re-derived per session.
  *Trade-off:* archives grow unbounded; needs a retention rule.

> **Recommended: A.** The skill's value is parallelism, and worktree isolation makes the
> "agents interfere" caveat largely obsolete — that's a step-change, not a polish.

## executing-plans (70 lines)

**Current state:** Thinnest skill in the tier. "Follow each step exactly" plus a short
stop-conditions list; checkpoints mentioned in the description but never defined in the
body.

### Simple

- **Option B — Blocker taxonomy.** Expand "stop and ask" into a table of blocker types
  (missing dependency, failing verification, ambiguous instruction, plan gap, wrong
  baseline) with a specific recovery action and escalation format for each.
  *Trade-off:* content-only; doesn't change the skill's mechanics.
- **Option D — Deviation log.** A convention for recording any departure from the plan
  (what changed, why, who approved) inline in the plan file itself, so the plan stays
  the single source of truth instead of drifting from reality. *Trade-off:* relies on
  discipline; nothing enforces the log entry.
- **Option G — Pre-flight checklist.** Before task 1: working tree clean, baseline
  tests green, correct branch/worktree, plan version current. Four checks that prevent
  the classic "executed a perfect plan on the wrong baseline". *Trade-off:* content
  only.
- **Option H — Completion stamps.** Each checked checkbox gains a one-line stamp:
  timestamp + verification command + result, so "when did this task actually pass?"
  has an answer. *Trade-off:* plan files get noisier; stamps are append-only clutter
  by design.
- **Option I — Staleness tripwire.** Signals that the plan no longer matches reality
  (file moved, API changed, dependency vanished) with the rule: return to
  writing-plans for an amendment, never improvise mid-execution. *Trade-off:*
  round-trips on small drift; the alternative is silent plan divergence.

### Medium

- **Option A — Checkpoint protocol** *(uses CC4, CC5)*. Define what a checkpoint
  actually is: execute N tasks as a tracked-todo batch, then stop and report with
  per-task evidence (command + output) before continuing. Gives the human real review
  points instead of a vague promise. *Trade-off:* slower than continuous execution; that
  is the point of this skill vs subagent-driven.
- **Option C — Degraded-mode twin** *(uses CC2)*. Reframe the skill explicitly as the
  no-subagent fallback of subagent-driven-development: same two-stage review (self-run
  spec pass, then quality pass), same status vocabulary (DONE / BLOCKED /
  NEEDS_CONTEXT), so plans execute identically regardless of platform. *Trade-off:*
  self-review is weaker than fresh-context review; must say so honestly.
- **Option J — Structured blocker escalation** *(uses CC1)*. Hitting a blocker raises
  one structured question (retry with fix / skip task and continue / abort batch) with
  a recommended default and the blocker evidence attached. *Trade-off:* interaction
  cost per blocker; prevents the silent-skip failure mode.
- **Option K — Trivial-batch fast-path** *(uses CC7)*. Tasks the plan marks trivial
  (single file, no new behavior) execute as one batch with a single combined checkpoint
  instead of per-task ceremony — the fast-path the checkpoint protocol (A) needs to
  stay tolerable on long plans. *Trade-off:* a misclassified "trivial" task skips
  review exactly where it needed it; classification errors land on writing-plans.

### Advanced

- **Option E — Plan-runner script** *(uses CC3)*. A script parses the plan's
  checkboxes, marks tasks complete, and emits the checkpoint report (tasks done,
  evidence per task) mechanically. *Trade-off:* requires plans to follow
  writing-plans' format strictly; brittle against hand-written plans.
- **Option F — Resume bootstrap** *(uses CC3)*. A script that reconstructs execution
  state in a fresh session: read the checkboxes, diff claimed progress against git
  history, and re-verify the last checkpoint's evidence before continuing.
  *Trade-off:* only pays off on multi-session plans; needs the plan file to be the
  source of truth (pairs with D).
- **Option L — Checkpoint reviewer dispatch** *(uses CC2)*. When subagents are
  available but the plan is being run in-session, each checkpoint dispatches a
  read-only reviewer agent to audit the batch's evidence against the plan — splitting
  the difference between this skill and subagent-driven-development. *Trade-off:*
  reviewer cost per checkpoint; blurs the boundary between the two execution skills
  (C must define it).

> **Recommended: C.** It fixes the real architectural gap — upstream's two execution
> skills drift apart — and pulls A's checkpoint evidence in as part of the shared
> protocol.

## finishing-a-development-branch (251 lines)

**Current state:** Careful decision tree (detect environment → 4-option menu → execute →
provenance-checked cleanup) written entirely as prose + shell the agent re-derives every
time.

### Simple

- **Option D — Pre-finish evidence checklist.** A table of the claims the skill
  currently assumes ("tests pass", "rebased on main", "no stray debug files") each with
  the command that proves it and the output shape to expect — CC5 in spirit, prose in
  form. *Trade-off:* still self-enforced.
- **Option E — Symptom→recovery table.** Expand Common Mistakes into symptom / cause /
  recovery rows ("can't remove worktree" → CWD inside it → cd out and retry; "branch
  delete refused" → unmerged commits → verify merge landed first). *Trade-off:* content
  depth only.
- **Option G — Exit-path cheat card.** One-screen table of the four exits (merge local /
  push+PR / keep / discard) with the signals for picking each, so the choice takes
  seconds instead of re-reading the tree. *Trade-off:* duplicates the decision tree;
  two artifacts to keep in sync.
- **Option H — Leftovers sweep.** Checklist of branch droppings to remove before
  finishing: debug prints, `.only`/`.skip` tests, scratch files, commented-out code,
  TODOs introduced by this branch. *Trade-off:* overlaps project linters where they
  exist.
- **Option I — Commit-story audit.** Quick pass over the branch's commits (do they
  build a reviewable story? squash fixups?) before the exit menu — PR reviewers read
  commits, not worktrees. *Trade-off:* history rewriting has sharp edges; needs an
  "already pushed, don't rebase" guard.

### Medium

- **Option B — Structured menu + typed-confirm** *(uses CC1)*. The 4-option menu becomes
  a structured choice with descriptions and a recommended default; discard keeps its
  typed-"discard" confirmation. *Trade-off:* improves the interaction, leaves the
  error-prone mechanics as prose.
- **Option C — Evidence-rich PRs** *(uses CC5)*. Option 2 (push + PR) auto-builds the PR
  body from the plan/spec summary plus captured verification output, instead of a
  skeleton template. *Trade-off:* only improves one of the four exit paths.
- **Option J — Finish receipt** *(uses CC5)*. Whatever exit is chosen, emit one
  evidence block: merge SHA or PR URL, branch/worktree cleanup confirmation, final
  test run on the result — the artifact verification-before-completion consumes.
  *Trade-off:* small bulk per finish; mostly valuable when things later need
  forensics.
- **Option K — Stacked-branch guard.** Before merge or discard, check whether other
  branches build on this one (`git branch --contains`); a dependent branch turns
  discard into a structured warning and merge into a rebase-the-children reminder.
  *Trade-off:* a rare-situation tax on every finish — but it's one cheap command.

### Advanced

- **Option A — Scriptify the mechanics** *(uses CC3)*. Ship `finish-branch.sh
  detect|merge|cleanup` implementing environment detection, CWD-safe worktree removal,
  and provenance checks. SKILL.md shrinks to: verify tests, present menu, run script,
  handle judgment calls. Kills the top three "Common Mistakes" (CWD inside worktree,
  branch-before-worktree deletion, harness-owned cleanup) by construction.
  *Trade-off:* script needs maintenance across git versions/platforms.
- **Option F — CI-aware finish.** On the push/PR path, poll `gh pr checks` until green
  or failed and report the result before declaring the branch finished; a red check
  routes back into systematic-debugging instead of ending the session on an unverified
  push. *Trade-off:* adds wall-clock wait; needs a timeout policy and a no-CI fallback.
- **Option L — Changelog deriver** *(uses CC3)*. A script that drafts the
  changelog/release-note entry from the branch's commits and spec summary at finish
  time, while the context is still loaded — instead of reconstructing it at release
  time. *Trade-off:* draft quality tracks commit-message quality (pairs with I's
  commit-story audit).

> **Recommended: A.** This skill is 80% mechanical; mechanics belong in a script. B can
> ride along almost for free.

## receiving-code-review (213 lines)

**Current state:** Strong anti-performative stance and source-specific handling, but
"VERIFY: check against codebase reality" is an instruction without a procedure.

### Simple

- **Option C — Reviewer-context probe.** Deepen the external-reviewer checklist into a
  structured probe (does reviewer know the platform constraints? the YAGNI status? prior
  decisions?) with worked examples per probe. *Trade-off:* content depth only.
- **Option D — Push-back phrasebook.** Worked examples contrasting performative
  agreement ("Great catch!") with evidence-backed responses for each stance — agree
  (with the verifying artifact), disagree (with the contradicting output), need
  clarification (with the specific question). *Trade-off:* examples drift if the triage
  format later changes.
- **Option H — Tone-stripping rule.** Separate each item's claim from its framing
  before triage — blunt phrasing doesn't raise priority, polite phrasing doesn't lower
  it; two worked examples (harsh-but-wrong, gentle-but-critical). *Trade-off:* content
  only.
- **Option I — Batch response convention.** Respond to the whole review once, with the
  per-item statuses, instead of piecemeal replies as items get fixed — reviewers get
  one coherent reply and items can't slip between messages. *Trade-off:* slower first
  response; worth telling the reviewer that's deliberate.
- **Option J — Fast-check list.** The claim types checkable in under a minute (does
  this function exist? is this dead code? does a test cover X?) with the command
  pattern for each — run the check *before* drafting any response. *Trade-off:* the
  list invites overconfidence on claims that merely look fast-checkable.

### Medium

- **Option A — Evidence-gated triage** *(uses CC5)*. For each feedback item, require a
  classification — implement / clarify / push back — and each classification demands an
  artifact: implement needs the verifying test, clarify needs the specific question,
  push back needs the grep/test output that contradicts the reviewer. No item moves
  without its artifact. *Trade-off:* heavier for trivial typo-level feedback; needs a
  fast-path.
- **Option B — Feedback ledger** *(uses CC4)*. Multi-item feedback becomes one tracked
  todo per item with status (pending / clarifying / fixed+tested / pushed-back), fixing
  the "implemented 4 of 6, lost 2" failure mode. *Trade-off:* bookkeeping overhead on
  small reviews.
- **Option E — Severity triage.** Classify each item blocker / should-fix / nit before
  acting, and work in that order — so a session can't stall polishing nits while a
  blocker waits. *Trade-off:* adds a classification pass before any fix lands.
- **Option K — Triage confirmation gate** *(uses CC1)*. Present the completed triage
  table (item → classification → artifact) as one structured confirmation before
  implementing anything, so a misclassified item gets re-routed while it's still
  cheap. *Trade-off:* one extra round-trip per review.
- **Option L — Recurring-feedback memory** *(uses CC8)*. Append each review's findings,
  tagged by category, to a durable log; the third occurrence of the same category
  triggers a proposal to fix the source (CLAUDE.md rule, lint config, skill edit)
  instead of hand-fixing instance four. *Trade-off:* categorization is judgment;
  miscategorized entries hide the pattern they should reveal.

### Advanced

- **Option F — Feedback intake parser** *(uses CC3)*. A script pulls PR review comments
  (`gh api`) and emits the ledger directly — one item per comment with file/line and
  status `pending` — removing manual transcription as an error source. *Trade-off:*
  GitHub-specific; needs a paste-the-review fallback for other sources.
- **Option G — Response bundle** *(uses CC3, CC5)*. A script collects each item's
  resolution artifact (test run, grep output, commit SHA) into a structured reply
  document and posts it back to the PR thread, closing the loop with the reviewer in
  the same evidence format the triage produced. *Trade-off:* only valuable once A or B
  exists to produce the artifacts.
- **Option M — Claim-check runner** *(uses CC3)*. Script the fast-check list (J):
  existence greps, dead-code checks, test-coverage queries per claim type, emitting
  the evidence artifacts that evidence-gated triage (A) demands — verifying a claim
  becomes one command per item. *Trade-off:* only as good as its claim-type patterns;
  novel claims still need manual checks.

> **Recommended: A.** It converts the skill's core principle ("verify before
> implementing") from exhortation into a gate, which is exactly how upstream's own
> verification skill works.

## requesting-code-review (103 lines)

**Current state:** Dispatch a generic subagent with a template; one review depth for
every change; reviewer context assembled by hand.

### Simple

- **Option D — Template tightening.** Require three fields in every review request:
  intent (what the reviewer should optimize for), known-risk areas, and explicit
  out-of-scope — so reviewers don't burn their depth budget on the wrong thing.
  *Trade-off:* content only; depends on the requester filling it honestly.
- **Option E — Self-review pre-pass.** A short checklist run before dispatching any
  reviewer: stray debug prints, leftover TODOs, accidental files, formatting — so
  reviewer attention goes to substance. *Trade-off:* partially duplicates linters where
  projects have them.
- **Option G — Diff hygiene pass.** Split unrelated changes out of the diff (separate
  commit or branch) before requesting review; mixed diffs get worse reviews of both
  halves. *Trade-off:* content only; some changes resist clean splitting.
- **Option H — Reviewer brief card.** A fixed one-paragraph brief ahead of the diff:
  what changed, why, how it was verified, where to look hardest. *Trade-off:* overlaps
  D's template fields; pick one as the canonical shape.
- **Option I — Readiness gate.** Don't request review with failing tests, unresolved
  TODOs, or un-run verification — making "review my WIP" an explicit labeled request
  instead of an accident. *Trade-off:* discourages legitimate early-feedback asks
  unless a WIP-labeled path is kept.

### Medium

- **Option A — Risk-scaled review depth.** Classify the change (diff size, files
  touched, blast radius) and scale the response: small/low-risk → single quick reviewer;
  large/risky → parallel spec-compliance + code-quality + silent-failure reviewers.
  *Trade-off:* classification heuristics need tuning to avoid over-reviewing.
- **Option F — Re-review delta protocol.** Follow-up reviews receive only the delta
  diff plus the prior findings with their statuses, not the whole change again —
  cheaper rounds and no re-litigating settled items. *Trade-off:* the reviewer loses
  whole-change context; needs a "request full review" escape hatch.
- **Option J — Block-or-continue choice** *(uses CC1)*. When review is requested, one
  structured choice: block until findings return, or continue on non-dependent work
  meanwhile (independence judged per dispatching-parallel-agents). *Trade-off:*
  continuing risks rework if the review lands blockers in shared code.
- **Option K — Findings archive** *(uses CC8)*. Persist each review's findings and
  their final statuses to a durable path keyed by branch — the prior-findings input
  the re-review delta protocol (F) needs, available mechanically instead of from
  memory. *Trade-off:* worthless until F (or A) exists to consume it.

### Advanced

- **Option B — Specialized reviewer routing** *(uses CC2)*. Replace the one
  general-purpose template with routing to purpose-built reviewer agents (spec reviewer,
  quality reviewer, test-coverage reviewer) sharing subagent-driven-development's
  templates, so ad-hoc review and plan-execution review behave identically.
  *Trade-off:* assumes those agent definitions exist on the platform; needs fallback.
- **Option C — Evidence-bundled requests** *(uses CC3, CC5)*. A helper script assembles
  the reviewer's context mechanically: SHAs, diff stat, test output, the relevant plan
  section. Reviewer quality is mostly context quality. *Trade-off:* script can
  over-include; needs a size cap.
- **Option L — Coverage-hint generator** *(uses CC3)*. A script that computes which
  changed lines lack test coverage and prepends the result to the review request as
  look-here hints, pointing reviewer depth at the genuinely unverified code.
  *Trade-off:* needs a working coverage setup per project; absent one, it must degrade
  silently to no hints.

> **Recommended: A**, with C's bundler as its mechanism — depth scaling is the visible
> win, and it needs the bundled evidence anyway.

## subagent-driven-development (279 lines)

**Current state:** The tier's flagship orchestrator — fresh implementer per task,
two-stage review, model selection, status protocol. Strictly serial: "never dispatch
multiple implementation subagents in parallel."

### Simple

- **Option D — Prompt gallery.** Good-vs-bad implementer and reviewer prompt examples
  showing context scoping: what the implementer was given vs what it actually needed,
  and how over-scoping leaks decisions the subagent should make itself. *Trade-off:*
  reference-file material (CC6); examples age as templates evolve.
- **Option E — Failure-mode table.** The orchestrator failures upstream leaves implicit
  — implementer ignored the spec, reviewer rubber-stamped, task reported DONE but
  half-finished — each with its detection signal and recovery move. *Trade-off:*
  content only.
- **Option G — Task brief template.** The fixed fields every implementer dispatch
  fills: task text, spec excerpt, files in scope, verification command, status
  vocabulary — the orchestrator stops composing prompts from scratch per task.
  *Trade-off:* template discipline only.
- **Option H — Review rubric cards.** Fixed checklists for the spec-review and
  quality-review stages (spec: every requirement traced; quality: tests meaningful, no
  silent failures, no scope creep) so reviewer subagents can't rubber-stamp with
  "LGTM". *Trade-off:* rubrics drift from project norms unless revisited.
- **Option I — Status vocabulary card.** Precise definitions of DONE / BLOCKED /
  NEEDS_CONTEXT and the evidence each demands (DONE → verification output; BLOCKED →
  the blocking artifact; NEEDS_CONTEXT → the specific missing fact). *Trade-off:*
  content only; enforcement still sits with the orchestrator.

### Medium

- **Option B — Deterministic model routing.** Turn the model-selection prose into a
  decision table evaluated per task (files touched, spec completeness, judgment
  required → haiku/sonnet/opus) recorded in the plan, so cost optimization is applied
  consistently rather than vibes-based. *Trade-off:* misrouting cheap models onto
  deceptively hard tasks costs a re-dispatch.
- **Option F — Stage-gated todos** *(uses CC4)*. Per task, the implementation,
  spec-review, and quality-review stages become tracked todos that cannot be silently
  skipped; the orchestrator's progress is externally visible mid-plan. *Trade-off:*
  todo volume on large plans.
- **Option J — Return-contract rejection** *(uses CC5)*. The orchestrator mechanically
  rejects implementer returns that lack the contract fields (files touched,
  verification command + output) and re-requests the missing fields rather than
  accepting prose. *Trade-off:* an extra round-trip when implementers under-report
  despite honest work.
- **Option K — Trivial-task fast-path** *(uses CC7)*. Tasks below a stated threshold
  (single file, no new public surface) skip the two-stage review and accumulate into
  one combined review at the end of their wave — proportional ceremony for the plan's
  long tail. *Trade-off:* the threshold is gameable; the combined review must be able
  to bounce a task back to the full process.

### Advanced

- **Option A — Parallel waves** *(uses CC2)*. Build the task dependency graph from the
  plan, then dispatch each wave of independent tasks concurrently — with worktree
  isolation per implementer where tasks share files. The serial rule becomes a special
  case, not a law. *Trade-off:* merge complexity between waves; review load spikes.
- **Option C — Persistent implementer via SendMessage.** For tightly-related task
  clusters, continue one implementer with its context intact instead of paying
  cold-start per task; keep fresh-per-task for unrelated tasks. *Trade-off:* trades away
  the "no context pollution" guarantee; needs a clear cluster heuristic.
- **Option L — Orchestration journal** *(uses CC8)*. Persist per-task dispatch records
  (prompt, model, status, review outcomes) to a durable path as the plan executes, so
  an interrupted orchestration resumes from the journal and a failed plan can be
  post-mortemed from its records. *Trade-off:* journal upkeep is orchestrator overhead
  on every task.

> **Recommended: A.** It's the biggest throughput unlock and composes with
> dispatching-parallel-agents Option A (same isolation machinery).

## systematic-debugging (296 lines)

**Current state:** Excellent four-phase discipline with rationalization tables; phases
are prose the agent can blur together, and hypotheses/evidence live only in the
conversation.

### Simple

- **Option D — Bug-class playbooks.** Short playbooks for recurring classes — flaky
  test, environment-only failure, regression-after-merge, heisenbug — each mapping to
  its Phase 1 evidence-gathering moves. *Trade-off:* more content in an already long
  skill; reference-file candidates (CC6).
- **Option E — Rationalization table refresh.** Add the newer rationalizations observed
  in agent debugging ("the fix is obvious from the diff", "I'll add the test after
  confirming the fix works", "it's probably the same root cause as last time") with
  rebuttals. *Trade-off:* table growth; needs pruning of stale rows in exchange.
- **Option G — First-15-minutes card.** The exact Phase 1 opening sequence: reproduce
  it, capture the literal error text, diff recent changes, shrink to the smallest
  failing case. Four moves, in order, before any theory. *Trade-off:* content only.
- **Option H — Can't-reproduce playbook.** The decision path when reproduction fails —
  capture environment deltas, add observability at the suspected boundary, downgrade
  to monitoring with a tripwire — instead of "couldn't repro, closing". *Trade-off:*
  lengthens the skill; reference-file candidate (CC6).
- **Option I — Fix-scope guard.** Rule: the fix diff must be fully explained by the
  confirmed hypothesis; any extra "while I'm here" change is a separate commit/task,
  keeping Phase 4 falsifiable. *Trade-off:* slower when the neighboring code really is
  broken; that's a feature.

### Medium

- **Option A — Debugging ledger** *(uses CC5)*. Each phase writes to a structured ledger
  (symptom → evidence gathered → hypotheses with predicted observations → test result →
  fix + verification). The ledger is the gate artifact: no Phase 4 without a confirmed
  hypothesis entry. Also gives "question the architecture after 3 fixes" a real counter
  to read. *Trade-off:* ceremony on genuinely trivial bugs; needs a 2-minute fast-path.
- **Option C — Phase gates as todos** *(uses CC4)*. Four phases become four tracked
  todos with explicit entry/exit criteria; red-flag thoughts trigger a forced return to
  the Phase 1 todo. *Trade-off:* lighter than A but the evidence itself stays
  unstructured.
- **Option J — Competing-hypotheses minimum.** Require at least two recorded hypotheses
  with distinct predicted observations before testing any — anchoring on hypothesis #1
  is this skill's most common silent failure. *Trade-off:* forced second hypotheses can
  be strawmen; the ledger (A) makes that visible.
- **Option K — Root-cause history** *(uses CC8)*. Confirmed root causes append one line
  (symptom signature → root cause → fix commit) to a durable debug-history file, and
  Phase 1 starts by grepping it — "have we seen this before?" gets a real answer
  instead of a hunch. *Trade-off:* low hit-rate while the file is young; value
  compounds with project age.

### Advanced

- **Option B — Instrumentation kit** *(uses CC3)*. Ship boundary-logging snippets and a
  bisect-helper script implementing Phase 1's multi-component evidence gathering, so
  "add diagnostic instrumentation at each layer" is paste-ready instead of improvised.
  *Trade-off:* snippets are stack-specific; pick 2–3 common stacks.
- **Option F — Ledger tooling** *(uses CC3)*. `debug-ledger.sh init|add|gate` creates
  the ledger file, appends entries, and refuses the Phase-4 gate unless a hypothesis
  entry carries a confirming test result — Option A's format with enforcement attached.
  *Trade-off:* pure ceremony unless A is adopted first; F is A's enforcement layer.
- **Option L — Repro scaffolder** *(uses CC3)*. A script that scaffolds a minimal
  reproduction test from the failing case (failing input, expected vs actual,
  environment pins) — Phase 1's "shrink to the smallest failing case" becomes an
  artifact, which then becomes the regression test after the fix. *Trade-off:*
  scaffolds are stack-specific; build for the project's primary test harness.

> **Recommended: A.** The ledger makes the Iron Law auditable, and its fix count is
> exactly what the architecture-escalation rule needs.

## test-driven-development (371 lines)

**Current state:** The tier's strongest discipline skill — iron law, rationalization
table, red flags. Big (371 lines), generic across stacks, and enforcement is purely
self-discipline.

### Simple

- **Option D — Violation gallery.** Realistic diffs of test-after work dressed up as
  TDD, annotated with what gave each one away (test asserts the implementation's
  current output; test never could have failed; commit order). *Trade-off:* content
  only; gallery needs to stay short to respect CC6.
- **Option E — Edge-case FAQ.** A table answering the recurring "does TDD apply here?"
  cases — spikes, legacy code with no harness, UI tweaks, generated code — with rulings
  consistent with upstream's iron law. *Trade-off:* loosely worded rulings become
  loopholes; each row needs the same rigor as the rationalization table.
- **Option G — First-test chooser.** A small table for picking the opening failing
  test per change type: new feature → simplest happy path; bugfix → the reproducing
  case; refactor → pin current behavior first. *Trade-off:* content only.
- **Option H — Test-name convention.** Names state behavior, not implementation
  (`rejects_expired_token`, not `test_validate_2`), with three good/bad pairs — names
  are the spec the next reader gets. *Trade-off:* conventions vary by stack; keep the
  examples per-stack light.
- **Option I — Minimal-implementation ladder.** Fake it → obvious implementation →
  triangulate, with the rule for when each rung is allowed and when to climb. Stops
  both gold-plating and permanent fakes. *Trade-off:* ladder discipline is invisible in
  the final diff; it lives in commit granularity.

### Medium

- **Option A — Red-green evidence trail** *(uses CC5)*. Require the RED and GREEN runs
  to be captured (command + failing output, then command + passing output) per behavior,
  composing directly with verification-before-completion's regression-test pattern.
  "Watched it fail" becomes checkable, not claimed. *Trade-off:* output capture adds
  bulk to long sessions.
- **Option B — Stack quick-starts** *(uses CC6)*. Slim the core to the iron law + cycle,
  and move per-stack mechanics (pytest/jest/vitest/go test invocation, watch-mode,
  failure-reading) to on-demand reference files. *Trade-off:* restructuring, not new
  capability — but it pays the always-loaded token tax down.
- **Option J — Cycle todos** *(uses CC4)*. RED, GREEN, REFACTOR become tracked todos
  per behavior; a GREEN todo cannot complete without the RED one before it — lighter
  than evidence capture (A), mechanical where the iron law is willpower. *Trade-off:*
  todo churn on many-small-behavior sessions.
- **Option K — Micro-change fast-path** *(uses CC7)*. Define exactly which changes are
  exempt from the cycle (comments, tool-assisted renames, formatting, config values
  already under test) and the reduced check each still requires — bounding the "too
  small for TDD" loophole instead of pretending it doesn't exist. *Trade-off:* every
  named exemption is a wedge; the list must be closed, not exemplary.

### Advanced

- **Option C — TDD compliance check** *(uses CC3)*. A script that inspects the working
  tree/commit history for production-code changes with no accompanying test change and
  flags them before commit. Coarse but catches the blatant violation. *Trade-off:*
  heuristic; easy to false-positive on refactors.
- **Option F — Hook pairing appendix.** Pair the skill with a PreToolUse hook that
  warns when production files are edited with no test file touched in the session —
  enforcement moves from willpower to the harness. Keep the v1 change to a "pair with a
  hook" appendix (hook config itself is v4 territory, mirroring
  verification-before-completion Option B). *Trade-off:* per-user configuration;
  heuristic detection.
- **Option L — Red-green archive** *(uses CC8)*. The evidence trail (A) writes to a
  durable per-branch file instead of living only in the conversation, so finishing's
  PR bodies and verification's gate read the same artifact rather than trusting the
  transcript. *Trade-off:* depends on A; adds file churn per behavior.

> **Recommended: A.** Discipline skills get stronger when claims become evidence, and it
> wires TDD tighter into the verification chain (CC2 for free).

## using-git-worktrees (215 lines)

**Current state:** Careful detect → native-tool → git-fallback decision tree, all prose
+ shell re-derived per session; baseline test results are reported then forgotten.

### Simple

- **Option D — Symptom table.** Common failures with one-line fixes: worktree directory
  shows in `git status` → ignore entry missing; "can't remove worktree" → CWD inside
  it; stale registration after manual delete → `git worktree prune`. *Trade-off:*
  content only.
- **Option E — One-page decision table.** Condense the detect→choose walk-through into
  a single-screen table (situation → mechanism → command), keeping the prose as backing
  detail. *Trade-off:* two representations of one tree must be kept in sync.
- **Option G — Naming convention.** Worktree directories named `<repo>-<branch-slug>`
  (or the harness's convention) so `git worktree list` reads as a task list and
  cleanup targets are unambiguous. *Trade-off:* content only.
- **Option H — Inventory habit.** `git worktree list` at session start and finish,
  with triage rules for what a stale entry means (abandoned spike → discard path;
  finished branch → prune). *Trade-off:* habit, not mechanism; pairs with finishing's
  cleanup.
- **Option I — Not-isolated card.** The things worktrees do NOT isolate — global git
  config, installed dependencies, running services/DB state, untracked env files —
  each with its mitigation. The skill's silent assumption, made explicit. *Trade-off:*
  content only.

### Medium

- **Option C — Baseline handshake** *(uses CC2, CC5)*. Record the baseline test result
  (command, counts, output digest) at setup; finishing-a-development-branch compares
  final tests against it, distinguishing "you broke it" from "it was already broken".
  *Trade-off:* small win unless paired with A or B.
- **Option F — Structured consent** *(uses CC1)*. Directory choice and creation consent
  become one structured question with a recommended default, replacing the prose
  back-and-forth before any directory is created. *Trade-off:* interaction polish only;
  mechanics unchanged.
- **Option J — Concurrency budget** *(uses CC4)*. A default cap on simultaneous
  worktrees (3) with one tracked todo per live tree; exceeding the cap forces a
  finish-or-discard decision before creating the next. *Trade-off:* the cap is
  arbitrary; the real constraint is the human's review bandwidth.
- **Option K — Worktree registry** *(uses CC8)*. A durable registry file records each
  worktree's branch, purpose, baseline result, and creation date; the inventory habit
  (H) reads the registry instead of guessing intent from directory names. *Trade-off:*
  drifts if manual `git worktree` commands bypass it; reconcile against
  `git worktree list`.

### Advanced

- **Option A — Scriptify the tree** *(uses CC3)*. `setup-worktree.sh` implements
  detection (worktree vs submodule vs normal), directory priority, ignore verification,
  creation, and project setup; SKILL.md keeps only the consent question and native-tool
  preference. *Trade-off:* the script must mirror the native-tool-first rule, not
  bypass it.
- **Option B — Native-first rewrite.** Restructure around the harness's own isolation
  (EnterWorktree, `isolation: "worktree"` on Agent calls) as the primary path, demoting
  manual git worktrees to a clearly-marked legacy appendix. *Trade-off:* platform
  coupling; other harnesses fall to the appendix.
- **Option L — Dependency drift syncer** *(uses CC3)*. A script that detects
  lockfile/config drift between a worktree and its base branch and re-runs installs as
  needed — mechanizing the biggest row of the not-isolated card (I). *Trade-off:*
  per-ecosystem logic (npm, pip, cargo); start with the project's own stack.

> **Recommended: A + C together.** They're nearly disjoint (mechanics + memory), and C
> gives the finish skill something no amount of prose provides.

## using-superpowers (117 lines)

**Current state:** Loaded into *every* conversation, yet spends its budget on
multi-platform notes and a 12-row red-flags table; routing to the other 13 skills is
implicit.

### Simple

- **Option C — Cheap decision procedure.** Replace the blanket "1% chance = invoke" with
  a two-step check (does the task match a routing-table trigger? if unsure, invoke) that
  costs less deliberation per message. *Trade-off:* any softening of the absolute rule
  risks under-triggering; needs baseline testing per writing-skills.
- **Option D — Announce-convention examples.** Two-line good/bad examples of the
  "Using [skill] to [purpose]" announcement, so the convention is imitable rather than
  abstract. *Trade-off:* spends always-loaded tokens; only worth it alongside the diet
  (A).
- **Option G — Tiebreaker examples.** Three worked cases of the priority rule (process
  skill before implementation skill): bug report + UI task, plan-exists + new idea,
  review feedback + failing tests — each showing the chosen order and why.
  *Trade-off:* spends always-loaded tokens; pairs with the diet (A).
- **Option H — Skill-miss log.** A one-line convention for when a skill should have
  fired but didn't (message, skill, why missed) — the raw corpus the trigger eval
  harness (E) replays. *Trade-off:* self-reported misses undercount; still better than
  no corpus.
- **Option I — Red-flag refresh.** Add the three highest-frequency rationalizations
  observed since upstream shipped ("the user is in a hurry", "I already know this
  skill's content", "this is just a follow-up question") with rebuttals; prune three
  stale rows in exchange. *Trade-off:* table churn; net-zero size by rule.

### Medium

- **Option A — Token diet** *(uses CC6)*. Compress the always-loaded core to <200 words
  (the rule, the priority order, the announce convention); move platform adaptation and
  the red-flags table to reference files. This is the single highest-leverage token fix
  in the tier because it multiplies across every session. *Trade-off:* red-flags lose
  some always-on deterrence; keep the 3 highest-frequency rows inline.
- **Option B — Routing table** *(uses CC2)*. Add an explicit trigger → skill map for all
  13 sibling skills ("user reports bug → systematic-debugging; plan exists →
  subagent-driven-development; about to claim done → verification-before-completion"),
  making the workflow graph discoverable from the entry point. *Trade-off:* table must
  stay in sync as skills evolve.
- **Option J — Declared skill chain.** On first contact with a non-trivial task, name
  the expected skill chain in one line ("brainstorming → writing-plans → SDD") before
  starting — making routing auditable and corrections cheap. *Trade-off:* the
  declaration can be wrong; it's a prediction, not a contract.
- **Option K — Persistent miss corpus** *(uses CC8)*. The skill-miss log (H) writes to
  a durable path and gets a periodic review pass; it doubles as the input corpus the
  trigger eval harness (E) replays. *Trade-off:* inherits H's undercounting; the
  periodic review is one more habit to keep.

### Advanced

- **Option E — Trigger eval harness** *(uses CC3)*. A script replays a corpus of past
  user messages against the routing table and reports trigger hit/miss rates — the
  baseline test writing-skills demands whenever this always-loaded skill changes
  (especially before adopting C). *Trade-off:* corpus curation is real work; metrics
  only as good as the corpus.
- **Option F — Generated routing.** Build the routing table mechanically at session
  start (hook or script) from installed skills' frontmatter descriptions, so the table
  cannot drift as skills are added or renamed. *Trade-off:* platform-coupled; generated
  triggers are only as good as each skill's description (pressure on CSO quality).
- **Option L — Usage telemetry** *(uses CC3)*. A script tallies which skills actually
  fired across session transcripts, surfacing never-fired skills (description problem
  or dead weight) and over-firers (trigger too broad) — the empirical complement to
  E's synthetic evals. *Trade-off:* transcript formats are platform-specific; mind
  privacy on shared machines.

> **Recommended: A + B.** Diet funds the routing table's token cost; together the entry
> skill gets smaller *and* smarter.

## verification-before-completion (139 lines)

**Current state:** Crisp iron law with a claims-vs-evidence table; everything depends on
the agent voluntarily running the gate function at the moment it's most tempted not to.

### Simple

- **Option C — Claim taxonomy expansion.** Grow the failure table with more claim types
  (docs updated, migration applied, perf improved, agent work verified) and their
  required evidence. *Trade-off:* content depth only.
- **Option D — Claim-phrase inventory.** An explicit list of completion-claim phrasings
  that must trigger the gate ("done", "fixed", "should work now", "tests pass",
  "ready to merge") with the evidence-bearing rewrite each one requires. *Trade-off:*
  phrase lists are never exhaustive; the principle still has to carry novel phrasings.
- **Option G — Honest-partial phrasing.** Approved language for reporting incomplete
  work ("X verified by <evidence>; Y attempted, not verified because <reason>") so
  the alternative to overclaiming isn't silence. *Trade-off:* content only.
- **Option H — Evidence freshness rule.** Evidence expires when any relevant file
  changes after the run; the gate requires the *latest* run, with one worked example
  of a stale-green trap. *Trade-off:* "relevant file" is a judgment call; err toward
  re-running.
- **Option I — Negative-claim checks.** "Didn't break anything else" is a claim too:
  the smoke-suite run, the usage grep, the build of dependents — evidence-table rows
  for the claims everyone skips. *Trade-off:* full negative verification is unbounded;
  scope it to the stated blast radius.

### Medium

- **Option E — Standard evidence block** *(uses CC5)*. Define the fixed format — claim,
  command, exit code, output digest, timestamp — that TDD's red-green trail,
  finishing's PR bodies, and review responses all emit and consume. This skill becomes
  the owner of the tier-wide evidence contract. *Trade-off:* format churn ripples into
  every skill that adopts it; version the format.
- **Option F — Verification todos** *(uses CC4)*. At completion time, one tracked todo
  per claim type made during the session; the completion message cannot be written
  while any verification todo is open. *Trade-off:* depends on the agent honestly
  enumerating its own claims — weaker than a hook, cheaper than one.
- **Option J — Independent double-check.** High-stakes claims (migration applied, data
  deleted, release tagged) require a second check by a *different* method than the one
  that did the work (row count after the migration script, not the script's own exit
  code). *Trade-off:* doubles verification cost; reserve for a named high-stakes list.
- **Option K — Stakes-scaled gate** *(uses CC7)*. Classify claim types low/high stakes
  once: low-stakes claims need the standard evidence block, high-stakes claims (J's
  list) need the independent double-check — making the proportionality rule explicit
  instead of leaving J's scope to mood. *Trade-off:* the classification line invites
  litigation; default unknown claims to high.

### Advanced

- **Option A — Verification manifest** *(uses CC3, CC5)*. A per-project
  `verify.yaml` mapping claim types to commands ("tests pass" → `pytest -q`, "build
  succeeds" → `npm run build`); a runner script executes all relevant entries and emits
  a timestamped evidence block to paste into the completion claim. One command replaces
  N remembered ones. *Trade-off:* manifest setup per project; stale manifests verify
  the wrong thing.
- **Option B — Hook-enforced gate.** A Stop/PreToolUse hook that detects completion-claim
  language or commit attempts without fresh verification output in the transcript and
  blocks with a reminder. Moves enforcement from willpower to the harness.
  *Trade-off:* claim-detection heuristics are fragile; hook config is per-user
  (overlaps v4 territory — keep the v1 change to a "pair with a hook" appendix).
- **Option L — Evidence ledger file** *(uses CC8)*. Evidence blocks append to a durable
  per-branch ledger as they're produced; finishing's receipt and PR bodies cite ledger
  entries instead of re-running commands or trusting the transcript. *Trade-off:* a
  stale ledger misleads worse than no ledger — pair with H's freshness rule.

> **Recommended: A.** It makes the iron law *cheaper to obey than to skip*, which is the
> only reliable way to beat end-of-task fatigue.

## writing-plans (152 lines)

**Current state:** Strong format (bite-sized steps, no placeholders, self-review
checklist) — but the self-review is manual and plan quality is unenforced at the
boundary where subagents consume it.

### Simple

- **Option C — Spec-coverage matrix** *(uses CC5)*. Require a closing table mapping each
  spec requirement to the task(s) implementing it; unmapped requirements are plan
  failures. *Trade-off:* manual to build unless specs are structured too.
- **Option D — Anti-pattern gallery.** Worked rewrites of vague steps into executable
  ones ("add appropriate error handling" → the exact try/except block with file path
  and line anchor), three pairs covering the most common placeholder shapes.
  *Trade-off:* content only; overlaps what the linter (A) would catch mechanically.
- **Option G — Task-size sniff test.** Signals a task is too big — more than ~5 steps,
  more than ~3 files, an "and" in the title — with the split move for each.
  *Trade-off:* content only.
- **Option H — Per-task file lists.** Every task declares Create/Modify/Test paths up
  front (upstream's format shows this; make it mandatory) — also the load-bearing
  input for v2 `parallel-plan-executor`'s independence test. *Trade-off:* file lists
  guessed early can drift; amend the plan, don't ignore them.
- **Option I — Rollback notes.** Each risky task (migration, deletion, config change)
  states its undo in one line; a plan that can't say how to undo a step is flagging a
  design problem early. *Trade-off:* trivial for most tasks; the value concentrates in
  the few risky ones.

### Medium

- **Option B — Execution metadata** *(uses CC2)*. Each task carries machine-readable
  metadata (files, dependencies on other tasks, complexity class) that
  subagent-driven-development consumes directly for model routing and parallel waves —
  the plan becomes the orchestrator's input format, not just prose.
  *Trade-off:* only pays off if SDD Options A/B are adopted.
- **Option E — Plan-review gate** *(uses CC1, CC4)*. The self-review checklist becomes
  tracked todos, and the handoff ends in one structured question (execute now / revise /
  dispatch a plan reviewer) instead of prose trailing off. *Trade-off:* process polish;
  plan content quality still rests on the checklist itself.
- **Option J — Coverage todos** *(uses CC4)*. One tracked todo per spec requirement
  while planning; the plan isn't done while any requirement lacks a mapped task —
  Option C's matrix, enforced during writing instead of assembled at the end.
  *Trade-off:* requires the spec to enumerate requirements cleanly.
- **Option K — Plan-weight classes** *(uses CC7)*. Three plan formats by scope (patch:
  checklist only; feature: full format; epic: full format + decomposition pass), each
  with its required sections — so a three-task fix doesn't carry epic ceremony and an
  epic can't ship as a checklist. *Trade-off:* boundary cases burn a classification
  decision; default upward.

### Advanced

- **Option A — Plan linter** *(uses CC3)*. A script that checks a plan file for the
  skill's own rules: required header, checkbox syntax, exact file paths, placeholder
  phrases ("TBD", "add appropriate error handling"), code blocks present in code steps,
  cross-task identifier consistency. Self-review becomes "run the linter, fix, rerun".
  *Trade-off:* lexical checks can't judge whether the code in a step is *right*.
- **Option F — Plan compiler.** A script that emits a machine-readable task list (JSON:
  files, dependencies, complexity class) from a conforming plan — Option B's metadata
  produced mechanically instead of hand-written, feeding SDD's wave dispatch and model
  routing directly. *Trade-off:* requires B's metadata conventions first; two formats
  (markdown + JSON) to keep consistent.
- **Option L — Planning feedback loop** *(uses CC8)*. After execution, divergences
  (deviation-log entries, re-planned tasks, blown estimates) get summarized into a
  durable planning-lessons file the next planning session reads first — plans learn
  from their own execution history. *Trade-off:* depends on executing-plans D (the
  deviation log) producing the raw material.

> **Recommended: A**, adding B if subagent-driven-development Option A is chosen — the
> two upgrades are designed to meet in the middle.

## writing-skills (655 lines)

**Current state:** The tier's biggest file. The TDD-for-docs core is excellent, but
testing methodology, CSO guidance, persuasion psychology, and checklists all live
inline, and "run pressure scenarios with subagents" is described, never automated.

### Simple

- **Option D — Description cookbook.** Before/after rewrites of skill descriptions
  (trigger-first phrasing, third person, concrete cue words), since description quality
  is what drives discovery for every other skill. *Trade-off:* content only; belongs in
  the CSO reference file if A is also adopted.
- **Option E — Budget table.** One table of word/line budgets per skill class
  (always-loaded / workflow / reference), giving CC6 a concrete number per class — and
  giving the linter (C) something mechanical to enforce later. *Trade-off:* numbers
  invite gaming; budgets need a stated escape hatch for genuinely irreducible skills.
- **Option G — Trigger-phrase inventory.** Per skill, list the literal user phrasings
  that should fire it ("this is broken", "why is this failing" →
  systematic-debugging); write descriptions *from* the inventory rather than guessing
  cue words. *Trade-off:* inventories go stale as usage evolves; date them.
- **Option H — Skill-rot table.** The signs an existing skill is decaying — dangling
  references, a growing FAQ section, users routinely bypassing it, examples that no
  longer run — each with the repair move. *Trade-off:* content only.
- **Option I — One-job test.** A quick check that a skill has a single trigger
  condition; if the description needs "or" twice, it's probably two skills — cheap
  decomposition pressure at authoring time. *Trade-off:* over-splitting fragments the
  library; the test is a prompt, not a rule.

### Medium

- **Option A — Progressive disclosure split** *(uses CC6)*. Keep the iron law,
  RED-GREEN-REFACTOR mapping, and the creation checklist inline (<300 lines); move CSO
  details, testing methodology, anti-patterns, and persuasion notes to reference files
  loaded when needed. Practices what the skill itself preaches. *Trade-off:* pure
  restructuring; risk of breaking internal references — diff carefully.
- **Option F — Checklist todos** *(uses CC4)*. The skill-creation/edit checklist becomes
  tracked todos, so the RED step (write the failing pressure test first) can't be
  silently skipped on the way to shipping a skill. *Trade-off:* ceremony for trivial
  description tweaks; needs a small-edit fast-path.
- **Option J — Description A/B drafting.** When writing or editing a description,
  draft two candidates and check both against the trigger-phrase inventory (G) before
  picking — descriptions are the highest-leverage 50 words in any skill. *Trade-off:*
  doubles drafting effort for a marginal-looking gain that compounds across every
  session.
- **Option K — Edit-size fast-path** *(uses CC7)*. Typo fixes and description tweaks
  get a reduced checklist (frontmatter still valid, description still triggers); new
  skills and behavior changes get the full RED-GREEN cycle — the small-edit fast-path
  F's trade-off explicitly asks for. *Trade-off:* "just a description tweak" is
  exactly where triggering regressions hide; the reduced checklist must still include
  a trigger check.

### Advanced

- **Option B — Pressure-test harness** *(uses CC3)*. A script that scaffolds pressure
  scenarios, dispatches baseline (no-skill) and with-skill subagents, and saves both
  transcripts side by side — making the RED phase a command instead of a 30-minute
  manual ritual, so it actually happens. *Trade-off:* most build effort of any option in
  this doc.
- **Option C — Skill linter** *(uses CC3)*. Mechanical checks: frontmatter validity,
  description starts with "Use when", word-count budgets by skill class, no `@`
  force-loads, kebab-case naming. Cheap CI for v1–v5. *Trade-off:* catches format, not
  effectiveness.
- **Option L — Pressure-test regression suite** *(uses CC8)*. Persist B's scenarios and
  transcripts as a durable corpus, and re-run the relevant scenarios whenever a skill
  changes — pressure tests become regression tests instead of one-shot birth
  certificates. *Trade-off:* only meaningful after B exists; transcript-based
  assertions are fuzzy to evaluate.

> **Recommended: B.** The skill's whole thesis is "no skill without a failing test
> first" — the harness is what makes that law followable at scale. Take C as a cheap
> companion.

---

## Decision tracker

| Skill | Recommended | Band | Chosen | Status |
|---|---|---|---|---|
| brainstorming | A — Fidelity contract (+B escape hatch) | Medium | **A** | implemented 2026-06-11 |
| dispatching-parallel-agents | A — Harness-native dispatch | Advanced | — | pending |
| executing-plans | C — Degraded-mode twin | Medium | — | pending |
| finishing-a-development-branch | A — Scriptify (+B menu) | Advanced | — | pending |
| receiving-code-review | A — Evidence-gated triage | Medium | — | pending |
| requesting-code-review | A — Risk-scaled depth (via C bundler) | Medium+Adv | — | pending |
| subagent-driven-development | A — Parallel waves | Advanced | — | pending |
| systematic-debugging | A — Debugging ledger | Medium | — | pending |
| test-driven-development | A — Red-green evidence trail | Medium | — | pending |
| using-git-worktrees | A + C — Scriptify + baseline handshake | Adv+Medium | — | pending |
| using-superpowers | A + B — Token diet + routing table | Medium | — | pending |
| verification-before-completion | A — Verification manifest | Advanced | — | pending |
| writing-plans | A — Plan linter | Advanced | — | pending |
| writing-skills | B — Pressure-test harness (+C linter) | Advanced | — | pending |

Skill renaming decisions are tracked separately in `RENAMING-OPTIONS.md`.

---

## Work orders from the 2026-06-10 v2 re-analysis

Four procedure gaps found in the fresh v1 re-read are in-place improvements to
existing v1 skills, not v2 skills (spec:
`docs/superpowers/specs/2026-06-10-v2-reanalysis-design.md`, "Rejected and
re-routed"). Fold each into its skill's next supercharging pass:

- **brainstorming — spec self-review rubric.** The self-review step lists four
  dimensions (placeholders, consistency, scope, ambiguity) with no pass/fail
  criteria per dimension. Add a concrete rubric with one example failure each.
- **test-driven-development — RED-phase validation checklist.** "Verify the test
  fails correctly" names symptoms but no procedure. Add a checklist
  distinguishing assertion-failure from error, expected-message match, and
  fails-for-the-right-reason confirmation.
- **systematic-debugging — instrumentation recipes.** "Add diagnostic
  instrumentation at component boundaries" has no how. Add a short recipe table
  per context (app code, test harness, CI pipeline, external service boundary).
- **writing-plans — task-granularity heuristic.** The 2–5-minute step rule has
  no estimation procedure. Add the three-question check: one sentence to
  describe? one observable outcome? no hidden sub-decisions?
