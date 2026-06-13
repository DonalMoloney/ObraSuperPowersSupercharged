---
name: write-release-notes
description: Use when a branch is being finished (merge or PR) and the change is user-facing enough to deserve a release note — turns the branch's git log, PR bodies, and spec summary into human-readable release notes grouped by feature / fix / internal, drafted at finish time while the context is still loaded.
author: Donal Moloney
tier: v2
supports: [finishing-a-development-branch]
type: technique
pairs-with: post-merge-retro
---

## Not this skill if

- You are running the team/process retrospective (what the feature taught, where learnings go) — that is v2 **post-merge-retro**. This skill produces the USER-FACING notes; the retro harvests internal learnings. They run back-to-back but answer to different audiences.
- The merge/PR decision itself isn't made yet — that is v1 **finishing-a-development-branch**. This skill drafts notes for the change being landed there; it does not decide how to land it.
- The change is internal-only with nothing a reader of a changelog or GitHub Release would care about — skip explicitly rather than fabricating a feature line.

# Write Release Notes

## Purpose

Release notes written days later are reconstructed from a cold git log, with the *why* already forgotten — so they degrade into a list of commit subjects. Drafting them at finish time, while the spec and PR context are still in the session, produces notes a human can read: grouped by what the reader cares about, with the user-facing intent intact. This skill is the drafting beat between landing the branch (v1 **finishing-a-development-branch**) and the retro (v2 **post-merge-retro**).

**Core rule:** group by audience impact (Feature / Fix / Internal), not by commit order. Every entry is one human-readable line, not a pasted commit subject.

## Sources (in priority order)

The branch is already in context at finish time — read these, highest-signal first:

1. **Spec / plan summary** — the intent of the work; the source of the feature-level one-liners.
2. **PR body** — the human framing the author already wrote (the `## Summary` bullets from the v1 finishing-a-development-branch PR template are a ready-made starting point).
3. **`git log <base-branch>..HEAD`** — the change inventory. Squashed branches hide individual changes; read PR bodies for the real context behind a single squash commit.

## Procedure

1. **Inventory** — list the merged changes from the sources above. Pull the *intent* from spec/PR, not the literal commit subject.
2. **Triage each change into exactly one bucket:**
   - **Features** — new user-facing capability.
   - **Fixes** — corrected behaviour a user could have hit.
   - **Internal** — refactors, perf, deps, tooling; only included if a reader would care (most CI/typo commits are dropped, not bucketed).
3. **Flag breaking changes at the top** — removed/renamed APIs, changed defaults, migration steps. These lead the notes regardless of bucket.
4. **Write one line per entry** — phrased for the reader ("Add parallel test sharding"), with its PR/issue reference (`#234`) where one exists.
5. **Format for the target** — a `## v<version> (<date>)` block for a CHANGELOG or GitHub Release. If the project keeps no changelog, hand the draft to v2 **post-merge-retro** step 1, which decides where it lands.

## Output shape

```markdown
## v1.3.0 (2026-05-30)

**Breaking:** Removed deprecated `legacyAuth()` — migrate to `auth()`.

### Features
- Add parallel test sharding (#234)

### Fixes
- Fix race condition in cache invalidation (#241)

### Internal
- Refactor routing layer for clarity (#236)
```

## Pitfalls

| Anti-pattern | Correct |
|---|---|
| Pasting commit subjects as the notes | Rewrite each as a reader-facing line; the commit is the source, not the output |
| Drafting from a cold git log days later | Draft at finish time while spec + PR context are loaded |
| Bucketing every trivial commit (CI, typos) | Drop them; Internal is only changes a reader cares about |
| Burying a breaking change in Fixes | Breaking changes lead the notes, flagged, with the migration step |
| Trusting a single squash commit's subject | Read the PR body behind the squash for the real change set |
| Writing the same content as the retro | The notes are user-facing; the retro is internal learnings — different audiences, both run |

## After

Verify every merged user-facing change appears in exactly one bucket, breaking changes lead the block, and each entry is a human line (not a commit subject). Hand the draft to v2 **post-merge-retro** so it lands in the changelog/release rather than dying in the session.

PROVEN BY: the drafted `## v<version>` block, with every entry traceable to a PR/commit/spec source and breaking changes at the top. A note that is a verbatim dump of `git log` subjects is invalid under this skill.
