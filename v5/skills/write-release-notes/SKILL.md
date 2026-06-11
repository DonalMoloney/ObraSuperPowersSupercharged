---
name: write-release-notes
description: git log + PR bodies → human-readable release notes grouped by feature/fix/internal
---

# Write Release Notes

> Turn git history and merged PRs into a professional release summary.

## When to use this skill

- You're shipping a release and need human-facing notes
- You want to highlight features, fixes, and breaking changes in one place
- You need to credit contributors or reference related issues
- Release notes should group changes by theme (features / fixes / internal)

## How it works

1. You provide a version range (e.g., `v1.2.0..v1.3.0`)
2. The skill fetches `git log` and merged PR bodies in that range
3. It groups changes: Features (user-facing) → Fixes (bugs) → Internal (perf/refactor)
4. Each entry gets a one-liner + the PR/commit context
5. Breaking changes are flagged at the top
6. Output is formatted for README or GitHub Releases

## Composition

**Calls:** None (reads git + GitHub)
**Called by:** `finish-branch`, CI/CD pipelines

## Example

**Input:** `v1.2.0..v1.3.0`

**Output:**
```
## v1.3.0 (2026-05-30)

⚠️ **Breaking:** Removed deprecated `legacyAuth()` API

### Features
- Add parallel test sharding (#234)
- Support AWS Lambda functions in deployments (#228)

### Fixes
- Fix race condition in cache invalidation (#241)
- Handle missing env vars gracefully (#239)

### Internal
- Refactor routing layer for clarity (#236)
- Upgrade dependencies to latest versions (#235)
```

## Pitfalls

- Squashed commits hide individual changes — use `git log --all` to catch them
- PR titles often vague — read PR bodies for real context
- Don't group trivial commits (CI fixes, typos) unless they're bugs

---

**Status:** Stub — outline complete, implementation pending
