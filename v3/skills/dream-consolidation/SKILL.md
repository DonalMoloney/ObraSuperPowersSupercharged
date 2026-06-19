---
name: dream-consolidation
description: Use as an overnight/idle pass between sessions — replays the day's traces, extracts recurring patterns, and rewrites memory into compressed schemas instead of raw logs.
tier: v3
status: experimental
---

# dream-consolidation

Raw logs are the brain's working buffer, not its long-term store. This skill is
the offline pass that turns a day of traces into reusable structure — sleep, not
note-taking.

**Replay (idle pass):** between sessions, re-read the day's traces — tool calls,
diffs, dead ends, fixes (described, not built). Rather than re-summarizing each
episode verbatim, sample across them and look for what *repeats*: the same
failure shape, the same file that always breaks first, the same three-step dance
that keeps working.

**Schema extraction:** distill recurring patterns into compressed schemas — a
schema is a generalization with slots, not a transcript. "When tests flake in
module X, it is almost always the fixture teardown" is a schema; the ten
individual flaky-test logs that produced it are discarded. The compression ratio
is the point: store the rule, drop the instances that taught it.

**Generative replay (REM-style):** to test a schema before committing it, replay
it generatively — imagine the next task it would apply to and check whether the
schema actually predicts the right move. Schemas that fail their own dream get
weakened or dropped; schemas that predict well get written into long-term memory.

**Boundary:** v3 `project-hippocampus` *stores and forgets* episodic memories
(situation → action → outcome) on an Ebbinghaus forgetting curve, replayed as a
next-session briefing. dream-consolidation is the consolidation pass that *writes
what project-hippocampus stores*: it reads many raw episodes and emits the
compressed schemas the hippocampus then keeps or decays. Hippocampus = episodic
store with a decay clock; dream-consolidation = the generative-replay /
schema-extraction step that feeds it. Reference it, do not duplicate it — one
holds episodes, the other manufactures the abstractions over them.

**Fitness signal:** next-day cold-start task score using the consolidated
schemas vs. the same task run against the raw, unconsolidated log. If schemas
beat raw logs on a held-out morning task, consolidation earned its keep;
if raw logs win, the dream pass is destroying signal and should be reverted.

## Why this might be crazy enough to work

Biological sleep does not archive the day — it compresses it, throwing away
instances to keep rules, and that lossy compression is *why* memory generalizes
instead of overfitting to yesterday. An offline pass that trades fidelity for
abstraction could give an agent the thing raw logs never do: transfer to tasks
it has not literally seen before.

## Known risks / absurdities

Schema extraction is hallucination with good PR — the dream may "discover" a
recurring pattern that was coincidence, then confidently delete the evidence
that would have disproved it. Generative-replay validation is itself a model
guessing whether a model's abstraction is right, so a confident-but-wrong schema
can pass its own dream and poison long-term memory irreversibly once the source
logs are gone. Keeping raw traces for a grace window before the dream is allowed
to delete them is probably mandatory.
