#!/usr/bin/env python3
"""lint-plan.py — check an implementation plan against writing-plans' own rules.

Option A — Plan linter (CC3): self-review becomes "run the linter, fix, rerun".
Lexical checks only — this tool cannot judge whether the code in a step is
*right*, only whether the plan keeps the format promises the skill makes.

Checks:
  header        H1 title, agentic-workers note, Goal / Architecture / Tech Stack
  tasks         at least one `### Task N:` heading; every task has checkbox steps
  checkboxes    `- [ ]` syntax intact; malformed or pre-checked boxes flagged
  files         every task declares a **Files:** block with exact, non-template paths
  placeholders  forbidden phrases from the skill's "No Placeholders" section
  codeblocks    code steps contain fenced code; run steps show command + Expected
  identifiers   cross-task identifier drift (clearLayers vs clearFullLayers)

Usage:
  python3 lint-plan.py PLAN.md [--strict]

  --strict   treat warnings as errors

Exit codes: 0 clean (warnings allowed unless --strict), 1 problems found, 2 usage/IO.
"""

import difflib
import re
import sys

# --- Patterns ----------------------------------------------------------------

TASK_RE = re.compile(r"^###\s+Task\s+(\d+)\s*[:.]?\s*(.*)")
STEP_RE = re.compile(r"^[-*]\s*\[([ xX])\]\s*(.*)")
MALFORMED_BOX_RE = re.compile(r"^([-*]\s*\[\](\s|$)|-\[[ xX]?\])")
FENCE_RE = re.compile(r"^(\s*)(`{3,}|~{3,})\s*(\S*)")
FILES_HEADER_RE = re.compile(r"^\*\*Files:?\*\*")
FILE_ENTRY_RE = re.compile(r"^\s*[-*]\s*(Create|Modify|Test|Delete|Move|Read)\s*:\s*(.*)", re.I)
HEADER_FIELDS = ("**Goal:**", "**Architecture:**", "**Tech Stack:**")
AGENTIC_NOTE_RE = re.compile(r"^>\s*\*\*For agentic workers", re.I)
TEMPLATE_PATH_RE = re.compile(r"(path/to|exact/path|some/path|<[^>]*>|\[[^\]]*\]|\.\.\.)")
TEMPLATE_FIELD_RE = re.compile(r"^\[.*\]$")

# Phrases the skill calls plan failures ("No Placeholders" section).
PLACEHOLDER_ERRORS = [
    (re.compile(r"\bTBD\b"), "placeholder 'TBD'"),
    (re.compile(r"\bTODO\b"), "placeholder 'TODO'"),
    (re.compile(r"\bFIXME\b"), "placeholder 'FIXME'"),
    (re.compile(r"\bimplement(?:ed)?\s+later\b", re.I), "placeholder 'implement later'"),
    (re.compile(r"\bfill in (?:the )?details\b", re.I), "placeholder 'fill in details'"),
    (re.compile(r"\badd appropriate \w+", re.I), "placeholder 'add appropriate ...'"),
    (re.compile(r"\badd validation\b", re.I), "placeholder 'add validation' (show the code instead)"),
    (re.compile(r"\bhandle edge cases\b", re.I), "placeholder 'handle edge cases' (name the cases, show the code)"),
    (re.compile(r"\bwrite tests? for the above\b", re.I), "placeholder 'write tests for the above' (include the test code)"),
    (re.compile(r"\bsimilar to task \d+\b", re.I), "placeholder 'similar to Task N' (repeat the code)"),
]

# Step-title classification (checked in order: commit, run, code).
COMMIT_TITLE_RE = re.compile(r"\bcommit\b", re.I)
RUN_TITLE_RE = re.compile(r"\b(run|rerun|re-run|execute|verify|confirm|check)\b", re.I)
CODE_TITLE_RE = re.compile(r"\b(write|implement|create|add|update|modify|refactor|define|extend|fix|delete|remove|rename)\b", re.I)

