---
name: devils-advocate
description: Use for any important claim that tests cannot mechanically prove — a design conclusion, research finding, or "this is the root cause" assertion — spin up N independent agents whose only job is to disprove it; if a quorum succeeds, the claim dies.
author: Donal Moloney
tier: v2
supports: [receiving-code-review, verification-before-completion]
type: process
---

## Not this skill if
- The claim is already mechanically proven by passing tests (v1 **verification-before-completion**) — refutation adds little
- Trivial or low-stakes claim
- You are attacking a spec or design as a whole with parallel adversarial agents and need the concrete parallel execution shape (claim atomization, batch-sizing N skeptics under a concurrency cap, blind independence, survivor-set assembly) → v2 **red-team-spec** is the canonical executable form; this skill is the conceptual framing.

# devils-advocate — refute before you trust

## Purpose

Stop plausible-but-wrong claims (especially research and design conclusions, which test-based verification (v1 verification-before-completion) cannot
test) from surviving by default. Any claim that hasn't faced an adversarial challenge is a liability;
this skill forces that challenge before the claim propagates downstream.

## Core rule

> **Rule:** Reviewers are prompted to *refute*, defaulting to "refuted" under uncertainty. The claim
> survives only if fewer than the quorum succeed.

## Triggers

**Use when:**
- A research conclusion, benchmark result, or design decision is about to be accepted and acted on
- You catch yourself or a teammate saying "this seems right" without having tested the opposite
- A design review produced consensus too quickly — no one argued the other side
- An architecture choice, threat model, or feasibility claim will gate downstream work
- A claim can't be mechanically tested (no executable test exists) but the cost of being wrong is high
- You need more than one lens: correctness, reproducibility, security, scalability, user impact

**Don't use when:**
- The claim is already covered by a passing test suite — run the tests and capture evidence per v1 **verification-before-completion** instead
- The claim is low-stakes and rework is cheap — inline skepticism is enough
- You need the full parallel execution harness with concurrency caps and survivor-set assembly — use v2 **red-team-spec**

## The pattern

```
claim
  └─ Refuter-1 (correctness lens)   → verdict: refuted | survived
  └─ Refuter-2 (security lens)      → verdict: refuted | survived
  └─ Refuter-3 (reproducibility)    → verdict: refuted | survived
                    ↓
              quorum vote
                    ↓
        survived → record surviving tensions
        killed   → rework + re-challenge
```

Dispatch N independent refuters via v1 **dispatching-parallel-agents**. Each refuter receives the claim text
and a single assigned lens. Refuters do not share intermediate findings — independence is the
mechanism that prevents groupthink.

## Algorithm

Spawn N independent agents (via v1 **dispatching-parallel-agents**), each tasked to disprove the claim, ideally
from a distinct lens (correctness, security, does-it-reproduce). **Quorum/majority vote** decides
survival; pick N for the trust level needed.

## Steps

### Step 1 — State the claim crisply

Write the claim as a single falsifiable sentence. Avoid compound claims; split them first. A good
claim has a clear subject, a predicate, and an implicit or explicit scope:

- Weak: "The architecture is solid."
- Strong: "The proposed event-driven pipeline handles 10 k events/sec with p99 < 50 ms under sustained load."

If the claim can't be stated in one falsifiable sentence, rewrite it until it can. A claim that
can't be falsified can't be refuted — and that's the problem, not the solution.

### Step 2 — Assign lenses and dispatch N refuters

Choose N based on trust level required:

- N = 2 for medium-stakes claims (one correctness, one alternative-hypothesis lens)
- N = 3 for high-stakes claims (correctness, security/adversarial, reproducibility)
- N = 5 for critical claims or contested decisions (add scalability and user-impact lenses)

Assign each refuter a distinct lens from this set (or invent domain-specific lenses):

| Lens | Prompt framing |
|---|---|
| Correctness | "Find any logical flaw, missing assumption, or counter-example that breaks this claim." |
| Security / adversarial | "Find any attack surface, misuse path, or threat scenario the claim ignores." |
| Reproducibility | "Find any reason this result would not hold on a different dataset, environment, or date." |
| Scalability | "Find any load, size, or throughput boundary at which the claim stops being true." |
| User impact | "Find any user segment, edge case, or workflow where this claim harms rather than helps." |

Dispatch via v1 **dispatching-parallel-agents**. Pass each refuter the claim text and its assigned lens only.
Do not share the other refuters' partial findings — independence is the mechanism that prevents
convergence on a shared blind spot.

### Step 3 — Collect verdicts and apply the quorum rule

Each refuter must return one of two verdicts:

- **refuted** — the refuter found a credible counter-argument, counter-example, or evidence gap
- **survived** — the refuter attempted in good faith and could not break the claim under its lens

Default is **refuted** under uncertainty: if the refuter is unsure, it returns refuted, not survived.
This asymmetry is intentional — it is cheaper to re-examine a claim that actually holds than to ship
a claim that was quietly wrong.

Apply the quorum rule once all verdicts are in:

- **Quorum reached (majority refuted):** claim is killed; route back to rework.
- **Quorum not reached (majority survived):** claim survives this round; record the surviving counter-arguments in the refutation record
  before routing downstream.
- **Tie:** treat as quorum reached — the benefit of the doubt belongs to skepticism.

### Step 4 — Record verdicts, route, and document

Regardless of outcome, record:

- The exact claim text
- N, the lenses used, and each verdict with a one-sentence justification
- The quorum threshold used and whether it was reached
- The final decision: survived or killed

If killed, attach the strongest refutation argument to the rework record so the author knows what
to address — don't just say "rejected."

If survived, append the surviving tensions (the arguments the claim did not fully defeat) to the refutation record so they travel with the claim.

## Pitfalls

| ❌ Mistake | ✅ Fix |
|---|---|
| Refuters share findings mid-run | Keep refuters isolated; dispatch independently and collect only final verdicts |
| Default verdict is "survived" under uncertainty | Default must be "refuted" — uncertainty is a signal of insufficient evidence, not safety |
| Compound claim sent to refuters | Split into atomic falsifiable sentences first; one claim per run |
| N = 1 for a high-stakes decision | Use at least N = 3 for anything that gates downstream work; a single refuter has a single blind spot |
| Discarding counter-arguments on survival | Survivors still carry unresolved tension; record it in the refutation record |
| Killing a claim without attaching the strongest refutation | Author needs to know what to fix; always attach the best counter-argument to the rework record |

## Proof

Done once the quorum decision and any surviving tensions are recorded.

The output must contain:

- The exact claim text (verbatim, not paraphrased)
- N, the list of lenses assigned, and each refuter's verdict with a one-sentence justification
- The quorum threshold (e.g., "majority of 3") and whether it was reached
- The final decision: survived or killed
- If survived: the unresolved tensions recorded alongside the claim
- If killed: the strongest refutation argument attached for rework

```
REFUTATION RECORD:
  claim: "<exact claim text>"
  N: <number of refuters>
  lenses: [<lens-1>, <lens-2>, ...]
  verdicts: [<refuted|survived>, ...]
  quorum: <threshold> — <reached|not reached>
  decision: <survived|killed>
  strongest_refutation: "<text, or 'n/a — claim survived'>"
  surviving_tensions: "<text, or 'n/a — claim killed'>"
```

## Adapt from
- Quorum/voting + evidence-gating pattern from **`moonrunnerkc/swarm-orchestrator`**.
  <https://github.com/moonrunnerkc/swarm-orchestrator>
