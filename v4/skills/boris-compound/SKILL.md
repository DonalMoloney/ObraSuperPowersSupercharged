---
name: boris-compound
description: Use right after fixing a bug, recovering from a failure, or learning something the hard way — capture the lesson as one small interlinked markdown note so it compounds and can't recur; also use to recall prior lessons before starting related work
tier: v4
inspiration: "Cherny — capture every correction so future sessions start with better context (Claude Code team tips, Threads, late 2025); storage follows Karpathy's LLM-Wiki interlinked-notes pattern (X, April 2026)"
pairs-with: [cognitive-prosthetics]
---

# Boris Compound

**Not this skill if:**

- You need the *map* of LLM cognitive deficits and their standing compensations → **v4 cognitive-prosthetics**. That skill names anterograde amnesia as a deficit and "write durable notes" as the prosthetic; this skill is the concrete write-format for one slice of that prosthetic — mistake-derived lessons — not a replacement for the broader map.
- You need broad, always-loaded project context or standing instructions → the host environment's `MEMORY.md` / `memory/` convention. That is the cache that loads every session; this store is the searchable archive you pull from on demand.
- You are debugging the failure that is happening *right now* → **v1 systematic-debugging**. Log the lesson here only *after* the fix lands and the verifier is green.

## The compounding rule

Every correction is a one-time tax unless it is written down — then it is a permanent dividend. The moment a fix-after-failure lands (a test went red then green, an error is now gone, a wrong assumption was caught), write exactly one note. Not later, not "if it matters" — now, while the root cause is still in the context window.

A lesson that lives only in this conversation evaporates when the window resets. A lesson written as a small, interlinked note is recalled by the next session that searches for it.

## Note format

One lesson = one file at `learnings/<slug>.md`, kebab-case slug. No subfolders — the store stays flat so links and search stay simple.

```markdown
---
slug: parser-eats-trailing-comma
tags: [parser, json]
date: 2026-06-13
---

# Parser silently drops trailing commas

**Symptom:** valid configs with a trailing comma parsed to the wrong shape, no error.
**Root cause:** the tokenizer treated `,}` as `}` instead of erroring.
**Fix:** reject `,}` / `,]` in `tokenize()`; test in `test_parser.py::test_trailing_comma`.
**Rule going forward:** any lenient parser change needs a malformed-input test. See [[config-loader-swallows-errors]].
```

Rules for a good note:

- **Atomic** — one lesson per file. If you are tempted to write "and also...", that is a second note.
- **Interlinked** — reference related lessons with `[[other-slug]]` wiki-links in the body. Links are what turn a pile of notes into a wiki.
- **Actionable** — every note ends in a *Rule going forward* line: what to do differently next time, not just what happened.
- **Has the receipt** — name the file/test/command that proves the fix, so the lesson is verifiable, not just remembered.

## Commands (stock tools only — no extra scripts to install)

Run from the project root.

**Log** a lesson:

```bash
mkdir -p learnings
cat > learnings/<slug>.md   # paste the note in the format above
```

**Recall** before related work — search the store first, every time:

```bash
grep -rli "<keyword>" learnings/ 2>/dev/null      # files mentioning the keyword
grep -rn "\[\[" learnings/ 2>/dev/null            # follow the wiki-links between them
```

**Regenerate the index** (Karpathy's auto-maintained INDEX) — one bullet per note, so the store is browsable at a glance:

```bash
{
  echo "# Learnings index"
  echo
  for f in learnings/*.md; do
    [ "$f" = "learnings/INDEX.md" ] && continue
    title=$(grep -m1 '^# ' "$f" | sed 's/^# //')
    slug=$(basename "$f" .md)
    echo "- [[$slug]] — ${title:-$slug}"
  done
} > learnings/INDEX.md
```

**Lint** — surface broken `[[links]]` (a wiki-link to a slug with no file):

```bash
for link in $(grep -rho '\[\[[^]]*\]\]' learnings/ | sed 's/\[\[//;s/\]\]//' | sort -u); do
  [ -f "learnings/$link.md" ] || echo "broken link: [[$link]]"
done
```

## Recall discipline

Before starting work in an area you have touched before, `grep` the store and read the hits. The whole point of compounding is that the second encounter with a class of bug is cheaper than the first — that only happens if you look before you leap.

When a lesson becomes load-bearing for everyday work, promote a pointer to it from `MEMORY.md` (e.g. `see learnings/<slug>.md`) so it loads automatically instead of needing a search.

## Provenance

- **Idea (Cherny — the practice):** After any correction, capture it durably so future sessions start with better context rather than repeating the mistake. Boris Cherny, sharing tips sourced from the Claude Code team: update `CLAUDE.md` whenever Claude does something wrong, and "one engineer maintains a notes directory per task, updated after every PR, with `CLAUDE.md` pointing at it." This is the verification-loop instinct applied to memory — never re-pay a cost you already paid once.
- **Where stated (Cherny):** Boris Cherny, "I'm Boris and I created Claude Code... a few tips for using Claude Code, sourced directly from the Claude Code team," Threads, late 2025 (threads.com/@boris_cherny/post/DUMZr4VElyb); verified via web search, June 2026.
- **Idea (Karpathy — the storage shape):** Treat knowledge as something to *compile over time like code*, not retrieve on demand: a flat set of LLM-maintained markdown pages, one concept per page, pages cross-linked with `[[wikilinks]]`, plus an auto-maintained index — the "LLM Wiki" pattern.
- **Where stated (Karpathy):** Andrej Karpathy, "LLM Wiki" pattern, popularized April 2026 (gist.github.com/karpathy/442a6bf555914893e9891c11519de94f); verified via web search, June 2026.
- **Attribution honesty:** the term *compounding engineering* was coined by Kieran Klaassen / Every, not by Cherny — Cherny's contribution this skill builds on is the underlying practice (capture corrections so they apply automatically), which his team tips state directly. The two ideas are deliberately separated above per the v4 one-tool-one-idea rule.
- **How this tool operationalizes it:** It fuses the two — Cherny's *when* (write the lesson the instant a fix-after-failure lands) with Karpathy's *how* (one flat atomic markdown note per lesson, `[[wiki-linked]]`, with a regenerated `INDEX.md` and a link-lint) — into a runnable log/recall/index/lint loop that uses only stock shell tools, so a corrected mistake becomes a searchable, interlinked note instead of a cost paid twice.
