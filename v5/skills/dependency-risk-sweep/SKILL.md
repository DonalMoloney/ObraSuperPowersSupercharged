---
name: dependency-risk-sweep
description: Use before an upgrade or audit — fan out over the dependency tree, one agent per high-risk dep checks changelog, breaking changes, CVEs, and maintenance health, then merge into a ranked upgrade/replace plan.
author: Donal Moloney
track: B
type: process
chains-to: migrate-codebase
---

## Not this skill if
- You're bumping one known dependency — just read its changelog and upgrade.
- You need to execute the migration, not plan it — use `migrate-codebase`.
- You have fewer than five dependencies to check — do it inline; the fan-out overhead is not worth it.
- You're doing a general security audit unrelated to dependency versions — use a dedicated CVE scanner directly.

# dependency-risk-sweep — rank the risk before you touch versions

## Purpose

Replace ad-hoc "just run `npm update`" with a risk-ranked plan: which deps are dangerous to upgrade, which are dangerous to keep, and in what order to act. Every recommendation cites evidence — no guesses, no "probably fine".

## Core rule

> **Rule:** Every recommendation cites evidence — a changelog entry, CVE ID, or maintenance signal (last release date, open-issue ratio, bus factor). No "probably fine".

## Triggers

**Use when:**
- Pre-upgrade audit: "what breaks if I update everything?"
- Security review prompted by a CVE advisory or Dependabot/Renovate noise.
- "Are our dependencies safe / stale?" — periodic health check.
- Onboarding to a codebase: building a mental map of dependency risk before touching anything.
- A dependency reaches end-of-life or the maintainer archives the repo.

**Don't use when:**
- You're bumping a single, well-understood dependency — just read its changelog.
- The codebase has no manifest or lockfile to parse (no structured dependency list exists).
- The goal is executing upgrades, not planning them — hand off to `migrate-codebase` for that.

## The pattern

```
triage(manifest + lockfile)          // build blast-radius map
  → select(high-risk set)            // filter by import-weight + known flags
  → fan_out(per-dep agents)          // parallel: changelog + CVEs + health per dep
  → merge(findings)                  // rank into upgrade-now / upgrade-carefully / replace / hold
  → hand_off(migrate-codebase)       // for upgrades that touch many call sites
```

## Steps

### 1. Parse the manifest and lockfile — build the import-weight map

Read the dependency manifest (`package.json`, `requirements.txt`, `go.mod`, `Gemfile`, etc.) and the corresponding lockfile. For each dependency, record:
- **Direct vs. transitive** — direct deps have higher blast radius per change.
- **Import-weight** — how many internal modules/files import this package. Count unique import sites, not lines.
- **Current pinned version vs. latest available** — use the lockfile for pinned version; query the registry or the `ossf/scorecard` API for latest.

Flag any package that is pinned more than two major versions behind, unmaintained (last release >18 months), or has an open CVE. These form the initial high-risk candidate set.

### 2. Select the high-risk set for fan-out

Apply the triage filter — promote a dependency to the high-risk set if it meets at least one of:
- Import-weight in top 20% of the tree (touches the most code).
- Pinned version is behind a breaking-change major release.
- Any CVE with CVSS >= 7.0 linked to the current pinned version.
- Maintenance signal: last release >18 months ago OR repo archived/unmaintained.
- Listed in a supplied blocklist or a prior security advisory.

Cap the high-risk set at a manageable size (typically ≤ 20 for a single sweep). If the set exceeds the cap, log the dropped candidates with their blast-radius score so a second sweep can cover them. No silent caps.

### 3. Fan out per-dep agents (parallel)

Dispatch one agent per high-risk dependency. Each agent independently performs three sub-checks:

**a. Changelog / breaking changes**
- Fetch the changelog or GitHub release notes between the pinned version and the latest stable release.
- Identify any entry tagged `BREAKING`, `REMOVED`, `DEPRECATED`, or containing API surface changes.
- Record the specific versions where breakage occurs.

