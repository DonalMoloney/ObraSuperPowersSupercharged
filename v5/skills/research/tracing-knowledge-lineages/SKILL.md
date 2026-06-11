---
name: tracing-knowledge-lineages
description: Understand how ideas evolved to find old solutions for new problems and prevent repeating past failures
when_to_use: before major architectural changes, or when a new problem feels familiar but you can't articulate why
version: 1.1.0
---

# Tracing Knowledge Lineages

## Overview

Why are we doing things this way? Trace the decision history to avoid repeating old mistakes and rediscovering old solutions.

**Core principle:** Understanding how we got here prevents cargo-culting.

## When to use

**Use when:**
- About to change a foundational decision or pattern
- Someone says "we've always done it this way" but can't explain why
- A new problem feels familiar but you don't know why
- You're about to reject an old approach without understanding why it exists
- Onboarding: understanding why the codebase is shaped the way it is

**Red flags you need this:**
- "This was done because..." (no actual explanation, just assumption)
- Changing something that's been stable for years (understand why first)
- Multiple failed attempts at the same problem (understand why they failed)
- Finding old code that solves your current problem (but it's "disabled" now)

## The tracing process

### 1. Pick a decision or pattern
What do you want to understand? Example: "Why is authentication stateless?"

### 2. Ask who decided
Who made the choice? When? What was the context?
- Commit history: `git log -p --all -S "stateless"` reveals when and why
- Git blame: `git blame` shows who touched the code
- ADRs (Architecture Decision Records): explicit decisions documented
- Slack/email: Historical discussions (if searchable)

### 3. Understand the constraints
What problem was this solving?
- What failed before this choice?
- What was the failure mode?
- What alternative was rejected and why?

### 4. Recognize the evolution
Has this decision been revisited?
- Changed implementations of the same idea
- Variants for different contexts
- Attempted reversals that didn't stick

### 5. Apply the insight
What does this tell you now?
- Is the original constraint still valid?
- Has the technology changed such that the constraint no longer applies?
- Would reverting this create a different set of problems?

## Example: Stateless Authentication

**The pattern:** Every request includes credentials; no server-side session.

**Tracing:**
1. Original decision (2015): Build mobile app + web, needed shared auth
2. Problem it solved: Cross-domain session sharing (mobile app talks to API)
3. Alternative rejected: Server sessions + mobile session sync (too complex)
4. Evolution: Token format changed (JWT → opaque tokens), but stateless principle held
5. Why it held: Performance benefit (no session lookup per request) and scalability

**Insight for now:** Stateless is still the right choice for distributed systems, but recent changes to token revocation speed might warrant revisiting for security-sensitive operations.

## Why this matters

- **Prevents cargo-culting**: Decisions made for constraints that no longer exist
- **Finds old solutions**: Previous attempts at similar problems carry lessons
- **Builds judgment**: Understanding why builds the ability to judge when to change it
- **Accelerates onboarding**: New team members understand not just what, but why

## Red flags

- "We've always done this" (without understanding why)
- Reverting a decision that was made for good reasons
- Repeating a problem that was solved 5 years ago (and the solution atrophied)
- Making a decision without checking if we tried and failed at something similar

## Remember

- Every pattern has a history
- Old solutions are often solutions for real problems
- Understanding why prevents repeating mistakes
- The constraints that made something true may have changed
