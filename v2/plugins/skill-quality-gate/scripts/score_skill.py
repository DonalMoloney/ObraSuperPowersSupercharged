#!/usr/bin/env python3
"""score_skill.py — mechanical quality scorer for a SKILL.md in this repo.

Two independent passes, mirroring the two embedded skills:

  STRUCTURAL (skill-quality-validator) — does the file have the right shape for
    its tier? required frontmatter fields, valid YAML block, body sections.
  CONTENT (skill-evaluator) — is the prose ship-ready? description phrasing,
    name format, size budget, at least one concrete example, no placeholders.

This repo's skills are markdown reference docs, NOT Python packages, so none of
the upstream factory checks (README.md / GUIDE.md / *.py / type hints) apply.
The rubric is the one in ../standards/skill-standards.md.

Usage:
  python3 score_skill.py <path-to-SKILL.md>
  python3 score_skill.py --json <path-to-SKILL.md>
  python3 score_skill.py --quiet <path-to-SKILL.md>   # only exit code, no stdout

Exit codes:
  0  score >= threshold (default 80)
  1  score <  threshold
  2  file missing / unreadable / not a SKILL.md
"""
import json
import os
import re
import sys

THRESHOLD = int(os.environ.get("SQG_THRESHOLD", "80"))


def tier_for(path):
    """Infer the tier from the path: v1/<name>/, v2/skills|plugins/..., etc."""
    m = re.search(r"(?:^|/)(v[1-5])/", path.replace("\\", "/"))
    return m.group(1) if m else None


def split_frontmatter(text):
    """Return (frontmatter_dict_of_raw_strings, body) or (None, text)."""
    if not text.startswith("---"):
        return None, text
    end = re.search(r"\n---[ \t]*\n", text[3:])
    if not end:
        return None, text
    fm_raw = text[3:3 + end.start()]
    body = text[3 + end.end():]
    fm = {}
    key = None
    for line in fm_raw.splitlines():
        m = re.match(r"^([A-Za-z0-9_-]+):[ \t]*(.*)$", line)
        if m:
            key = m.group(1)
            fm[key] = m.group(2).strip()
        elif key and (line.startswith(" ") or line.startswith("\t")):
            # YAML block-scalar / folded continuation
            fm[key] = (fm[key] + " " + line.strip()).strip()
    return fm, body


def strip_quotes(v):
    return v.strip().strip('"').strip("'").lstrip(">|+-").strip()


# ---------------------------------------------------------------------------
# STRUCTURAL pass (skill-quality-validator)
# ---------------------------------------------------------------------------

def structural_checks(path, fm, body, tier):
    checks = []

    def add(name, points, ok, fix):
        checks.append({
            "id": len(checks) + 1, "name": name, "points": points,
            "awarded": points if ok else 0, "passed": ok,
            "fix": None if ok else fix,
        })

    # S1: valid frontmatter block with name + description
    has_fm = fm is not None
    has_name = bool(fm and fm.get("name"))
    has_desc = bool(fm and fm.get("description"))
    add("frontmatter_block", 20, has_fm and has_name and has_desc,
        "SKILL.md needs a `---` frontmatter block with non-empty `name` and `description`.")

    # S2: name matches its directory (kebab) — directory is parent of SKILL.md
    dirname = os.path.basename(os.path.dirname(os.path.abspath(path)))
    name_val = strip_quotes(fm.get("name", "")) if fm else ""
    add("name_matches_dir", 15, bool(name_val) and name_val == dirname,
        f"Frontmatter `name` ({name_val or 'missing'}) must equal the directory name ({dirname}).")

    # S3: tier-specific required fields
    tier_fix = "Unrecognized tier path; place the skill under v1..v5."
    tier_ok = False
    if tier == "v1":
        # v1 keeps upstream frontmatter shape; tier proof lives in the body
        tier_ok = "## Supercharged vs upstream" in body
        tier_fix = "v1 skills MUST contain a `## Supercharged vs upstream` section (CLAUDE.md tier rules)."
    elif tier == "v2":
        tier_ok = (fm or {}).get("tier") == "v2" and bool((fm or {}).get("supports"))
        tier_fix = "v2 skills require `tier: v2` and a `supports:` field naming the v1 skill(s) supported."
    elif tier == "v3":
        tier_ok = (fm or {}).get("tier") == "v3" and (fm or {}).get("status") == "experimental"
        tier_fix = "v3 skills require `tier: v3` and `status: experimental`."
    elif tier == "v4":
        tier_ok = (fm or {}).get("tier") == "v4" and bool(
            (fm or {}).get("inspiration") or (fm or {}).get("inspired-by") or (fm or {}).get("cites"))
        tier_fix = "v4 skills require `tier: v4` and an `inspiration:`/`cites:` field naming the originator + idea."
    elif tier == "v5":
        tier_ok = True  # v5 is import-only, no tier discipline
        tier_fix = ""
    add("tier_fields", 20, tier_ok, tier_fix)

    # S4: body has at least one ## heading (real structure, not a stub)
    add("has_section_headings", 10, len(re.findall(r"^##+\s", body, re.M)) >= 1,
        "Body needs at least one `##` section heading.")

    return checks


# ---------------------------------------------------------------------------
# CONTENT pass (skill-evaluator)
# ---------------------------------------------------------------------------

RESERVED_NAME_PREFIXES = ("anthropic-", "claude-")
PLACEHOLDERS = ("TODO", "TBD", "FILL:", "PLACEHOLDER", "[fill", "[todo", "coming soon")