**b. CVE scan**
- Query the `jeremylong/DependencyCheck` database (or equivalent) for known vulnerabilities tied to the pinned version range.
- Record CVE IDs, CVSS scores, and whether a patched version exists.

**c. Maintenance health**
- Pull signals from `ossf/scorecard` or the registry metadata: last release date, release cadence, open-issue count vs. closed-issue count, number of active maintainers.
- Flag if the project is archived, has a single maintainer, or has a steeply declining commit frequency.

Each agent returns a structured record: `{ dep, pinned_version, latest_version, breaking_changes: [], cves: [], health_signals: {}, recommendation }`.

### 4. Merge findings into a ranked action plan

Collect all per-dep records. Rank each dependency into one of four buckets:

| Bucket | Criteria |
|---|---|
| **Upgrade now** | Active CVE with CVSS >= 7.0 AND patched version available |
| **Upgrade carefully** | Breaking changes exist but no active CVE; high import-weight requires coordinated callsite updates |
| **Replace** | Unmaintained (archived or last release >18 months) AND no active CVE — plan a migration away |
| **Hold** | No CVE, no breaking changes in the target version range, healthy maintenance — safe to stay or upgrade opportunistically |

Within each bucket, order by blast radius descending. Attach the evidence record to each entry — every action item cites at least one changelog entry, CVE ID, or maintenance signal.

### 5. Hand off wide upgrades to `migrate-codebase`

For any "Upgrade carefully" or "Replace" item that touches more than a configurable threshold of call sites (default: 10+ import sites), append a handoff note: "Delegate to `migrate-codebase` — N call sites affected." Do not attempt the migration here; this skill produces a plan, not execution.

Deliver the final ranked plan as the output artifact.

## Common mistakes / Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Silent cap — sweep quietly skips low-ranked deps that later turn out to have CVEs | Log all dropped candidates with their blast-radius score and the cap reason before the fan-out starts |
| Treating "no CVE in the database" as "safe" | Note explicitly that the scan covers known CVEs only; zero findings does not mean zero risk |
| Ranking by CVE count alone, ignoring blast radius | Weight by import-weight first — a low-severity CVE in a dep imported by 40 modules is higher priority than a high-severity CVE in an unused transitive dep |
| Recommendations without citations | Every action item must cite a specific changelog entry, CVE ID, or maintenance signal — enforce the Core rule before writing the plan |
| Starting the merge before all per-dep agents return | Collect all structured records before ranking; a partial merge produces misleading "Upgrade now" gaps |
| Conflating "replace" with "upgrade" for archived packages | Archived packages need a migration plan, not a version bump — put them in "Replace" and hand off to `migrate-codebase` |

## Output

A ranked dependency action plan with four buckets (Upgrade now / Upgrade carefully / Replace / Hold), each entry containing:
- Dependency name and pinned version.
- Target version (if upgrading) or replacement candidate (if replacing).
- Blast radius: number of import sites.
- Evidence: changelog entry, CVE ID, or maintenance signal.
- Handoff flag if `migrate-codebase` delegation is recommended.

## Verification / Proof

Before delivering the plan, verify:
- Every "Upgrade now" and "Upgrade carefully" entry has at least one cited CVE ID or changelog reference.
- Every "Replace" entry has a maintenance signal (archive date, last-release age, or bus-factor flag).
- The dropped-candidates log is present if the high-risk set was capped.
- No dependency appears in more than one bucket.

A valid `PROVEN BY:` block must contain:
- List of dependencies scanned (name + pinned version).
- Count of deps in the high-risk set vs. total deps parsed.
- Count of dropped candidates (if capped) with reason.
- At least one evidence citation per "Upgrade now" and "Upgrade carefully" entry.
- Confirmation that all per-dep agents returned before the merge ran.

## Adapt from
- **`ossf/scorecard`** — automated maintenance/security health signals per dependency.
  <https://github.com/ossf/scorecard>
- **`jeremylong/DependencyCheck`** — CVE/known-vulnerability mapping.
  <https://github.com/jeremylong/DependencyCheck>
