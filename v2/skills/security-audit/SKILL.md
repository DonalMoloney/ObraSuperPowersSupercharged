---
name: security-audit
description: Use when code changes touch auth, crypto, input validation, secrets, or permissions — runs OWASP-grounded checks across the diff, emits a structured findings block with severity and file:line references, and gates completion on v1 verification-before-completion.
author: Donal Moloney
tier: v2
supports: [requesting-code-review, verification-before-completion]
type: process
chains-to: verification-before-completion
---

## Not this skill if
- You need an exhaustive multi-modal sweep of the entire codebase — that full-codebase sweep is out of scope for this skill, which focuses on targeted, diff-scoped checks
- You need to attack a written spec before implementation begins — use v2 **red-team-spec**
- The concern is a known bug with a clear reproduction path, not a latent vulnerability — use v1 **systematic-debugging**
- The change has no auth, crypto, input handling, secrets, or permission logic — skip this and proceed to v1 **verification-before-completion**

# security-audit — OWASP-grounded code security review

## Purpose

Security flaws introduced during development are cheap to fix in review and expensive to fix in production. A code change that touches authentication, cryptography, input handling, secrets management, or access control carries disproportionate risk relative to its size. This skill makes security review concrete: it walks a defined checklist, anchors every finding to a file and line, assigns a severity, and requires a remediation note before the finding is closed. No finding can be silently dropped.

**Core principle:** Every security finding receives a disposition. An undisposed finding blocks v1 **verification-before-completion**.

## Core rule

> **Rule:** Do not claim a diff is secure until every applicable OWASP check has been run against it and every finding — confirmed or refuted — is recorded with a written disposition.

## Triggers

**Use when any of the following are true:**
- The diff adds or modifies authentication or session management code
- The diff touches cryptographic operations (key generation, hashing, signing, encryption, IV/nonce handling)
- The diff handles user-supplied input that flows to a database, shell, filesystem, or template renderer
- The diff adds, moves, or reads secrets, API keys, tokens, or credentials
- The diff changes access control decisions (permission checks, role guards, ownership checks, admin gates)
- The diff introduces a new external integration or trust boundary crossing
- The user explicitly asks for a security review

**Don't use when:**
- The diff is purely test data, documentation, or comments with no behavioral change
- The diff is a pure formatting or linting pass — no logic changed

## The pattern

```
scope diff → run OWASP checks (parallel per category) → adversarially verify each finding
→ assign severity → demand dispositions → completeness critic → v1 verification-before-completion
```

## Steps

### Step 1 — Scope the diff

Before running any check, read the full diff and produce a **scope declaration**:

- **Files changed** — list every modified file with a one-line summary of what changed.
- **Security-relevant surfaces** — identify which of the following are touched: auth/session, crypto, input handling, secrets, permissions, trust boundaries, serialization, dependency additions.
- **Out-of-scope declaration** — explicitly state which categories do not apply to this diff. A category that does not apply must be listed as "N/A — no code in scope" rather than silently omitted.

This declaration is the ground truth for which checks are mandatory.

### Step 2 — Run OWASP checks per category

Run each applicable check. Checks within a category may be run in parallel; categories may also be run in parallel. Each check produces a list of findings or a clean-pass record.

#### A1 — Broken Access Control
- Are permission checks present at every entry point that handles restricted resources?
- Can a user escalate privilege by manipulating an identifier (IDOR — insecure direct object reference)?
- Are admin/elevated endpoints protected by role or permission guards, not just UI hiding?
- Is access control enforced server-side, not client-side?
- Are default-deny patterns used, not default-allow with exception lists?

#### A2 — Cryptographic Failures
- Is sensitive data encrypted at rest and in transit?
- Are weak or deprecated algorithms in use (`MD5`, `SHA-1`, `DES`, `RC4`, `ECB` mode)?
- Are cryptographic keys and secrets stored outside source code and config files tracked in VCS?
- Are IVs/nonces generated freshly and randomly per operation — never hardcoded or reused?
- Is password storage using a slow adaptive hash (`bcrypt`, `argon2`, `scrypt`) rather than a fast hash?
- Is TLS certificate validation enforced, not disabled?

