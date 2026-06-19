# autonomy-control (v4 plugin)

The **enforcement bundle** for partial-autonomy work. Three v4 skills already cover
the thinking; this plugin makes the decision *mechanical*.

```
policy            mechanism                 enforcement
─────             ─────────                 ───────────
autonomy-slider → permission-tiers      → autonomy-control PreToolUse hook
(which level)     (settings.json that      (blocks/warns at tool-call time,
                   makes the level real)    regardless of what the model remembers)
```

- **Policy — which level.** `autonomy-slider` declares the autonomy level (L0
  suggest-only → L3 full task), the selection criteria, and the downgrade triggers.
- **Mechanism — make the level real.** `permission-tiers` maps each level to a
  `settings.json` permission template (allowlists / permission modes).
- **Enforcement — make the level binding.** This plugin's `PreToolUse` hook reads the
  currently-declared level and gates every file-mutating tool call against it.

## Referenced skills (NOT vendored)

This plugin bundles three **standalone** v4 skills *by reference* — there is one
source of truth for each, at its own path:

| Skill | Repo path | Role |
|---|---|---|
| `autonomy-slider` | `v4/skills/autonomy-slider/SKILL.md` | Policy — declares which level the work gets. |
| `permission-tiers` | `v4/skills/permission-tiers/SKILL.md` | Mechanism — maps the level into `settings.json`. |
| `commit-checkpoints` | `v4/skills/commit-checkpoints/SKILL.md` | Rollback — frequent commits so any mid-work step is revertible. |

> The three skills remain fully usable on their own. The plugin's *net-new* value is
> only the enforcement hook below; it does not duplicate skill content.

## The net-new piece: a PreToolUse enforcement hook

`hooks/enforce-autonomy.sh` fires on `Edit | Write | MultiEdit` and resolves the
declared level, in order:

1. env var `CLAUDE_AUTONOMY`, else
2. a repo file `.claude/autonomy-level` (first non-blank line).

| Declared level | Behaviour |
|---|---|
| unset / empty | **Allow** (exit 0). Opt-in by default — the plugin does nothing until you declare a level. |
| `L0` (suggest-only) | **Block** (exit 2) with a clear "propose the diff, don't write" message. |
| `L1` (single-file diffs) | **Warn** (print a note), then allow (exit 0). |
| `L2` / `L3` | **Allow** (exit 0). |
| anything unrecognized | **Allow** (exit 0) with a fail-soft note. |

The hook is **fail-soft**: it drains stdin so it can never hang, and every path exits
0 except the one deliberate L0 block. False blocks are what get hooks uninstalled, so
the only thing it ever refuses is a write under an explicit L0 declaration.

### Declaring a level

```sh
# per-session, ad hoc:
export CLAUDE_AUTONOMY=L0      # suggest-only — writes will be blocked

# or per-repo, durable:
echo "L0" > .claude/autonomy-level
```

(`l0` lowercase works too; the hook normalizes case.)

## Why a plugin, not just a skill

A `PreToolUse` hook fires **mechanically** at tool-call time, regardless of what the
model remembers — Cherny's **hooks-as-enforcement** principle: prose in a skill is
advisory and can be forgotten under context pressure, a hook is deterministic. That is
what turns the declared autonomy level from a stated intention into a *binding*
constraint: at L0 the agent literally cannot write to disk, so "I'll just suggest the
change" is enforced by the session machinery rather than trusted to the model.

## Provenance

- **Karpathy — autonomy slider / partial autonomy** ("Software Is Changing (Again)",
  YC AI Startup School keynote, June 2025): autonomy is a dial the user tunes per task,
  with fast human verification loops keeping the agent on a leash. That supplies the
  *levels* (L0–L3) this plugin enforces — see `autonomy-slider`.
- **Boris Cherny — hooks-as-enforcement** (Claude Code best-practices, Apr 2025): make
  must-happen rules deterministic with hooks rather than relying on the model to
  remember them; settings.json allowlists / permission modes make permissions
  concrete. That supplies the *enforcement mechanism* — the `PreToolUse` gate here and
  the `settings.json` mapping in `permission-tiers`.

The plugin is the seam where Karpathy's *policy* (which level) meets Cherny's
*enforcement* (a hook that makes the level binding).

## Files

```
autonomy-control/
├── .claude-plugin/plugin.json
├── README.md
└── hooks/
    ├── hooks.json
    └── enforce-autonomy.sh
```
