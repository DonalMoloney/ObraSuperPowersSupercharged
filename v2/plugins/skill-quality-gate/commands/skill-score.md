---
description: Score a SKILL.md against this repo's structural + content quality rubric and print the pass/fail breakdown with concrete fixes
---

Score the SKILL.md the user names (or, if none is named, the most recently edited one) against the skill-quality-gate rubric:

1. Resolve the target path. If the user gave a skill directory, append `/SKILL.md`. If they gave nothing, ask which skill, or score the SKILL.md most recently changed in `git status`.
2. Run the scorer:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/score_skill.py" <path-to-SKILL.md>
   ```
   Add `--json` if you need the structured object, or `--quiet` to get only the exit code in a script.
3. Report the breakdown verbatim: overall score / 100, PASS or FAIL against the threshold (default 80, override with `SQG_THRESHOLD`), and both passes — `[structural]` (skill-quality-validator) and `[content]` (skill-evaluator) — with each check's awarded points.
4. If the verdict is FAIL, list every fix line and name the responsible embedded skill: structural failures route to v2 skill-quality-validator, content failures to v2 skill-evaluator. Static-clean does not mean behaviorally correct — point the user to v2 skill-test-harness for behavioral proof before merge.
