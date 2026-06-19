---
name: safe-dependency-bump
description: Use when upgrading a dependency (or a batch of them) and you want the change safe and reviewable — reads the changelog for breaking changes across the whole version delta, bumps one dependency (or one coupled set) per change, regenerates the lockfile with the package manager, applies required migrations, checks transitive/peer impact, and proves it with a green suite.
author: Donal Moloney
tier: v2
supports: [verification-before-completion, finishing-a-development-branch]
type: technique
chains-to: verification-before-completion
pairs-with: resolve-merge-conflict
---

## Not this skill if

- **Security hotfix for a known CVE** — apply the patched version immediately; the deliberate changelog pass below can follow, but don't let it block the fix.
- You're **adding a new dependency**, not bumping one — that's a design decision (do you need it at all?). Take it through v1 **brainstorming** first.
- You're bumping an **internal/workspace package** you control — that's release coordination, not an external-dependency upgrade.

# Safe Dependency Bump

## Purpose

Upgrade pain comes from two habits: skipping the changelog, and bumping many dependencies at once so a breakage can't be traced to the bump that caused it. This skill makes upgrades **bisectable and informed** — one dependency (or one set that must move together) per change, with the breaking changes read *before* the bump, the migrations applied *in* the bump, and a green suite proving it.

Supports v1 **verification-before-completion** (a green install is not a green build) and v1 **finishing-a-development-branch** (focused, reviewable upgrade PRs).

## Procedure

1. **Pin the delta and size the jump.** Record `current → target` and read it as semver: patch / minor / **major**. A major is a breaking-changes contract — there is a migration guide; treat it as required reading, not a version number.
2. **Read the changelog across the whole delta.** Every intervening minor and major between current and target, not just the target's notes. Capture: breaking changes, deprecations, and any required code/config migration. **This is the step people skip and pay for in production.**
3. **Bump one unit per change.** A single dependency, or a tightly-coupled set that must move together (a framework + plugins pinned to its version). Update the manifest, then **regenerate the lockfile with the package manager** — `npm install` / `npm update <pkg>`, `pnpm up <pkg>`, `poetry update <pkg>`, `pip-compile`, `cargo update -p <pkg>`, `go get <pkg>@<ver> && go mod tidy`, `bundle update <gem>`. Never hand-edit a lockfile.
4. **Apply the migrations from step 2 in the same change.** A bump that requires a code change isn't done until that code change lands with it — otherwise the next person bisects to a "bump" commit that never worked.
5. **Check transitive and peer impact.** Did the lockfile pull a new transitive *major*? Any peer-dependency warnings? Use the tool's inspector — `npm why <pkg>` / `npm ls <pkg>`, `cargo tree -i <pkg>`, `pipdeptree`, `go mod graph` — to see what else moved. Resolve warnings now, not in prod.
6. **Verify.** Full build + full test suite. Where tests are thin, also **smoke the upgraded surface** — exercise the specific APIs the changelog flagged as changed.
7. **Scope the PR.** One dependency (or coupled set) per PR where feasible, with the changelog highlights and the migrations you made in the description. A 30-dependency mega-bump is neither reviewable nor bisectable.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Bumping everything in one commit | One focused bump per change — keep it bisectable |
| Skipping the changelog | Read breaking changes across the whole delta first |
| Hand-editing the lockfile to "make it match" | Regenerate it with the package manager |
| Treating a major like a patch | Majors ship a migration guide; follow it in the same change |
| "It installed, ship it" | Install success ≠ working — run the suite, smoke the changed API |
| Ignoring peer/transitive warnings | Resolve them in this change, not after a prod failure |

## After

Hand the green, migrated state to v1 **verification-before-completion** (or v2 **done-gate**) before opening the upgrade PR. If a later rebase conflicts on the lockfile, resolve it with v2 **resolve-merge-conflict** (take one side, then regenerate the lockfile — never hand-merge it).

PROVEN BY: the version delta (`<pkg> X.Y.Z → A.B.C`), the breaking changes reviewed from the changelog, the migrations applied, the transitive/peer check output, and the post-bump full-suite result (totals, 0 failures). An upgrade claimed on install success alone does not satisfy this skill.
