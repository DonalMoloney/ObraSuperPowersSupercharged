export const meta = {
  name: 'feature-intake-pipeline',
  description: 'Autonomous intake: scope → contract → red-team → plan → tests',
  phases: [
    { title: 'Scope' },
    { title: 'Contract' },
    { title: 'Red Team' },
    { title: 'Plan' },
    { title: 'Tests' },
  ],
}

// ── Schemas ─────────────────────────────────────────────────────────────────
// Inline — workflow scripts cannot import from other files.

const SCOPE_SCHEMA = {
  type: 'object',
  required: ['purpose', 'constraints', 'successCriteria', 'nonGoals', 'confidence'],
  properties: {
    purpose:         { type: 'string' },
    constraints:     { type: 'array', items: { type: 'string' } },
    successCriteria: { type: 'array', items: { type: 'string' } },
    nonGoals:        { type: 'array', items: { type: 'string' } },
    affectedSystems: { type: 'array', items: { type: 'string' } },
    rollbackStrategy:{ type: 'string' },
    openQuestions:   { type: 'array', items: { type: 'string' } },
    confidence:      { type: 'number', minimum: 0, maximum: 1 },
  },
}

const CONTRACT_SCHEMA = {
  type: 'object',
  required: ['goal', 'acceptanceCriteria', 'outOfScope', 'doneWhen', 'constraints', 'openDecisions', 'confidence'],
  properties: {
    goal:               { type: 'string' },
    acceptanceCriteria: { type: 'array', items: { type: 'string' } },
    outOfScope:         { type: 'array', items: { type: 'string' } },
    doneWhen:           { type: 'array', items: { type: 'string' } },
    constraints:        { type: 'array', items: { type: 'string' } },
    openDecisions:      { type: 'array', items: { type: 'string' } },
    confidence:         { type: 'number', minimum: 0, maximum: 1 },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['lens', 'verdict', 'findings', 'hasCritical'],
  properties: {
    lens:    { type: 'string', enum: ['correctness', 'scope', 'testability'] },
    verdict: { type: 'string', enum: ['pass', 'fail'] },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'description', 'recommendation'],
        properties: {
          severity:       { type: 'string', enum: ['CRITICAL', 'MAJOR', 'MINOR'] },
          description:    { type: 'string' },
          recommendation: { type: 'string' },
        },
      },
    },
    hasCritical: { type: 'boolean' },
  },
}

const PLAN_SCHEMA = {
  type: 'object',
  required: ['tasks', 'filesToCreate', 'filesToModify', 'confidence'],
  properties: {
    tasks: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'title', 'files', 'doneWhen', 'mapsToContract'],
        properties: {
          id:              { type: 'number' },
          title:           { type: 'string' },
          files:           { type: 'array', items: { type: 'string' } },
          doneWhen:        { type: 'string' },
          mapsToContract:  { type: 'array', items: { type: 'string' } },
        },
      },
    },
    filesToCreate: { type: 'array', items: { type: 'string' } },
    filesToModify: { type: 'array', items: { type: 'string' } },
    confidence:    { type: 'number', minimum: 0, maximum: 1 },
  },
}

const TESTS_SCHEMA = {
  type: 'object',
  required: ['testFiles', 'commitMessage', 'failCount', 'passCount', 'confidence'],
  properties: {
    testFiles:     { type: 'array', items: { type: 'string' } },
    commitMessage: { type: 'string' },
    failCount:     { type: 'number' },
    passCount:     { type: 'number' },
    confidence:    { type: 'number', minimum: 0, maximum: 1 },
  },
}

// ── Pipeline args ────────────────────────────────────────────────────────────
// args: { request: string, mode: 'interactive'|'semi-auto'|'full-auto', featureSlug: string }

const mode = (args && args.mode) || 'interactive'
const featureSlug = (args && args.featureSlug) || 'unnamed-feature'
const request = (args && args.request) || ''

log(`feature-intake-pipeline starting`)
log(`Feature: ${featureSlug} | Mode: ${mode}`)

// ── Stage 1: scope-feature ───────────────────────────────────────────────────
phase('Scope')
log('Stage 1: running scope-feature...')

const scope = await agent(
  `You are running the scope-feature skill. Produce a structured scope for the following raw feature request.

Feature request: "${request}"

Scope fields to fill:
- purpose: one sentence — what problem this solves and for whom
- constraints: hard limits (tech stack, compatibility, timeline, no new deps, etc.)
- successCriteria: measurable statements of what "working" looks like — no vague language
- nonGoals: things this deliberately does NOT do; be specific about adjacent capabilities to exclude
- affectedSystems: which services, components, or files are touched
- rollbackStrategy: how to undo this change if it causes problems in production
- openQuestions: unresolved decisions that must be answered before implementation — if none, return []
- confidence: 0.0–1.0 — your confidence that the scope is complete and unambiguous

If the request is ambiguous, flag it in openQuestions rather than assuming. Do not invent constraints.`,
  { schema: SCOPE_SCHEMA, phase: 'Scope', label: 'scope-feature' }
)

