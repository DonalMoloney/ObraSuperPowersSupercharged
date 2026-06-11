---
name: meta-pattern-recognition
description: Spot patterns appearing across 3+ domains to extract universal principles and prevent reinventing wheels
when_to_use: when you recognize the same issue in different places or feel like you're solving a variant of a problem you've solved before
version: 1.1.0
---

# Meta-Pattern Recognition

## Overview

Same problem keeps appearing in different contexts. Extract the **universal pattern** and stop solving it over and over.

**Core principle:** If you see a pattern 3+ times across different domains, extract the abstraction.

## When to use

**Red flags you need this:**
- "Didn't we solve something like this before?"
- Same solution applied to different domains (different names, same mechanism)
- "This problem but for X instead of Y" (X and Y are different domains)
- Pattern reappears in a new codebase/project/context
- Different teams solving the same problem independently

## Process

1. **Collect examples** - Where have you seen this pattern? List 3+ instances across different domains.
2. **Name the essence** - What's fundamentally the same underneath the surface differences?
3. **Extract universal form** - State the pattern in domain-independent terms.
4. **Verify it applies** - Does it actually fit all collected examples?
5. **Document and reuse** - Record the universal pattern so you (and others) can recognize and apply it.

## Example

**Problem instances:**
- Database migrations with rollback capability
- Feature flag rollout with enable/disable
- Kubernetes rolling deployments (old replicas stay until new ones pass healthcheck)
- Blue-green deployments (old version runs until new version confirmed)

**Universal pattern:** "Dual-state machines where old state stays live until new state is verified stable, then transition completes."

**Reusable insight:** This isn't a database problem, deployment problem, or feature-flag problem — it's a **controlled transition pattern** applicable whenever you need zero-downtime state shifts.

## Why this matters

- **10x leverage**: Solving the pattern once applies to 10+ contexts
- **Prevents disasters**: Knowing the pattern's edge cases protects all instances
- **Speeds teams**: New problems become applications of known patterns instead of novel challenges
- **Builds architectural thinking**: Patterns reveal the shape of problems beneath surface differences

## Red flags you're missing a pattern

- "This is completely different from X" (but it's using the same mechanism)
- Three similar implementations in different parts of the codebase
- "We'll probably need to solve this for Y too" (you haven't extracted the universal form yet)

## Remember

- Patterns hide in plain sight — surfaces differ, essences match
- Three instances = pattern; two instances = coincidence
- Name the essence, not the implementation
- Share the pattern so others can recognize and reuse it