# Identifier extraction (only inside code fences whose language is code-like).
SKIP_LANGS = {
    "bash", "sh", "shell", "zsh", "console", "shell-session", "text", "txt",
    "output", "diff", "json", "yaml", "yml", "toml", "ini", "md", "markdown",
    "http", "csv", "plaintext", "",
}
DEF_PATTERNS = [
    re.compile(r"^\s*(?:async\s+)?def\s+([A-Za-z_]\w*)"),
    re.compile(r"^\s*(?:export\s+)?(?:abstract\s+)?class\s+([A-Za-z_$][\w$]*)"),
    re.compile(r"^\s*(?:export\s+)?(?:default\s+)?(?:async\s+)?function\s*\*?\s*([A-Za-z_$][\w$]*)"),
    re.compile(r"^\s*(?:export\s+)?(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*(?:async\s+)?(?:\(|[A-Za-z_$][\w$]*\s*=>|function\b)"),
    re.compile(r"^\s*(?:export\s+)?(?:interface|enum)\s+([A-Za-z_$][\w$]*)"),
    re.compile(r"^\s*(?:export\s+)?type\s+([A-Za-z_$][\w$]*)\s*="),
    re.compile(r"^\s*(?:pub(?:\([^)]*\))?\s+)?fn\s+([A-Za-z_]\w*)"),
    re.compile(r"^\s*func\s+(?:\([^)]*\)\s*)?([A-Za-z_]\w*)"),
    re.compile(r"^\s*(?:pub\s+)?(?:struct|trait)\s+([A-Za-z_]\w*)"),
]
REF_RE = re.compile(r"(?<![\w$])([A-Za-z_$][\w$]{2,})\s*\(")
DEF_KEYWORD_BEFORE_RE = re.compile(r"\b(def|function|fn|func)\s*$")
REF_STOPWORDS = {
    # control flow / language
    "if", "elif", "else", "for", "while", "switch", "match", "case", "return",
    "yield", "raise", "throw", "catch", "except", "with", "assert", "await",
    "not", "and", "or", "in", "is", "del", "lambda", "new", "super", "this",
    "self", "typeof", "instanceof", "sizeof", "defer", "import", "require",
    # common builtins
    "print", "println", "len", "range", "type", "str", "int", "float", "bool",
    "list", "dict", "set", "tuple", "repr", "hash", "iter", "next", "enumerate",
    "zip", "map", "filter", "sorted", "reversed", "sum", "min", "max", "abs",
    "round", "open", "input", "format", "isinstance", "issubclass", "getattr",
    "setattr", "hasattr", "vars", "console", "log",
    # test frameworks
    "describe", "it", "test", "expect", "beforeEach", "afterEach", "beforeAll",
    "afterAll", "fixture", "mock", "patch", "Mock", "MagicMock", "pytest",
    "assertEqual", "assertEquals", "assertTrue", "assertFalse", "assertRaises",
    "assertIn", "toBe", "toEqual", "toThrow",
}
MAX_IDENTIFIER_WARNINGS = 10


class Issue:
    def __init__(self, level, line, category, msg):
        self.level, self.line, self.category, self.msg = level, line, category, msg