def content_checks(path, fm, body, tier):
    checks = []

    def add(name, points, ok, fix):
        checks.append({
            "id": len(checks) + 1, "name": name, "points": points,
            "awarded": points if ok else 0, "passed": ok,
            "fix": None if ok else fix,
        })

    desc = strip_quotes(fm.get("description", "")) if fm else ""
    name_val = strip_quotes(fm.get("name", "")) if fm else ""

    # C1: description begins with "Use when" (the CSO trigger phrase)
    add("description_trigger", 15, desc.lower().startswith("use when"),
        'Description must begin with "Use when" and state the triggering condition (v1 writing-skills CSO).')

    # C2: description states WHEN, does not just summarize the workflow.
    # Heuristic: must contain a when-ish signal and stay under ~500 chars.
    when_signal = bool(re.search(r"\b(when|before|after|if|while)\b", desc, re.I))
    add("description_when_not_what", 10, when_signal and len(desc) <= 500,
        "Description should state WHEN to use the skill (triggers/symptoms), in third person, under 500 chars.")

    # C3: name is kebab-case, < 64 chars, no reserved prefix
    name_ok = (
        bool(name_val)
        and re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name_val) is not None
        and len(name_val) < 64
        and not name_val.startswith(RESERVED_NAME_PREFIXES)
    )
    add("name_format", 10, name_ok,
        "Name must be kebab-case, under 64 chars, no reserved prefix (anthropic-/claude-).")

    # C4: SKILL.md under 500 lines (token-efficiency budget)
    nlines = body.count("\n") + 1
    add("size_under_500_lines", 15, nlines <= 500,
        f"SKILL.md body is {nlines} lines; keep it under 500 (split heavy reference into a sibling file).")

    # C5: at least one concrete example — a fenced code block or a "## Example"
    has_example = bool(re.search(r"```", body)) or bool(re.search(r"^##+.*\bexamples?\b", body, re.I | re.M))
    add("has_example", 10, has_example,
        "Include at least one concrete example: a fenced code block or a `## Example(s)` section.")

    # C6: ends in a verification / proof / checklist loop
    feedback = bool(re.search(
        r"(?im)(PROVEN BY|## Verification|## Review checklist|## After|verification-before-completion|\bverify\b)",
        body))
    add("feedback_loop", 15, feedback,
        "End with a feedback loop: a `## Verification` / `## Review checklist` section or a `PROVEN BY:` block.")

    # C7: no placeholder / unfinished text
    lowered = body.lower()
    found = [p for p in PLACEHOLDERS if p.lower() in lowered]
    add("no_placeholders", 10, not found,
        f"Remove unfinished placeholder text: {', '.join(found)}." if found else "")

    # C8: consistent skill-vs-tier terminology (heuristic — flag obvious drift)
    # A v2 skill that calls itself "v3" or names no supported v1 skill is drift.
    drift = False
    if tier == "v2" and fm:
        drift = ("tier: v3" in str(fm.get("tier", "")) or "tier: v4" in str(fm.get("tier", "")))
    add("consistent_terms", 5, not drift,
        "Tier/terminology drift: frontmatter tier disagrees with the folder it lives in.")

    return checks


def score(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
    except Exception as e:  # noqa: BLE001
        return {"error": f"cannot read {path}: {e}", "exit": 2}

    if os.path.basename(path) != "SKILL.md":
        return {"error": f"not a SKILL.md: {path}", "exit": 2}

    fm, body = split_frontmatter(text)
    tier = tier_for(path)

    structural = structural_checks(path, fm, body, tier)
    content = content_checks(path, fm, body, tier)
    all_checks = [dict(c, pass_type="structural") for c in structural] + \
                 [dict(c, pass_type="content") for c in content]

    total = sum(c["points"] for c in all_checks)
    awarded = sum(c["awarded"] for c in all_checks)
    pct = round(awarded * 100 / total) if total else 0
    fixes = [c["fix"] for c in all_checks if not c["passed"] and c.get("fix")]

    return {
        "skill_path": path,
        "tier": tier,
        "score": pct,
        "threshold": THRESHOLD,
        "passing": pct >= THRESHOLD,
        "structural": structural,
        "content": content,
        "fixes": fixes,
        "exit": 0 if pct >= THRESHOLD else 1,
    }


def human(report):
    lines = []
    verdict = "PASS" if report["passing"] else "FAIL"
    lines.append(f"{report['skill_path']}  {report['score']}/100  {verdict} "
                 f"(threshold {report['threshold']}, tier {report['tier'] or '?'})")
    for label, key in (("structural", "structural"), ("content", "content")):
        lines.append(f"  [{label}]")
        for c in report[key]:
            mark = "PASS" if c["passed"] else "FAIL"
            lines.append(f"    {mark} {c['name']:<24} {c['awarded']}/{c['points']}")
    if report["fixes"]:
        lines.append("  fixes:")
        for fx in report["fixes"]:
            lines.append(f"    - {fx}")
    return "\n".join(lines)


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    flags = {a for a in argv[1:] if a.startswith("--")}
    if not args:
        print(__doc__.strip().splitlines()[0], file=sys.stderr)
        return 2
    report = score(args[0])
    if "error" in report:
        if "--quiet" not in flags:
            print(report["error"], file=sys.stderr)
        return report["exit"]
    if "--json" in flags:
        out = {k: v for k, v in report.items() if k != "exit"}
        print(json.dumps(out, indent=2))
    elif "--quiet" not in flags:
        print(human(report))
    return report["exit"]


if __name__ == "__main__":
    sys.exit(main(sys.argv))
