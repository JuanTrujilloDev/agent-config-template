---
name: update-config
description: "Upgrade a project rendered by agent-config-template to the current version: plan the config changes, migrate old docs/specs/ folders to docs/epics/, apply only what the user approves by number, commit on a chore/ branch."
argument-hint: "[path to the template or plugin root]"
disable-model-invocation: true
---

# update-config

Brings an existing render up to date without a silent overwrite. `TEMPLATE` below is the template checkout or plugin root that holds `setup.sh` (the argument, else ask).

## 1. Detect

Read `agent-config.lock.json` (template version, hosts, per-file SHA) and `answers.env` at the project root. If either is missing, stop: this project was never rendered, or was rendered before v0.9.2; point the user to `/setup-template`. Print one line: `installed <lock version> → template <TEMPLATE version>`.

If `answers.env` still has `workflow_mode`, `use_gherkin` or `enforce_layer_split`, say once that v0.11 retired them (tests always come first, slices are always layered, Gherkin tags are gone), that the renderer ignores them, and offer to delete the lines.

## 2. Plan the config

```bash
bash "$TEMPLATE/setup.sh" --target . --answers answers.env
```

With an existing config and no mode this writes nothing and prints one line per differing file. Collect them into a table:

| Label | Meaning | Default |
| --- | --- | --- |
| `STALE-MANAGED` | template file you never edited | overwrite |
| `CUSTOMIZED-MANAGED` | template file you edited | keep; never touched by this skill |
| `CUSTOMIZED` | yours by design (`CLAUDE.md`, `docs/CONTEXT.md`, `docs/design-system/`) | keep; reconcile by hand |
| `LEGACY` | no baseline to compare | ask; if the user confirms the files are unedited template output, `--merge --legacy` records them as baselines |
| `OBSOLETE` | file the template no longer ships, unedited | prune |
| `CUSTOMIZED-OBSOLETE` | dropped file you edited | keep; never touched by this skill |

## 3. Plan the specs

When `docs/specs/` exists:

```bash
python3 .claude/skills/update-config/migrate.py
```

It prints one row per slug: `done` specs are archived verbatim to `docs/epics/archive/<slug>/`; `open` specs are archived and also get `docs/epics/<slug>/epic.md` and `slices/<id>.md` (stories start as `TODO`, the TS lines keep the scenario text). Use the copy under `$TEMPLATE` when the project does not have the skill yet.

## 4. Confirm

One numbered list: config paths to overwrite, obsolete paths to prune, LEGACY paths to decide, specs to migrate, and these manual steps:

- **`UserPromptSubmit` cleanup**: `--prune` drops the settings hook entry of every file it prunes (v0.10's `coding-reminder.sh`). Without `--prune`, or when `coding-reminder.sh` is `CUSTOMIZED-OBSOLETE`, offer to delete that entry from `.claude/settings.json` by hand.
- **`CUSTOMIZED CLAUDE.md` reconcile**: v0.11 rewrote the Workflow, Agents and Commands sections of `CLAUDE.md`; diff it against a fresh render (`setup.sh --target <tmp> --answers answers.env`) and fold those sections in. It is always loaded, so a stale copy points at dropped agents and commands.

The user answers by number (`approve 1-4, 7`); anything unanswered is skipped. Never overwrite silently. `CUSTOMIZED` and `CUSTOMIZED-*` paths are never offered for overwrite; list them so the user can reconcile by hand.

## 5. Apply

On a `chore/update-agent-config` branch (never the default branch):

```bash
bash "$TEMPLATE/setup.sh" --target . --answers answers.env --merge --overwrite-files <approved,paths> [--prune]
python3 .claude/skills/update-config/migrate.py --apply <approved slugs>
python3 .claude/skills/epic/validate-epics.py docs/epics
```

`--prune` only when the user approved pruning; it removes unchanged `OBSOLETE` files, their lock entries and any `settings.json` hook that runs them. Then do the approved manual steps (hook entry, `CLAUDE.md`). `--merge` deep-merges `.claude/settings.json` and refreshes the lock for the files it wrote. Paste each command's output. A second run of `migrate.py` must report every slug as `skip (migrated)`.

## 6. Commit

`chore(config): update agent-config-template to v<version>`, listing overwritten, pruned and migrated paths in the body. Push and PR stay gated: ask first. Restart the host so it loads the new config.