#### A3 — Injection
- Does user input flow, without parameterisation, into SQL, NoSQL, LDAP, OS commands, or XML?
- Are ORM queries constructed with raw string concatenation rather than parameter binding?
- Does any template renderer receive unsanitised user data in a context where it can be interpreted?
- Are shell commands constructed with untrusted data passed directly to `exec`, `popen`, or `subprocess.run(shell=True)`?

#### A4 — Insecure Design
- Does the diff introduce a trust assumption that is never verified (e.g., trusting a header the client can set)?
- Are there missing rate-limit or brute-force controls on authentication or sensitive operations?
- Does the flow allow a race condition between a permission check and a subsequent privileged action (TOCTOU)?
- Are business-logic constraints enforced at the data layer, not just the presentation layer?

#### A5 — Security Misconfiguration
- Are debug modes, verbose error messages, or stack traces enabled in production paths?
- Are new dependencies introduced with known vulnerabilities (check against CVE / `npm audit` / `pip-audit` / `cargo audit`)?
- Are default credentials, example API keys, or placeholder secrets present in config or code?
- Are CORS, CSP, or security headers configured permissively without justification?
- Are file or directory permissions set correctly for newly created files?

#### A6 — Vulnerable and Outdated Components
- Do newly added dependencies have a published CVE at the pinned version?
- Are transitive dependency updates pulling in a version with a known vulnerability?
- Is the dependency version pinned precisely or using a wildcard that could resolve to a vulnerable version?

#### A7 — Identification and Authentication Failures
- Are session tokens generated with a cryptographically secure PRNG?
- Are session tokens invalidated on logout and privilege change?
- Are passwords subject to a minimum complexity or length policy?
- Is multi-factor authentication bypass possible through the new code path?
- Are account enumeration attacks possible via timing differences or distinct error messages for valid vs. invalid usernames?

#### A8 — Software and Data Integrity Failures
- Are serialised objects from untrusted sources deserialised without type or schema validation?
- Are CI/CD pipeline steps or build scripts modified in a way that could introduce a supply-chain injection point?
- Are software update mechanisms verified with a signature before application?

#### A9 — Security Logging and Monitoring Failures
- Are authentication failures, access control violations, and input validation failures logged?
- Are log entries free of secrets, passwords, or sensitive PII?
- Is there a mechanism to detect and alert on anomalous access patterns introduced by the new code?

#### A10 — Server-Side Request Forgery (SSRF)
- Does the diff introduce a code path where user-supplied URLs or hostnames are fetched server-side?
- Is there an allowlist of permitted fetch targets, or is the URL accepted verbatim?
- Are internal network ranges (`169.254.0.0/16`, `10.0.0.0/8`, `127.0.0.1`) blocked from being targeted via user input?
- Does the fetch follow redirects that could be used to escape the allowlist?

### Step 3 — Adversarially verify each finding

For every candidate finding, attempt to construct a counterargument that refutes it:
- Is the vulnerable path actually reachable from an untrusted entry point?
- Is there an upstream guard that prevents the bad input from arriving at the vulnerable call?
- Is the finding a false positive from a pattern match that misidentified the data type or context?

Keep only findings that survive scrutiny. Mark refuted candidates as `status: refuted` and retain them in the output — do not silently drop them.

### Step 4 — Assign severity

For each surviving confirmed finding, assign a severity level:

| Severity | Criteria |
|---|---|
| **CRITICAL** | Direct path to data breach, remote code execution, authentication bypass, or privilege escalation with no additional prerequisites |
| **HIGH** | Exploitable by an authenticated attacker or requires one additional precondition; would require a design change to fully remediate |
| **MEDIUM** | Requires chaining with another flaw or a specific environment condition; code-level fix is sufficient |
| **LOW** | Defence-in-depth gap, hardening opportunity, or clarification that reduces future risk |

### Step 5 — Emit the findings block

Produce the structured findings block (see Output section). Every finding must have a file:line reference. No finding may be left without a remediation note, however brief.

### Step 6 — Demand dispositions

For every finding, require one of:

- `FIXED — <one sentence describing the change made>`
- `ACCEPTED (risk: <one sentence stating what is accepted and why it is tolerable>)`
- `REJECTED (reason: <one sentence explaining why the finding is a false positive or already mitigated>)`

A finding without a disposition blocks v1 **verification-before-completion**. "Will fix later" is not a disposition.

### Step 7 — Completeness critic

