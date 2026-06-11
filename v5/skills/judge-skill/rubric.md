# judge-skill Scoring Rubric

Each dimension is scored 0, 3, or 5. Multiply by 4 to get points out of 20.
Total = sum of five dimensions (max 100).

---

## Dimension 1 — Trigger Clarity (×4 = 0/12/20)

**Key question:** Does a future Claude instance reading only the `description:` field know exactly when to invoke this skill?

| Score | Criteria |
|-------|----------|
| **5** | `description:` starts with "Use when"; names a concrete, specific trigger (a symptom, an artifact, a task type); contains at least one keyword a search would use; under 500 characters; does NOT summarise the skill's workflow |
| **3** | Starts with "Use when" but trigger is vague or abstract ("when doing code work"), OR contains a brief workflow hint, OR keyword coverage is thin |
| **0** | Does not start with "Use when"; OR trigger is missing entirely; OR description summarises the process instead of the triggering condition |

**Disqualifiers (auto-0):**
- Description starts with "This skill…", "Helps you…", or is a gerund summary ("Scoring SKILL.md files…")
- Trigger mentions the skill's internal steps

---

## Dimension 2 — Process Completeness (×4 = 0/12/20)

**Key question:** Could a different agent follow this skill's steps without asking a single clarifying question?

| Score | Criteria |
|-------|----------|
| **5** | All steps are numbered; each step is a concrete, runnable action (verb-first imperative); no step requires interpretation; output format is specified; edge cases that require a different path are covered |
| **3** | Steps exist but at least one is ambiguous ("review the output"), or the output format is unspecified, or a common edge case is missing |
| **0** | No steps; or steps are at such a high level of abstraction that they cannot be followed without additional guidance; or the skill describes goals without describing actions |

**Disqualifiers (auto-0):**
- Skill body consists only of bullet points without a process section

---

## Dimension 3 — Proof-Gate Presence (×4 = 0/12/20)

**Key question:** Is there a mechanism that forces evidence before a completion claim?

| Score | Criteria |
|-------|----------|
| **5** | Explicit `PROVEN BY:` tag format is shown OR a verification step is numbered in the process AND the step names a specific check (command, assertion, observable) OR `chains-to: proof-gate` or `Pairs with: proof-gate` is present with a note explaining what is verified |
| **3** | A verification step exists but the check is underspecified ("verify the output looks correct"), or the pairs-with reference exists but no verification guidance is given |
| **0** | No verification step, no `PROVEN BY:` format, no `proof-gate` reference of any kind |

**Disqualifiers (auto-0):**
- "Verify" appears only in a pitfalls section warning not to skip it — that is not evidence of proof-gate presence

---

## Dimension 4 — Voice Consistency (×4 = 0/12/20)

**Key question:** Is every sentence in the skill body imperative, precise, and free of marketing language?

| Score | Criteria |
|-------|----------|
| **5** | All process steps are imperative ("Read the file", "Emit the scorecard"); all descriptive sentences are declarative and factual; no hedges ("might", "could", "usually"); no marketing adjectives ("powerful", "robust", "seamlessly"); no falsifiable percentages without a citation |
| **3** | Mostly compliant but 1–3 instances of hedging, marketing language, or passive voice in process steps |
| **0** | Pervasive hedging or marketing language; process steps written in passive or third-person ("the agent should…", "Claude will…"); or skill body reads like a sales document |

**Marketing language blacklist** (presence of any → max score 3):
`powerful`, `robust`, `seamlessly`, `easily`, `just`, `simply`, `amazing`, `best-in-class`, `cutting-edge`, `state-of-the-art`

**Hedge blacklist** (3+ instances → max score 3; pervasive → score 0):
`might`, `could`, `should be`, `usually`, `typically`, `generally`, `in most cases`

---

## Dimension 5 — Section Completeness (×4 = 0/12/20)

**Key question:** Are all load-bearing sections present?

| Score | Criteria |
|-------|----------|
| **5** | All required sections present: (a) Purpose or equivalent 1–2-sentence statement of what the skill is; (b) When to use / Triggers / Not this skill if; (c) Process, Core Pattern, or Implementation steps; (d) Pitfalls, Failure modes, or Gotchas; Frontmatter has `name`, `description`, `author`, `track`, `type`, `chains-to` |
| **3** | One required section is missing or skeletal (fewer than 2 substantive lines) |
| **0** | Two or more required sections are absent; or frontmatter is missing required fields |

**Required frontmatter fields:**
- `name` — letters, numbers, hyphens only
- `description` — starts with "Use when"
- `author`
- `track`
- `type`
- `chains-to` (may be `~` if skill is terminal)

**Required body sections (all must be present):**
1. `## Not this skill if` OR `## Triggers` with a "when not to use" clause
2. `# <Skill Title>` (h1 matching the skill name)
3. `## Purpose` (or equivalent opening statement)
4. A process section (`## Process`, `## Core Pattern`, `## Implementation`, or `## Steps`)
5. A failure section (`## Pitfalls`, `## Failure modes`, or `## Gotchas`)

---

## Score Interpretation

| Range | Interpretation | Action |
|-------|---------------|--------|
| 90–100 | Exemplary | Safe to commit; consider as style reference |
| 80–89 | Pass | Safe to commit; address fix list in next iteration |
| 60–79 | Marginal | Do not commit; fix priority items and re-score |
| 40–59 | Poor | Significant rewrite required before re-scoring |
| 0–39 | Failing | Start from `writing-skills` authoring checklist |

**Gate threshold: 80.** The pre-commit hook blocks any `SKILL.md` with a judge-skill score below 80.
