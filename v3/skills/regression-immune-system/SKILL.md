---
name: regression-immune-system
description: Use whenever a bug is fixed — treats each fixed bug as an antigen, auto-synthesizes a minimal reproduction test (the antibody) into the suite as permanent immune memory, and tracks the reinfection rate of bug-classes toward zero.
tier: v3
status: experimental
---

# regression-immune-system

A bug fix that ships without a test is a recovery without immunity: the body
healed, but it can catch the same thing tomorrow. This skill makes every fix
mint an antibody, so the codebase remembers the pathogen.

**Antigen capture:** the moment a bug is confirmed and fixed, treat the failure
as an antigen with a fingerprint — the stack signature, the failing assertion,
the inputs that triggered it, and a *bug-class* label (e.g. "off-by-one in
pagination", "null-deref on empty config"). The fingerprint, not the exact
line, is what immunity is built against.

**Antibody synthesis:** auto-synthesize the *minimal* reproduction that turns
red on the pre-fix code and green on the fixed code, then inject it into the
suite as permanent immune memory — a test that exists forever specifically to
recognize this antigen's class again. Minimal matters: a bloated repro is an
antibody that mistakes friends for enemies (false positives) and gets deleted.

**Reinfection tracking:** every time a bug is captured, check its class
fingerprint against the immune-memory ledger. A *new* class is a first
infection. A class that already has an antibody is a **reinfection** — the
immune memory failed to catch it, which is the single most informative event
the system can record: either the antibody was too narrow, or the fix never
addressed the class. Reinfections trigger antibody-broadening, not just a new
test.

**Fitness signal (named, unmistakable):** the **reinfection rate** — the
fraction of newly-captured bugs whose class already had an antibody in immune
memory — trends to zero over time. It is binary per-bug (was this class seen
before: yes/no) and machine-countable from the ledger, no judge or rubric. A
falling reinfection rate means the immune system is learning the body's real
vulnerabilities faster than new ones appear; a flat or rising rate means the
antibodies are decorative.

**Boundary:** v3 `eval-suite-from-git` MINES git history into a scored
regression suite in *batch*, recovering (broken-state, test, fix) triples after
the fact. regression-immune-system is *real-time and per-fix*: it acts at the
moment of the fix and adds the reinfection metric, which history-mining has no
notion of. They are adjacent and composable — this skill's freshly-minted
antibodies are exactly the new bug-fix-plus-test commits that `eval-suite-from-git`
auto-promotes on its next harvest, so this skill can FEED that suite. It does
not duplicate the mining; it produces the input mining later consumes.

## Why this might be crazy enough to work

The biology metaphor is load-bearing, not decorative: an immune system's power
comes from cheap *memory of past attacks* plus a single scalar (reinfection
rate) that says whether the memory is working. Codebases already have the first
half — every fix is a confirmed pathogen — but they throw it away or file it as
an untracked test. By attaching a class fingerprint and counting recurrences,
the suite stops being a pile of tests and becomes a measurable defense whose
effectiveness you can watch converge. The reinfection metric is what turns
"we have tests" into "we are provably getting harder to re-break."

## Known risks / absurdities

The whole thing rests on **bug-class clustering**, which is the hard, fuzzy
part: too coarse a fingerprint and every null-deref is "the same class" so
reinfection rate is meaninglessly high; too fine and nothing ever counts as a
reinfection so it sits at a flattering zero forever. Auto-synthesized minimal
repros can be wrong — green for the wrong reason, or so minimal they no longer
exercise the real path. And a reinfection rate trending to zero might just mean
the team stopped finding bugs, or stopped labeling classes honestly to keep the
number pretty — the metric can be gamed by undercounting antigens, so it needs
to be read alongside raw bug-discovery volume.

## Likely graduation criteria (path to v2)

Promote to v2 when: (1) class fingerprinting is concrete and reproducible (same
bug → same class label across runs), with documented coarse/fine failure modes;
(2) antibody synthesis demonstrably produces minimal repros that are red pre-fix
and green post-fix on at least two real repos (reuse the round-trip admission
gate from `eval-suite-from-git`); (3) the reinfection-rate ledger is
deterministic and the metric is shown trending down across a real bug history
rather than asserted; and (4) the hand-off into `eval-suite-from-git` is
demonstrated end-to-end (a fix here appears as a promoted task there) without
duplicate antibodies. At that point rewrite to v2 standards (concrete commands,
pitfalls table, `PROVEN BY:` evidence) and move it.