def lint(path):
    try:
        with open(path, encoding="utf-8") as f:
            lines = f.read().splitlines()
    except OSError as e:
        print(f"plan-lint: cannot read {path}: {e}", file=sys.stderr)
        sys.exit(2)

    issues = []
    err = lambda n, cat, msg: issues.append(Issue("ERROR", n, cat, msg))
    warn = lambda n, cat, msg: issues.append(Issue("WARN", n, cat, msg))

    # --- Single pass: structure + fences ------------------------------------
    tasks = []          # {num, line, title, files_line, file_entries, steps}
    blocks = []         # {lang, start, task, step, lines: [(lineno, text)]}
    current_task = None
    current_step = None
    in_fence = False
    fence_char = fence_len = 0
    current_block = None
    first_nonblank = None
    first_task_line = None
    header_seen = {f: None for f in HEADER_FIELDS}
    agentic_note_line = None

    for n, raw in enumerate(lines, 1):
        if in_fence:
            m = FENCE_RE.match(raw)
            if m and m.group(2)[0] == fence_char and len(m.group(2)) >= fence_len and not m.group(3):
                in_fence = False
                blocks.append(current_block)
                current_block = None
            else:
                current_block["lines"].append((n, raw))
            continue

        m = FENCE_RE.match(raw)
        if m:
            in_fence = True
            fence_char, fence_len = m.group(2)[0], len(m.group(2))
            current_block = {"lang": m.group(3).lower(), "start": n,
                             "task": current_task, "step": current_step, "lines": []}
            if current_step is not None:
                current_step["fences"] += 1
            continue

        if first_nonblank is None and raw.strip():
            first_nonblank = (n, raw)

        # Placeholder phrases (prose; fenced content is scanned later too).
        for pat, msg in PLACEHOLDER_ERRORS:
            if pat.search(raw):
                err(n, "placeholders", msg)

        tm = TASK_RE.match(raw)
        if tm:
            current_task = {"num": tm.group(1), "line": n, "title": tm.group(2),
                            "files_line": None, "file_entries": [], "steps": []}
            tasks.append(current_task)
            current_step = None
            if first_task_line is None:
                first_task_line = n
            continue

        if first_task_line is None:
            if AGENTIC_NOTE_RE.match(raw):
                agentic_note_line = n
            for field in HEADER_FIELDS:
                if raw.startswith(field) and header_seen[field] is None:
                    header_seen[field] = (n, raw[len(field):].strip())

        if MALFORMED_BOX_RE.match(raw):
            err(n, "checkboxes", f"malformed checkbox {raw.strip()[:30]!r} — use exactly '- [ ] '")
            continue

        sm = STEP_RE.match(raw)
        if sm:
            if current_task is None:
                warn(n, "tasks", "checkbox step appears before any '### Task N:' heading")
                continue
            title = re.sub(r"\*\*", "", sm.group(2)).strip()
            current_step = {"line": n, "checked": sm.group(1) != " ",
                            "title": title, "body": [], "fences": 0}
            current_task["steps"].append(current_step)
            if current_step["checked"]:
                warn(n, "checkboxes", "step is pre-checked '- [x]' — fresh plans start unchecked")
            if not re.match(r"Step\s+\d+\s*:", title, re.I):
                warn(n, "checkboxes", f"step title {title[:40]!r} doesn't follow '**Step N: ...**'")
            continue

        if current_task is not None and FILES_HEADER_RE.match(raw):
            current_task["files_line"] = n
            current_step = None
            continue

        fm = FILE_ENTRY_RE.match(raw)
        if current_task is not None and current_step is None and fm:
            current_task["file_entries"].append((n, fm.group(1), fm.group(2).strip()))
            continue

        if current_step is not None:
            current_step["body"].append((n, raw))

    if in_fence:
        err(current_block["start"], "codeblocks", "unclosed code fence")
        blocks.append(current_block)

    # Placeholder phrases inside fences (TODO comments in plan code count too).
    for block in blocks:
        for n, text in block["lines"]:
            for pat, msg in PLACEHOLDER_ERRORS:
                if pat.search(text):
                    err(n, "placeholders", msg + " (inside code block)")

    # --- Header --------------------------------------------------------------
    if first_nonblank is None:
        err(1, "header", "file is empty")
    else:
        n, text = first_nonblank
        if not text.startswith("# "):
            err(n, "header", "plan must start with '# [Feature Name] Implementation Plan'")
        elif "implementation plan" not in text.lower():
            warn(n, "header", "H1 title doesn't end in 'Implementation Plan'")
    if agentic_note_line is None:
        err(1, "header", "missing '> **For agentic workers:** REQUIRED SUB-SKILL ...' note")
    for field in HEADER_FIELDS:
        seen = header_seen[field]
        if seen is None:
            err(1, "header", f"missing {field} line in plan header")
        else:
            n, value = seen
            if not value:
                err(n, "header", f"{field} has no content")
            elif TEMPLATE_FIELD_RE.match(value):
                err(n, "header", f"{field} still contains template text {value!r}")

    # --- Tasks, files, steps ---------------------------------------------------
    if not tasks:
        err(1, "tasks", "no '### Task N:' headings found — plan has no tasks")
    for t in tasks:
        label = f"Task {t['num']}"
        if t["files_line"] is None:
            err(t["line"], "files", f"{label} has no '**Files:**' block")
        elif not t["file_entries"]:
            err(t["files_line"], "files", f"{label} '**Files:**' block lists no Create/Modify/Test entries")
        for n, kind, value in t["file_entries"]:
            path = value.strip("`").strip()
            if not path:
                err(n, "files", f"{label} {kind}: entry has no path")
            elif TEMPLATE_PATH_RE.search(path):
                err(n, "files", f"{label} {kind}: path {path!r} looks like template residue — use the exact path")
            elif "/" not in path and "." not in path:
                warn(n, "files", f"{label} {kind}: path {path!r} is vague — exact file paths always")

        if not t["steps"]:
            err(t["line"], "checkboxes", f"{label} has no '- [ ]' checkbox steps")
        for s in t["steps"]:
            body_text = "\n".join(text for _, text in s["body"])
            fence_text = "\n".join(
                text for b in blocks if b["step"] is s for _, text in b["lines"])
            where = f"{label} step {s['title'][:40]!r}"
            if COMMIT_TITLE_RE.search(s["title"]):
                if s["fences"] == 0 and "git " not in body_text:
                    err(s["line"], "codeblocks", f"{where}: commit step shows no git command")
            elif RUN_TITLE_RE.search(s["title"]) and not CODE_TITLE_RE.search(s["title"]):
                if s["fences"] == 0 and not re.search(r"\bRun\s*:", body_text, re.I):
                    err(s["line"], "codeblocks", f"{where}: run step shows no command ('Run: ...' or code block)")
                if not re.search(r"\bExpect(ed|s)?\b", body_text + fence_text, re.I):
                    warn(s["line"], "codeblocks", f"{where}: run step states no expected output")
            elif CODE_TITLE_RE.search(s["title"]):
                if s["fences"] == 0:
                    err(s["line"], "codeblocks",
                        f"{where}: code step has no code block — show the code, don't describe it")

    # --- Cross-task identifier consistency -------------------------------------
    defined = {}     # name -> (task_num, line)
    referenced = {}  # name -> (task_num, line)
    for block in blocks:
        if block["lang"] in SKIP_LANGS:
            continue
        tnum = block["task"]["num"] if block["task"] else "?"
        for n, text in block["lines"]:
            defs_on_line = set()
            for pat in DEF_PATTERNS:
                dm = pat.match(text)
                if dm:
                    name = dm.group(1)
                    defs_on_line.add(name)
                    defined.setdefault(name, (tnum, n))
            for rm in REF_RE.finditer(text):
                name = rm.group(1)
                if name in defs_on_line or name in REF_STOPWORDS:
                    continue
                if DEF_KEYWORD_BEFORE_RE.search(text[:rm.start()]):
                    continue
                referenced.setdefault(name, (tnum, n))

    id_warnings = 0
    norm = lambda s: s.lower().replace("_", "")
    # (a) two *definitions* that normalize to the same name but are spelled differently
    by_norm = {}
    for name in defined:
        by_norm.setdefault(norm(name), []).append(name)
    for variants in by_norm.values():
        if len(variants) > 1 and id_warnings < MAX_IDENTIFIER_WARNINGS:
            spots = ", ".join(f"'{v}' (Task {defined[v][0]}, L{defined[v][1]})" for v in sorted(variants))
            warn(min(defined[v][1] for v in variants), "identifiers",
                 f"same identifier spelled differently across tasks: {spots}")
            id_warnings += 1
    # (b) references with no definition but a near-miss defined name
    lower_to_def = {d.lower(): d for d in defined}
    for name, (tnum, n) in sorted(referenced.items(), key=lambda kv: kv[1][1]):
        if name in defined or not defined or id_warnings >= MAX_IDENTIFIER_WARNINGS:
            continue
        close = difflib.get_close_matches(name.lower(), list(lower_to_def), n=1, cutoff=0.8)
        if close and close[0] != name.lower():
            d = lower_to_def[close[0]]
            dt, dl = defined[d]
            warn(n, "identifiers",
                 f"Task {tnum} calls '{name}' which is never defined; Task {dt} (L{dl}) "
                 f"defines '{d}' — same thing? (identifier drift)")
            id_warnings += 1

    return issues


def main(argv):
    strict = "--strict" in argv
    args = [a for a in argv if a != "--strict"]
    if len(args) != 1 or args[0] in ("-h", "--help"):
        print(__doc__.strip(), file=sys.stderr)
        return 2
    path = args[0]
    issues = lint(path)
    issues.sort(key=lambda i: (i.line, i.level))
    for i in issues:
        print(f"{i.level:<5} L{i.line:<5} [{i.category}] {i.msg}")
    errors = sum(1 for i in issues if i.level == "ERROR")
    warns = sum(1 for i in issues if i.level == "WARN")
    print(f"plan-lint: {path}: {errors} error(s), {warns} warning(s)"
          + (" [--strict]" if strict else ""))
    if errors or (strict and warns):
        return 1
    print("plan-lint: OK — lexically clean. The linter cannot judge whether the "
          "code in each step is right; that part is still on you.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