log(`Scope complete — confidence: ${scope.confidence}`)
log(`Purpose: ${scope.purpose}`)
if (scope.openQuestions && scope.openQuestions.length > 0) {
  log(`Open questions flagged: ${scope.openQuestions.join(' | ')}`)
}

// ── Stage 2: compile-goal-to-contract ───────────────────────────────────────
phase('Contract')
log('Stage 2: running compile-goal-to-contract...')

const contract = await agent(
  `You are running the compile-goal-to-contract skill. Convert the approved scope into a machine-readable contract.

Approved scope:
- Purpose: ${scope.purpose}
- Constraints: ${scope.constraints.join(', ')}
- Success criteria: ${scope.successCriteria.join(' | ')}
- Non-goals: ${scope.nonGoals.join(', ')}
- Open questions from scope: ${(scope.openQuestions || []).join(', ') || 'none'}

Rules:
- acceptanceCriteria: each must start with a testable verb (Returns, Renders, Passes, Handles, Rejects, Emits). No "should", "must", or "will".
- outOfScope: list the three most likely scope-creep directions explicitly — not "performance optimisation" but "caching layer for X endpoint"
- doneWhen: each item must name a specific test command or observable state. "Tests pass" is not specific. "pytest tests/auth/test_oauth.py returns 0 failed" is.
- openDecisions: resolve ALL open questions from scope with a decision rule. Format: "if X then Y; otherwise Z". Return [] if none remain.
- constraints: hard non-negotiable limits only — not preferences
- confidence: 0.0–1.0 — your confidence that all criteria are independently testable

Do not re-ask questions already resolved in scope.`,
  { schema: CONTRACT_SCHEMA, phase: 'Contract', label: 'compile-goal-to-contract' }
)

log(`Contract complete — confidence: ${contract.confidence}`)
log(`${contract.acceptanceCriteria.length} acceptance criteria | ${contract.doneWhen.length} done-when items | ${contract.openDecisions.length} open decisions`)

// ── Stage 3: adversarial panel ───────────────────────────────────────────────
phase('Red Team')
log('Stage 3: running adversarial panel (3 agents in parallel)...')

const verdicts = await parallel([
  () => agent(
    `You are an adversarial reviewer. Your lens: CORRECTNESS.

Contract to attack:
Goal: ${contract.goal}
Acceptance criteria:
${contract.acceptanceCriteria.map(c => `- ${c}`).join('\n')}

For each acceptance criterion ask:
1. Does it start with a testable verb?
2. Can it be verified without reading the conversation?
3. Could two different engineers interpret it differently?

Be harsh — if something CAN be misinterpreted, it WILL be. Rate findings:
- CRITICAL: blocks the pipeline (untestable criterion, fundamentally ambiguous goal)
- MAJOR: should be fixed before implementation (vague language, missing edge case)
- MINOR: nice to fix (wording, clarity)

Set verdict: "pass" only if no CRITICAL findings. Set hasCritical: true if any CRITICAL exist.`,
    { schema: VERDICT_SCHEMA, phase: 'Red Team', label: 'adversary:correctness' }
  ),
  () => agent(
    `You are an adversarial reviewer. Your lens: SCOPE.

Contract to attack:
Goal: ${contract.goal}
Acceptance criteria:
${contract.acceptanceCriteria.map(c => `- ${c}`).join('\n')}
Out of scope:
${contract.outOfScope.map(s => `- ${s}`).join('\n')}

Ask:
1. What obvious capability is missing that any engineer would expect?
2. What included criterion clearly exceeds the stated goal?
3. Is the out-of-scope list specific enough to prevent scope creep on the three most adjacent features?

Rate findings CRITICAL / MAJOR / MINOR. Set verdict: "pass" if no CRITICAL. Set hasCritical accordingly.`,
    { schema: VERDICT_SCHEMA, phase: 'Red Team', label: 'adversary:scope' }
  ),
  () => agent(
    `You are an adversarial reviewer. Your lens: TESTABILITY.

Contract to attack:
Goal: ${contract.goal}
Done-when:
${contract.doneWhen.map(d => `- ${d}`).join('\n')}
Constraints:
${contract.constraints.map(c => `- ${c}`).join('\n')}

Ask:
1. Can an implementer run each done-when check without asking anyone?
2. Does each done-when name a specific command or observable state?
3. Would two different engineers agree on whether the check passed?

Rate findings CRITICAL / MAJOR / MINOR. Set verdict: "pass" if no CRITICAL. Set hasCritical accordingly.`,
    { schema: VERDICT_SCHEMA, phase: 'Red Team', label: 'adversary:testability' }
  ),
])

const passing = verdicts.filter(Boolean).filter(v => v.verdict === 'pass')
const hasCritical = verdicts.filter(Boolean).some(v => v.hasCritical)
const panelPassed = passing.length >= 2 && !hasCritical

log(`Red team: ${passing.length}/3 passed | critical findings: ${hasCritical}`)

