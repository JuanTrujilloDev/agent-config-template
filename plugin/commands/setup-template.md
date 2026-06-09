---
description: Render the full agent-config-template into the current project. Reads project files, infers placeholder values, asks for approval, then writes a calibrated `.claude/` tree + CLAUDE.md.
---

# /agent-config-template:setup-template

Render the full template into the current project — same flow as cloning the repo and running `setup.sh` manually, but driven by Claude inside the project. After running, the project has a fully-calibrated `.claude/` tree and `CLAUDE.md` tuned to its specific stack, test command, branch convention, and toggles.

This is the **opt-in calibration step** for users who installed the plugin and want more than the generic defaults. The agents, hooks, skills, and slash commands you got from `/plugin install` continue to work exactly the same — `/setup-template` just adds a project-root `.claude/` tree with project-specific configuration.

## What this command does

1. **Inspects the current project.** Reads `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `requirements.txt`, `manage.py`, `setup.cfg`, top-level `README.md`, and the source layout.

2. **Drafts an `answers.env`** at the project root with one `KEY=VALUE` per placeholder defined in `${CLAUDE_PLUGIN_ROOT}/template.config.yaml`. Each value is classified by confidence:
   - **HIGH** — derived directly from a config file (cite the file).
   - **LOW** — best guess; show the alternative.
   - **UNKNOWN** — left blank with a `# TODO: <what's missing>` line above.

3. **Shows the draft to the user**, grouped by confidence level, and **WAITS for approval or edits.** Do not run the renderer until the user explicitly approves with "yes," "go," "render," or equivalent.

4. **After approval, runs the renderer.** The renderer is **non-destructive**: against a project that already has a Claude config it writes nothing and prints a per-file change plan until you pass an explicit mode.
   ```bash
   # Fresh project (no existing .claude/ or root CLAUDE.md) — writes directly:
   bash "${CLAUDE_PLUGIN_ROOT}/setup.sh" --target . --answers ./answers.env

   # Existing config — run with no mode first to show the user the change plan
   # (writes nothing, exits 1), then apply with one of:
   #   --merge      add missing files, deep-merge .claude/settings.json, keep your other files
   #   --overwrite  replace template-managed files (settings.local.json is never touched)
   #   --abort      do nothing (the default)
   bash "${CLAUDE_PLUGIN_ROOT}/setup.sh" --target . --answers ./answers.env --merge
   ```
   For a project that already has config, default to `--merge`. Only use `--overwrite` when the user explicitly wants the template versions to win, and only after they've seen the plan.

5. **Adds to `.gitignore`** (creating it if missing):
   ```
   .claude/settings.local.json
   .claude/mcp.json
   answers.env
   ```

6. **Reminds the user** that Claude Code needs to be restarted to pick up the new project-root hooks and slash commands. The plugin-level commands and agents remain available regardless.

## Hard rules

- **Do not invent placeholder values.** If a value is genuinely ambiguous, leave it UNKNOWN and ask one targeted clarifying question — don't guess.
- **Wait for explicit approval** before invoking `setup.sh`. The draft step is not optional.
- **Don't modify anything outside `answers.env`, `.claude/`, `CLAUDE.md`, and `.gitignore`.**
- **Never overwrite an existing config silently.** The renderer now enforces this — against an existing `.claude/` tree (or root `CLAUDE.md`) it writes nothing without an explicit `--merge`/`--overwrite`. Run it once with no mode to show the user the per-file plan, then let them choose. `.claude/settings.local.json` is never touched. If both root `CLAUDE.md` and `.claude/CLAUDE.md` exist with different content, the renderer warns — surface that to the user and ask which is canonical.

## Honor conditional questions (`when:` clauses)

`template.config.yaml` lists each placeholder with an optional `when:` clause that gates whether the variable applies. **Honor those clauses strictly** — both in the questions you ask and in the `answers.env` you write.

Concrete rules:

- **`mcp_plane_workspace` and `mcp_plane_host`** — only ask, only include in `answers.env`, only render related sections **if `ticket_tracker = Plane`**. For any other tracker, omit these lines entirely from the draft (don't include them as blank lines or commented placeholders). The renderer's mustache conditionals will skip the Plane-related blocks automatically because the synthetic flag `ticket_tracker_plane` won't be set.
- **`frontend_framework` and `frontend_dir`** — only ask if `has_frontend = yes`. If the project is API-only, omit both lines from `answers.env`. The renderer drops files marked `<!-- requires: has_frontend -->` (e.g., `frontend-dev` agent, `frontend-style` rule).
- **`has_e2e` and `enforce_layer_split`** — only ask if `has_frontend = yes`. Skip entirely for API-only projects.

The general rule: **if a `when:` clause isn't satisfied, the variable doesn't exist for this project.** Don't ask, don't write, don't display in the confidence-grouped draft. This keeps the conversation tight and the rendered output clean.

## Variant: just-go mode

If the user prefixes the command with explicit phrasing like *"setup, just go"* or passes `--auto`, skip the approval gate and run with the inferred values directly. Useful for throwaway projects, dangerous on real ones — the user is taking responsibility for any wrong inferences.

## What gets rendered

A full `.claude/` tree calibrated to the project:

- **`CLAUDE.md`** at the project root — principles, branch rules, agent map, dynamic context section, all referencing the project's actual test/lint/format commands and source dirs.
- **`.claude/HELP.md`** — decision tree + worked examples customized for the stack.
- **`.claude/settings.json`** — permissions tightened around the project's actual tools.
- **`.claude/mcp.json.example`** — MCP server template.
- **`.claude/rules/principles.md`**, **`backend-style.md`**, optional **`frontend-style.md`** — operating principles + style guides tailored to the stack.
- **`.claude/agents/`** — the same agents as the plugin (plus `mutation-tester` when `enforce_mutation_testing=yes`), with placeholders rendered to specifics (e.g., `backend-dev` references the project's actual test command).
- **`.claude/commands/`** — the slash commands (`/spec`, `/feature`, `/fix`, `/verify`, `/audit`, `/commit`, `/pr`, `/design`, …), locally available (non-namespaced).
- **`.claude/hooks/`** — branch discipline, agent gating, auto-format — with the project's actual `src_dir` / `default_branch` baked in (no env-var fallback needed).

## Relationship to the plugin

After `/setup-template`, both layers are active:

| Layer | Source | Naming |
|---|---|---|
| Plugin commands/agents | `${CLAUDE_PLUGIN_ROOT}/...` | Namespaced (`/agent-config-template:feature`) |
| Project commands/agents | `./.claude/...` | Unnamespaced (`/feature`) |

The project-root versions take precedence when names collide. This is intentional — the project versions have the calibrated test commands, branch prefixes, and toggles baked in.

## Pre-filled examples

If the user wants to skip inference entirely and use a known-good preset, point them at `${CLAUDE_PLUGIN_ROOT}/examples/` (when present). Common stacks: `python-fastapi`, `python-django`, `node-express`, `node-nextjs`. They can copy one and run `setup.sh` directly without going through inference.

## Troubleshooting

- **`setup.sh: command not found`** — the plugin didn't ship the bundled template. Reinstall: `/plugin update agent-config-template@juantrujillodev`.
- **Missing `python3`** — `setup.sh` requires Python 3. Install it (it's preinstalled on macOS and most Linux).
- **`.git/index.lock` errors when committing afterward** — leftover from a crashed git process. Run `rm -f .git/index.lock` and retry.
- **"Existing Claude config detected … Nothing was written" (exit 1)** — expected, not an error. The project already has a config. Re-run with `--merge` (recommended) or `--overwrite` after the user has reviewed the printed plan.
