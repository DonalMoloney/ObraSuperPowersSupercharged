---
name: parallel-run-dashboard
description: Use when multiple parallel agents are running and you need live visibility into their status, token spend, partial results, and merge tree. Surfaces running / queued / done / failed state for every agent in a single dashboard view served over a local HTTP port.
author: Donal Moloney
track: A
---

## Not this skill if
- Only one agent is running — no fan-out means no dashboard value
- The run is already complete — use `merge-parallel-results` to consolidate finished output
- You need structured orchestration logic, not observation — use `wave-runner` or `map-reduce-sweep` to design the run first

# parallel-run-dashboard — live parallel-agent visibility

## Purpose

When an orchestrator fans out to multiple agents, progress becomes invisible unless you deliberately surface it. This skill starts and drives a lightweight, dependency-free dashboard that streams each agent's status, token spend, partial result, and position in the merge tree — all in real time, via Server-Sent Events with a polling fallback.

No build step, no npm install. Node >= 18 only.

## Core rule

> **Rule:** Start the dashboard before the first wave launches. An observation tool started after the run gives you history, not live progress.

## Steps

### 1. Confirm prerequisites

- Node >= 18 is available (`node --version`).
- The orchestrator writes (or can write) a JSON state file, or can call `POST /api/update`.
- Agree on a state-file path (default: `./state.json`) and port (default: `7878`). Record both so every process in the run uses the same values.

### 2. Start the dashboard server

```bash
node server.mjs --port 7878 --state ./state.json
# Parallel-Run Dashboard listening on http://localhost:7878
```

Open `http://localhost:7878` in a browser tab. Leave it open for the duration of the run.

### 3. Seed initial state (optional but recommended)

Write an initial `state.json` that lists every agent the orchestrator intends to launch, with `status: "queued"`. This makes the dashboard show the full scope from the start rather than agents appearing one by one.

```bash
node seed.mjs --once    # writes an example state; replace with your own shape
```

Or POST directly:

```bash
curl -s localhost:7878/api/update \
  -H 'content-type: application/json' \
  -d '{"agents":[{"id":"a1","label":"Researcher","status":"queued"},{"id":"a2","label":"Analyst","status":"queued"}]}'
```

### 4. Push updates from the orchestrator

Each agent or the orchestrator calls `POST /api/update` (or runs `node push.mjs`) as status changes. Minimum useful updates:

| Event | Push |
|---|---|
| Agent starts | `{"agent":{"id":"a1","status":"running"}}` |
| Token checkpoint | `{"agent":{"id":"a1","tokens":1400}}` |
| Partial result ready | `{"agent":{"id":"a1","result":"Found 12 documents"}}` |
| Agent completes | `{"agent":{"id":"a1","status":"done"}}` |
| Agent blocked / failed | `{"agent":{"id":"a1","status":"failed"}}` |
| Merge step starts | `{"merges":[{"into":"final","from":["a1","a2"]}]}` |

The dashboard recomputes totals and pushes a full-state SSE frame on every write. No polling needed on the browser side.

### 5. Watch the dashboard during the run

Monitor:

- **Status column** — any agent stuck in `running` longer than expected is a signal to investigate.
- **Token column** — agents spending far more tokens than peers may be looping or off-track.
- **Merge tree** — confirms which agents' outputs will flow into which consolidation step before the merge runs.
- **Event log** — checkpoint messages, gate firings, and custom notes from the orchestrator appear here in order.

If an agent shows `failed`, address it before the merge step it feeds. A failed input to a merge produces an incomplete consolidation.

### 6. Confirm completion before merge

Before invoking `merge-parallel-results` or the consolidation step:

1. Verify every required agent shows `done` in the dashboard.
2. Check that no agent feeding the merge tree shows `failed` or `running`.
3. Emit a checkpoint note: `node push.mjs --event '{"type":"note","message":"all agents done — starting merge"}'`

Attach a `PROVEN BY:` block to this checkpoint:

```
PROVEN BY: parallel-run-dashboard /api/state at <ts> — agents [a1, a2, a3] all status: done, 0 failed
```

### 7. Shut down

After the consolidation step completes, stop the server (`Ctrl-C` or kill the process). Archive `state.json` alongside the run output if a record of agent activity is needed.

## HTTP API reference

| Method and path | Description |
|---|---|
| `GET /` | The dashboard page |
| `GET /api/state` | Current run state as JSON |
| `GET /api/stream` | SSE stream; pushes full state on every change |
| `POST /api/update` | Merge a partial update into the state file |

## State shape (summary)

```jsonc
{
  "runId": "run-001",
  "agents": [
    { "id": "a1", "label": "Researcher", "status": "running", "tokens": 1200, "result": "..." }
  ],
  "merges": [{ "into": "final", "from": ["a1", "a2"] }],
  "totals": { "agentsRunning": 1, "totalTokens": 1200 }
}
```

Full schema: `v2/plugins/parallel-run-dashboard/state-schema.md`.

## Limitations

- Single state file, in-memory SSE client list — no database.
- No auth, no TLS. For local and CI orchestration only; not for public deployment.
- `merges` is replaced wholesale on each update, not merged element-wise.
- Event log is bounded to the last 500 entries.
- Single writer assumed — multiple independent server processes on the same file can race.

## Pitfalls

- Starting the dashboard after agents launch — you lose the early status transitions and token spend for agents that complete quickly.
- Not seeding a `queued` state for all agents up front — the dashboard appears to grow mid-run, making it harder to gauge overall progress.
- Forgetting to push `failed` status for a crashed agent — the dashboard shows it as `running` indefinitely, masking the problem.
- Skipping the pre-merge completion check — merging with a `failed` agent input silently drops that agent's findings.

## Integrates with

- [`orchestrate-feature`](../orchestrate-feature/SKILL.md): invoke this skill when orchestrate-feature fans out subagents; see the "Live progress" section there
- [`wave-runner`](../wave-runner/SKILL.md): wave-runner drives the fan-out; dashboard shows each wave's agents as they launch and complete
- [`map-reduce-sweep`](../map-reduce-sweep/SKILL.md): map-reduce-sweep fans out mappers and a reducer; push mapper status to the dashboard so the reduce step only starts when all mappers are done