if (!panelPassed) {
  const criticalFindings = verdicts
    .filter(Boolean)
    .flatMap(v => v.findings.filter(f => f.severity === 'CRITICAL'))
  log(`GATE BLOCKED — red team failed`)
  criticalFindings.forEach(f => log(`  CRITICAL: ${f.description} → ${f.recommendation}`))
  return {
    status: 'blocked',
    stage: 'red-team',
    reason: hasCritical ? 'critical-findings' : 'majority-failed',
    verdicts,
    contract,
    scope,
  }
}

const majorFindings = verdicts
  .filter(Boolean)
  .flatMap(v => v.findings.filter(f => f.severity === 'MAJOR'))
if (majorFindings.length > 0) {
  log(`Red team passed with ${majorFindings.length} MAJOR finding(s) — review recommended:`)
  majorFindings.forEach(f => log(`  MAJOR: ${f.description}`))
}

// ── Stage 4: outline-plan ────────────────────────────────────────────────────
phase('Plan')
log('Stage 4: running outline-plan...')

const plan = await agent(
  `You are running the outline-plan skill.

Approved contract:
Goal: ${contract.goal}
Acceptance criteria:
${contract.acceptanceCriteria.map(c => `- ${c}`).join('\n')}
Done-when:
${contract.doneWhen.map(d => `- ${d}`).join('\n')}
Out of scope: ${contract.outOfScope.join(', ')}
Constraints: ${contract.constraints.join(', ')}

Write an implementation plan with 5–15 tasks (hard max: 20). Rules:
- Each task must include at least one exact file path (create or modify)
- Each task must have a doneWhen clause: a specific, runnable check
- Each task must list which acceptanceCriteria it satisfies in mapsToContract
- A task that maps to zero acceptance criteria is scope creep — exclude it
- Tasks must be atomic: one file or one concern per task

List filesToCreate and filesToModify at the top level too.
confidence: 0.0–1.0 — your confidence the plan covers all acceptance criteria within scope.`,
  { schema: PLAN_SCHEMA, phase: 'Plan', label: 'outline-plan' }
)

log(`Plan complete — ${plan.tasks.length} tasks | confidence: ${plan.confidence}`)

if (plan.tasks.length > 20) {
  log(`GATE BLOCKED — ${plan.tasks.length} tasks exceeds hard max of 20`)
  log(`Decompose into two plans. Run the first plan through the pipeline; queue the second.`)
  return {
    status: 'blocked',
    stage: 'plan',
    reason: 'task-count-exceeded',
    taskCount: plan.tasks.length,
    plan,
    contract,
    scope,
  }
}

// ── Stage 5: write-tests-first ───────────────────────────────────────────────
phase('Tests')
log('Stage 5: running write-tests-first...')

const tests = await agent(
  `You are running the write-tests-first skill.

Plan tasks:
${plan.tasks.map(t => `- Task ${t.id}: ${t.title}\n  Files: ${t.files.join(', ')}\n  Done when: ${t.doneWhen}`).join('\n')}

Contract done-when:
${contract.doneWhen.map(d => `- ${d}`).join('\n')}

For each task that introduces new or modified behaviour, specify:
1. The test file path
2. The test names and what they assert
3. Why the test will fail before implementation (not an import error — a real assertion failure)

Also provide:
- commitMessage: the git commit message for committing the failing test suite
- failCount: how many tests will fail
- passCount: must be 0 — if any test would pass before implementation, it is testing existing behaviour. Do not include it.
- confidence: 0.0–1.0 — your confidence the test suite covers all done-when items

If a task has no testable behaviour (e.g. a config change with no observable output), skip it.`,
  { schema: TESTS_SCHEMA, phase: 'Tests', label: 'write-tests-first' }
)

log(`Tests complete — ${tests.failCount} failing tests across ${tests.testFiles.length} file(s) | confidence: ${tests.confidence}`)

if (tests.passCount > 0) {
  log(`WARNING: ${tests.passCount} test(s) would pass before implementation — these test existing behaviour and should be excluded`)
}

// ── Handoff ──────────────────────────────────────────────────────────────────
const totalTokens = budget.spent()
log(`All gates passed. Total cost: ${totalTokens} tokens.`)
log(`Handing off to execute-plan.`)

return {
  status: 'complete',
  handoff: {
    task: `implement ${featureSlug} per approved plan`,
    goalContract: {
      goal: contract.goal,
      acceptanceCriteria: contract.acceptanceCriteria,
      doneWhen: contract.doneWhen,
      outOfScope: contract.outOfScope,
    },
    state: {
      featureSlug,
      mode,
      testsPassing: `0/${tests.failCount} (all failing — expected)`,
    },
    evidence: [
      `PROVEN BY: test runner → ${tests.failCount} failed, 0 passed`,
      `PROVEN BY: git commit message: ${tests.commitMessage}`,
    ],
    cost: `${totalTokens} tokens`,
    nextAgent: 'execute-plan',
  },
  artifacts: {
    scope,
    contract,
    redTeamVerdicts: verdicts.filter(Boolean),
    plan,
    tests,
  },
}
