---
name: project-hippocampus
description: Use via session start/end hooks — consolidates each session into episodic memories and replays the relevant ones as a briefing next time the same area is touched, with a forgetting curve.
tier: v3
status: experimental
---

# project-hippocampus

Episodic memory for a project, with biology's garbage collector.

**Consolidation (session end):** write 3–5 episodes to a memory directory
(described, not built). Each episode is situation → action → outcome, with
concrete file paths and an emotional valence tag (`frustrating`, `smooth`,
`surprising`). Episodes are small, dated, and specific.

**Recall (session start):** retrieve episodes relevant to the current task and
inject a one-paragraph briefing: "last time we touched this area, X happened,
we did Y, it went Z." The briefing is context, not instruction.

**Forgetting curve:** unrecalled episodes lose detail over sessions — they get
summarized down, then merged, then dropped. Recalled episodes get reinforced
and re-detailed. This Ebbinghaus mechanic is the point: the store cleans
itself, and what survives is what keeps being relevant.

## Why this might be crazy enough to work

The decay-unless-recalled mechanic is a self-cleaning filter that solves
memory's real failure mode — not forgetting, but drowning in stale notes —
using nothing but periodic re-summarization.

## Known risks / absurdities

Retrieval is keyword-grade without embeddings, so the hippocampus may
confidently brief you about the wrong "last time," and a false memory presented
as a briefing is worse than no memory. Valence tags could also bias work
("dread" episodes making Claude avoid files that were fixed long ago).
