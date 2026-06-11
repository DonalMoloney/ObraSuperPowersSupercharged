---
name: memory-systems-design
description: Design persistent semantic memory architecture; choose between vector stores, knowledge graphs, and temporal memory based on access patterns
author: Donal Moloney
when_to_use: when agents need to remember across sessions, recall similar problems, or consolidate learning over time
version: 1.0.0
---

# Memory Systems Design

## Overview

Agents need to remember. But how? Raw transcripts grow unbounded. Semantic memory lets you find what matters.

**Core principle:** Match memory storage to access patterns; consolidate aggressively.

## Three Memory Architectures

### Architecture 1: Vector Store (Semantic Similarity)

Embed everything as vectors; search by semantic meaning.

```
Session transcript → Chunk → Embed → Store in vector DB
                                        ↓
Query: "How do we handle auth?" → Embed → Search → Find similar memories
```

**Best for:**
- "What did we learn about X?"
- Cross-session pattern recall ("we solved similar before")
- Semantic search (not keyword match)

**Storage:**
- Pinecone, Weaviate, Milvus, local FAISS
- Each memory: (text, embedding, metadata, timestamp)

**Access pattern:**
```typescript
// "Find memories about authentication across 100 sessions"
results = vectorDB.search(
  embedding("how do we handle auth?"),
  filters: { topic: "security" },
  topK: 5
);
```

**Tradeoffs:**
- ✓ Fast semantic search
- ✓ Handles fuzzy matching ("auth" finds "login", "session tokens")
- ✗ Embedding cost (API calls, latency)
- ✗ Hard to update (re-embed on changes)
- ✗ Loses structure (flat similarity search)
- ✗ No temporal reasoning (similar ≠ causality)

**Cost & latency:**
```
Per embedding: 0.01-1ms (local) to 50-200ms (API)
Per search: 1-50ms
Storage: ~100 bytes per memory (text) + 1-4KB per vector
```

### Architecture 2: Knowledge Graph (Structured Relationships)

Nodes = concepts; edges = relationships. Query by path.

```
Session → Extract concepts → Build graph

Session A:                  Session B:
┌─ API Auth ──┐           ┌─ JWT ──┐
│   └─ JWT ───┼──────────→│   └─ verify ─┐
│   └─ Sessions ─┐        │              │
└─────────────┘ │        └──────────────┘
              ↓
         Merged Graph
```

**Best for:**
- "What leads to API Auth?"
- "What breaks when JWT expires?"
- Multi-hop reasoning ("A causes B; B affects C")

**Storage:**
- Neo4j, Amazon Neptune, ArangoDB
- Each memory: (entity, type, relationships, properties)

**Access pattern:**
```
// "How do authentication failures propagate?"
MATCH (problem:Issue) -[:CAUSED_BY]-> (auth:Auth) -[:AFFECTS]-> (impact:Impact)
RETURN problem, auth, impact
```

**Tradeoffs:**
- ✓ Captures causality and relationships
- ✓ Multi-hop reasoning
- ✓ Update-friendly (add edges, don't re-embed)
- ✗ Harder to populate (requires extraction logic)
- ✗ Slower queries (especially deep traversals)
- ✗ Explodes in size with many relationships
- ✗ Maintenance burden (keep graph consistent)

**Cost & latency:**
```
Per memory: 10-100ms to extract and insert
Per query: 10-500ms (depends on depth)
Storage: Compact; scales to millions of nodes
```

### Architecture 3: Temporal Memory (Time-Aware Consolidation)

Store decisions + outcomes + lessons learned at decision points. Forget implementation details.

```
Session A (Day 1): Decided to use Redis for caching
              → Outcome: Cache hits = 70%
              → Lesson: "Redis effective for 70% hot-path"

Session B (Day 5): Decided to refactor authentication
              → Outcome: 2 security bugs found
              → Lesson: "Auth refactors need adversarial review"

Memory = { decision, rationale, outcome, lesson, timestamp }
```

**Best for:**
- "What did we try and what happened?"
- "What lessons have we learned?"
- Avoiding repeated experiments

**Storage:**
- Log-structured (immutable append)
- Timeline: { timestamp, decision, rationale, outcome, lesson, confidence }

**Access pattern:**
```
// "Have we tried caching strategies before?"
timeline.query(
  when: last-30-days,
  what: "caching",
  outcome: ["success", "failed"]
)
→ Returns: all caching decisions + results
```

**Tradeoffs:**
- ✓ Simple to populate (just log decisions)
- ✓ Temporal reasoning ("we tried that in Q3, it didn't work")
- ✓ Confidence tracking (tried X times, succeeded Y%)
- ✗ Limited to what was explicitly logged
- ✗ Outcomes may not be known immediately
- ✗ Requires periodic consolidation (or grows forever)

**Cost & latency:**
```
Per memory: 1-2ms (append)
Per query: 10-100ms (scan timeline)
Storage: Extremely compact; just text + metadata
```

## Choosing Your Architecture

| Question | Answer | Use |
|----------|--------|-----|
| Need to find "similar past problems"? | Yes | Vector store |
| Need to reason about relationships? | Yes | Knowledge graph |
| Need to know "what happened and why"? | Yes | Temporal memory |
| Multiple apply? | Use all three | Hybrid |

## Consolidation Strategy

**Problem:** Sessions accumulate; memory grows unbounded.

**Solution:** Periodically consolidate (weekly/monthly):

1. **Vector store:** Delete old embeddings; keep high-value summaries
2. **Knowledge graph:** Prune low-degree nodes; merge similar entities
3. **Temporal memory:** Archive old decisions; keep only lessons learned

**Consolidation example:**
```
Raw timeline (100 sessions over month):
- Session 1: Tried caching with Redis
- Session 2: Tried caching with Memcached
- Session 3: Tried caching with in-memory
- ...
- Session 100: Caching is 70% effective

Consolidated lesson:
"Caching effectiveness: 70% hit rate. Tried 3 backends; Redis and Memcached similar perf. In-memory too limited for dataset size."
```

## Hybrid Design (Recommended)

Use all three for different purposes:

```
Temporal memory (decisions & outcomes)
         ↓
    Consolidate → Lessons learned
         ↓
Vector store (semantic search for lessons)
         ↓
Knowledge graph (relationships between concepts)
```

**Access flow:**
1. User asks: "How do we handle auth?"
2. Vector store finds similar past memories
3. Knowledge graph shows how auth relates to other concerns
4. Temporal memory shows what was tried and what worked

## Privacy & Consolidation

**Risk:** Raw session transcripts contain sensitive data.

**Solution:** Consolidate aggressively; delete raw transcripts.

```
Raw session transcript (keep 7 days):
  [Full conversation with sensitive diffs, API keys, etc.]

Consolidated memory (keep forever):
  "Session focused on authentication. Tried JWT revocation. Learned: immediate revocation is critical for security."
  
Discard: Raw transcript after 7 days
```

## Remember

- **Vector store:** "Find similar"
- **Knowledge graph:** "Why and how are they connected?"
- **Temporal memory:** "What did we try and what happened?"
- **Consolidate:** Aggressively; forget raw details; keep lessons
- **Hybrid:** Use all three for comprehensive memory
