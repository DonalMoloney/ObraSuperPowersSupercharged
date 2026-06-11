---
name: multi-agent-architecture-patterns
description: Choose between supervisor, peer-to-peer, and hierarchical agent patterns; plan context isolation, token economics, and consensus
author: Donal Moloney
when_to_use: when designing multi-agent systems, orchestrating parallel agents, or scaling beyond a single agent's context window
version: 1.0.0
---

# Multi-Agent Architecture Patterns

## Overview

One agent can't hold your entire codebase context. Multiple agents solve different pieces. But how do they coordinate?

**Core principle:** Choose an architecture pattern that matches your problem shape, then design for isolation and token efficiency.

## The Three Patterns

### Pattern 1: Supervisor (Hub-and-Spoke)

One agent orchestrates; others are specialists.

```
    Supervisor
    /  |  \
   /   |   \
  🔧  📝   🧪
(Code) (Docs) (Tests)
```

**Best for:**
- Clear orchestration point (user request → supervisor decides what to do)
- Asymmetric workflows (one agent coordinates many)
- Synchronous handoff (supervisor waits for results)

**Tradeoffs:**
- ✓ Simple coordination, clear control flow
- ✓ Supervisor can synthesize across agent results
- ✗ Supervisor becomes bottleneck
- ✗ All agents depend on supervisor's token budget
- ✗ Context loss at handoff boundaries

**Token economics:**
```
Supervisor: context(problem) + summary(agent-1) + summary(agent-2) + synthesis
Agent-1: context(subtask-1)
Agent-2: context(subtask-2)

Total = base + (agent-count × per-agent-context)
```

### Pattern 2: Peer-to-Peer (Broadcast)

Agents work independently, share state through messages.

```
🔧 ←→ 📝
 ↓ ↘ ↙ ↓
 🧪 ↔ State
```

**Best for:**
- Highly parallel work (agents don't need each other's results)
- Decentralized consensus (no single coordinator)
- Asynchronous/event-driven workflows

**Tradeoffs:**
- ✓ High parallelism (no bottleneck)
- ✓ Each agent works independently
- ✗ Coordination complexity (who decides when done?)
- ✗ State synchronization issues (conflicting updates)
- ✗ Telephone-game problem (each retelling loses context)

**Token economics:**
```
Each agent: context(full-problem) + view(other-agents-state)

Total = agent-count × full-context
(Much higher than supervisor pattern)
```

### Pattern 3: Hierarchical (Tree)

Agents form layers; each layer has specialists.

```
      Orchestrator
        /    \
    Layer-1  Layer-1
    /   \    /   \
  🔧   📝  🧪   🔍
```

**Best for:**
- Staged workflows (research → design → implement → test)
- Complexity stratification (higher layers = strategy, lower = tactics)
- Scaling deep problems (too big for any single layer)

**Tradeoffs:**
- ✓ Natural decomposition of complex problems
- ✓ Context isolation between layers
- ✗ Most complex to design
- ✗ Context loss at each layer boundary
- ✗ Cascading delays (layer N waits on N-1)

**Token economics:**
```
Per layer: context(layer-scope) + summarized-input(from-below)

Total = sum(layer-budgets) + boundary-loss
```

## Choosing Your Pattern

Ask these questions in order:

1. **Is there a clear orchestrator?** → Supervisor
2. **Can agents work fully independently?** → Peer-to-peer
3. **Is the problem naturally layered?** → Hierarchical
4. **None of the above?** → Hybrid (mix patterns)

## Context Isolation

**Problem:** Agent A's work shouldn't pollute Agent B's context.

**Solutions:**

**Supervisor pattern:**
- Pass summaries, not full context
- Supervisor distills: "Agent A found X; here's the key point"
- Agent B never sees Agent A's full output

**Peer-to-peer pattern:**
- Each agent gets a view of shared state (not everything)
- Use semantic search to find relevant state: "what did they learn about authentication?"
- Agents ignore noise

**Hierarchical pattern:**
- Each layer receives curated input from the layer below
- Layer N+1 doesn't see Layer N's scratch work, just conclusions

## Consensus Mechanisms

Multi-agent systems need agreement. Choose based on risk:

| Risk Level | Mechanism | Example |
|-----------|-----------|---------|
| **Low** | Single source of truth (supervisor decides) | Supervisor reviews and picks implementation |
| **Medium** | Majority vote | 3 agents design, pick most popular pattern |
| **High** | Unanimous consensus | Security code requires all agents to agree |
| **Critical** | Adversarial verify (devils-advocate) | Each agent argues against proposal |

## Anti-Patterns

❌ **Telephone game:** Agent A tells Agent B who tells Agent C → original intent lost
- Fix: Supervisor maintains context; agents reference it, don't re-transmit

❌ **Context duplication:** Every agent gets full problem context
- Fix: Use isolation patterns above; pass only what's needed

❌ **Undefined coordination:** Agents don't know when their work is done
- Fix: Explicit handoff points; supervisor (or message queue) signals completion

❌ **Unbounded token growth:** More agents = exponentially more tokens
- Fix: Design for isolation; budget carefully; use summaries

## Token Budget Planning

Before spawning agents, calculate:

```
per_agent_budget = (problem_context + interaction_overhead) / agent_count
total_budget = sum(all_per_agent_budgets) + synthesis_overhead

Example (Supervisor pattern):
- Problem context: 10k tokens
- 3 specialist agents: 3k tokens each
- Supervisor synthesis: 5k tokens
- Total: (10k + 3k + 3k + 3k) + 5k = 24k tokens
```

For peer-to-peer, budget higher (context duplication) or use semantic search to reduce it.

## Remember

- **Supervisor:** Simple, scalable, bottleneck-risk
- **Peer-to-peer:** Parallel, complex coordination, token-heavy
- **Hierarchical:** Natural decomposition, context loss at boundaries
- **Always:** Isolate context, budget tokens, define consensus
- **Never:** Let agents waste context by retelling everything
