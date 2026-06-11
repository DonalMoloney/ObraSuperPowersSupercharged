---
name: ghost-run
description: Use as an optional gate between writing-plans and executing-plans — hallucinate the entire plan execution into a ghost transcript first, then halt real execution wherever reality diverges from the prediction.
tier: v3
status: experimental
---

# ghost-run

A surprised plan is a wrong plan. Before executing any multi-step plan:

1. **Simulate:** a simulator agent steps through every plan item and writes a
   ghost transcript — concretely *predicting* what each command will output,
   which files will conflict, where tests will fail, what each diff will look
   like. The predictions must be specific enough to be wrong.
2. **Execute with a tripwire:** during real execution, diff reality against
   the ghost at each step. Small divergences (line numbers, timing) pass.
   Divergence beyond threshold — a command failing that the ghost passed, a
   file the ghost didn't know existed, a test failing differently — HALTS
   execution.
3. **Diagnose before resuming:** a halt means the world-model that wrote the
   plan is wrong somewhere. Update the understanding (and usually the plan)
   before continuing. The halt fires *before* the misunderstanding compounds.

## Why this might be crazy enough to work

The value isn't in the simulation being right — it's that
divergence-from-prediction is a cheap, automatic "your model of this codebase
is wrong, stop" tripwire, and it fires at the first symptom instead of three
broken steps later.

## Known risks / absurdities

The ghost is generated from the same flawed world-model that wrote the plan,
so they may share every blind spot — the diff then catches only trivia while
radiating false confidence. Threshold tuning is also unsolved: too tight and
every run halts on noise, too loose and the tripwire never fires.