Before closing, ask:
- Which OWASP category was declared N/A — is that declaration correct on re-examination?
- Is there a finding whose remediation note references a mitigation that was not actually verified to be present in the diff?
- Does any `ACCEPTED` risk interact with another `ACCEPTED` risk to produce a compounded failure?

If the critic identifies a gap, re-run the relevant check and repeat Step 3–5 for the new candidates.

### Step 8 — Hand off to v1 verification-before-completion

After all findings carry dispositions and the completeness critic is satisfied, run v1 **verification-before-completion** to confirm any remediation code that was written actually compiles or passes its tests, capturing the evidence block (command + literal output).

## Output

### Scope declaration

```
SCOPE:
  files: <list>
  security surfaces touched: <list>
  categories N/A: <list with reason>
```

### Findings block

```
SECURITY FINDINGS — <date> — <diff ref or PR number>

[CRITICAL] <Short title>
  file: <path>:<line>
  category: <OWASP A#>
  detail: <One or two sentences describing the flaw and its exploitation path.>
  remediation: <Specific, actionable fix — algorithm name, function to use, pattern to apply.>
  disposition: <FIXED / ACCEPTED (risk: ...) / REJECTED (reason: ...)>

[HIGH] <Short title>
  file: <path>:<line>
  category: <OWASP A#>
  detail: ...
  remediation: ...
  disposition: ...

[MEDIUM] ...

[LOW] ...

REFUTED CANDIDATES:
  - <path>:<line> — <one sentence why this was examined and refuted>

CLEAN CATEGORIES:
  - A3 Injection: N/A — no SQL, shell, or template rendering in diff
  - <other clean/N/A categories>

SUMMARY: CRITICAL <n> | HIGH <n> | MEDIUM <n> | LOW <n> | refuted <n>
```

### Proof block

```
EVIDENCE: security-audit on <diff ref>
  → checks run: <applicable OWASP categories, listed>
  → findings: CRITICAL <n> | HIGH <n> | MEDIUM <n> | LOW <n>
  → dispositions: <n> FIXED | <n> ACCEPTED | <n> REJECTED
  → refuted candidates: <n>
  → completeness critic: <"no gaps" or gap found + re-check performed>
  → verification: <command run> → <key output line>
```

## Integrates with

- **v1 verification-before-completion** — mandatory before any FIXED disposition: the remediation's verification command and literal output are captured in the findings block; completion is blocked while any finding is undisposed.
- v2 **red-team-spec** — run before implementation if the feature being reviewed was never adversarially attacked at the spec stage; security holes at spec level will not be found by this skill.
- **v1 writing-plans** — when CRITICAL or HIGH findings require design changes, use v1 **writing-plans** to structure the remediation work before writing any code.

## Pitfalls

| Mistake | Fix |
|---|---|
| Declaring a category N/A without reading the diff | Read every changed line before writing the scope declaration; a one-line helper can introduce a vulnerable call |
| Running only pattern-match checks and missing logic flaws | Pair static pattern checks with data-flow tracing; A4 (Insecure Design) and A7 (Auth) flaws are invisible to grep |
| Marking a finding FIXED without running the remediation code | v1 **verification-before-completion** is mandatory before any FIXED disposition closes the gate |
| Accepting a risk without stating why it is tolerable | `ACCEPTED` without a reason is the same as not reviewing; write the one-sentence risk acceptance explicitly |
| Producing a finding with no file:line reference | Every finding must anchor to a specific location; a floating finding cannot be verified or tracked |
| Skipping the completeness critic | The completeness critic is the only step that catches a mis-declared N/A category or an unverified "mitigation already present" claim |
| Dropping refuted candidates from the output | Retain them with `status: refuted`; they are evidence the check ran and the site was examined |
| Treating MEDIUM and LOW findings as advisory — skippable | All findings require dispositions; severity determines urgency, not whether a disposition is required |

## When process reveals "no findings"

If every applicable OWASP check is clean, the output is:

```
SECURITY FINDINGS — <date> — <diff ref>
  All applicable checks clean. No findings.
  Categories checked: <list>
  Categories N/A: <list with reason>

EVIDENCE: security-audit on <diff ref>
  → checks run: <list>
  → findings: CRITICAL 0 | HIGH 0 | MEDIUM 0 | LOW 0
  → completeness critic: no gaps
  → verification: <command> → <output>
```

A clean pass must still carry an evidence block (per v1 verification-before-completion). A clean pass without a block is an unverified claim.
