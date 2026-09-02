---
description: Render the full agent-config-template into the current project. Infers the whole placeholder profile from project files, asks one numbered round of decisions (with recommended defaults), then writes a calibrated `.claude/` tree + CLAUDE.md.
---

# /agent-config-template:setup-template

Render the full template into the current project — same flow as cloning the repo and running `setup.sh` manually, but driven by Claude inside the project. After running, the project has a fully-calibrated `.claude/` tree and `CLAUDE.md` tuned to its specific stack, test command, branch convention, and toggles.

This is the **opt-in calibration step** for users who installed the plugin and want more than the generic defaults. The agents, hooks, skills, and slash commands you got from `/plugin install` continue to work exactly the same — `/setup-template` just adds a project-root `.claude/` tree with project-specific configuration.

## What this command does

The interview is **infer → show → ask once → record → render**. Facts are read from the project and never asked; only decisions reach the user, in one numbered round.

1. **INFER.** Read `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `requirements.txt`, `manage.py`, `setup.cfg`, top-level `README.md`, CI config, the source/test layout, `git branch -a`, and any existing `answers.env` (a prior render's values are HIGH, source `answers.env`). Draft a value for **every** placeholder in `${CLAUDE_PLUGIN_ROOT}/template.config.yaml` whose `when:` clause holds, tagged by confidence:
   - **HIGH** — derived directly from a file (cite it: `pyproject.toml [tool.ruff]`, `.github/workflows/ci.yml`, …). Never asked.
   - **LOW** — best guess with a named alternative. Goes to the round.
   - **UNKNOWN** — no signal. Goes to the round with no recommendation; if it stays unanswered it is written blank with a `# TODO: <what's missing>` line above.
   - **default** — no project signal, the `template.config.yaml` default is fine. Not asked unless it changes what renders (see the round).

   Host signals: `claude` always; add `cursor` when a `.cursor/` directory exists; add `codex` when Codex project config exists (`.codex/` or `.agents/`). Tracker signals: `.github/` → GitHub; Jira/Linear/Plane keys in branch names or issue templates → that tracker.

2. **SHOW the inferred profile** as one table — every applicable placeholder with its value, confidence tier, and cited source:

   | Placeholder | Value | Confidence | Source |
   |---|---|---|---|
   | `language` | Python | HIGH | `pyproject.toml` |
   | `test_cmd` | `pytest -q` | HIGH | `pyproject.toml [tool.pytest]` |
   | `ticket_tracker` | GitHub | LOW | `.github/` exists; alt: Linear |
   | `line_length` | 100 | default | template default |
   | `branch_prefix` | — | UNKNOWN | no ticket ids in `git branch -a` |

   Personal prefs already present in `.claude/answers.local.env` appear tagged `recorded` and are not re-asked (the user edits that file to change them); `companions=not_now` is the exception — it is asked again on every run. A recorded comma list (e.g. `companions=graphify,ponytail`) is tagged `recorded` and not re-asked; tools omitted from that list were skipped by omission and are not re-recommended. Likewise, policy decisions already present in `answers.env` (`workflow_mode`, `TARGET_HOSTS`) appear tagged `recorded` (source `answers.env`) and are not re-asked — round items 1–2 are listed only when their value is absent.

3. **ASK one frontier round.** Below the table, list **all** currently-answerable decision questions, numbered, each with a recommended answer. Facts (stack, dirs, commands, versions) are never in the round. The round contains:

   1. `workflow_mode` — `SDD` or `SDD+TDD`. Recommended: `SDD` (`SDD+TDD` when the project already has a substantial test suite and CI running it).
   2. Target hosts — multi-select `claude`, `cursor`, `codex` (`grok` = claude tree + AGENTS.md). Recommended: the inferred set from step 1; the user may add or drop any.
   3. `autonomy_mode` — `gated` or `autonomous`. Recommended: `gated` (today's behavior: pause before each micro-commit; `autonomous` skips that pause — push/merge/publish/destructive confirms ALWAYS apply regardless of mode).
   4. Companions — three groups, one answer. **Core quality:** graphify (knowledge graph behind `code-query`) + ponytail (runtime minimal-code enforcement). **Output:** the native `concise` output style is already on by default — nothing to install. **UI:** ui-ux-pro-max (design-system skill) — listed only when `has_ui` is truthy; omit the whole UI group when `has_ui` is falsy. Answer `[Yes / Not now / Never / <comma list>]`. Recommended: `Not now`. When every tool recommended for this project is already installed (`command -v graphify`; `claude plugin list` contains `ponytail@ponytail`; `.claude/skills/ui-ux-pro-max/` exists, when `has_ui`), skip this question **and step 8**, and leave any existing `companions` key untouched.
   5. … every LOW placeholder (recommended = the best guess, alternative named), every UNKNOWN (no recommendation — say which signal is missing), and any `default`-tagged item that changes what renders (`has_frontend`, `ticket_tracker`, `has_background_jobs`, `use_gherkin`, `enforce_mutation_testing`).

   End with: *"Reply `all defaults` (or `go`) to accept every recommendation and render, or answer by number — `1: SDD+TDD, 4: Never`. Unanswered numbers take the recommendation."* That reply is the approval gate: it resolves the whole round and authorizes the render — **do not run `setup.sh` before it arrives.**

   A **second round happens only when an answer unlocks new `when:`-gated questions** (`ticket_tracker: Plane` → `mcp_plane_workspace`, `mcp_plane_host`; `has_frontend: yes` → `frontend_framework`, `frontend_dir`, `has_e2e`, `enforce_layer_split`). It lists only those, same format, and its reply is the approval — in that case the round-1 reply is not yet the approval; nothing renders until the final round's reply. UNKNOWN items still unanswered after the round stay blank with their `# TODO` line — say so in one line before rendering; never fill them with a guess.

4. **RECORD** the resolved answers in their scopes (table below):
   - **`answers.env`** at the project root — one `KEY=VALUE` per applicable placeholder, including `workflow_mode=…` and `TARGET_HOSTS=<comma-separated list>` (the renderer defaults to `claude` when the line is absent; `setup.sh --host` overrides it). Project policy, committed.
   - **`.claude/answers.local.env`** (`mkdir -p .claude`; create or update, preserving other keys) — `autonomy_mode=gated|autonomous` and `companions=yes|not_now|never|<comma list>` — `yes` = all recommended for this project; a comma list (e.g. `graphify,ponytail`) installs only those and the rest are skipped by omission and not re-recommended; `not_now` = asked again next run; `never` = suppress every mention. Personal, gitignored, read at session time by hooks and command instructions. **Never write these two keys to `answers.env`, and never pass this file to the renderer** — it is not a placeholder source.

5. **RENDER.** The renderer is **non-destructive**: against a project that already has a Claude config it writes nothing and prints a per-file change plan until you pass an explicit mode.
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

6. **Adds to `.gitignore`** (creating it if missing):
   ```
   .claude/settings.local.json
   .claude/mcp.json
   .claude/answers.local.env
   ```
   `answers.env` is **committed** — never gitignore it. It is project policy and
   the source of truth for reproducible re-renders (`setup.sh --answers
   ./answers.env --merge`; see `docs/upgrade-guide.md`). Personal preferences go
   in the gitignored `.claude/answers.local.env` instead.

7. **Reminds the user** that Claude Code needs to be restarted to pick up the new project-root hooks and slash commands. The plugin-level commands and agents remain available regardless.

8. **Companions**, per the `companions` value recorded **this run** (a value recorded on an earlier run does not re-trigger this step):
   - `yes` — run the `/setup-companions` flow now. It detects what is already installed and has its own confirmation gate; that gate is kept even in just-go mode — nothing installs without it.
   - `<comma list>` (e.g. `graphify,ponytail`) — run `/setup-companions <list>` now; it installs exactly those and keeps its own confirmation gate.
   - `not_now` — mention once (don't push): `/setup-companions` installs the optional companion tools — graphify (knowledge graph behind the `code-query` skill), ponytail (runtime minimal-code enforcement) and, when `has_ui`, ui-ux-pro-max (design-system skill).
   - `never` — say nothing about companions, this run and every future run (the recorded value also skips question 4).

## Config scopes

Every config value lives in exactly one of three scopes:

| Scope | File | Committed? | Holds |
|---|---|---|---|
| Project policy | `answers.env` | yes | `workflow_mode`, `TARGET_HOSTS`, micro-PR limits — everything in `template.config.yaml` |
| Local prefs | `.claude/answers.local.env` | no (gitignored) | personal settings read at session time (`autonomy_mode`, `output_style` = `concise|balanced|detailed|terse`, default `concise`, `agent_style` = `terse|descriptive`, default `terse` — both not asked in the round, `companions`) — never rendered into files |
| Session keywords | — | never persisted | one-session overrides like "just go" / "gate me" |

## Hard rules

- **Do not invent placeholder values.** If a value is genuinely ambiguous, leave it UNKNOWN and ask one targeted clarifying question for it inside the frontier round — don't guess.
- **Ask decisions, never facts.** Anything a project file answers is inferred, cited, and shown — not asked.
- **Wait for explicit approval** before invoking `setup.sh`. The reply that resolves the frontier round is that approval; without it, nothing renders.
- **Personal prefs stay personal.** `autonomy_mode` and `companions` go only to `.claude/answers.local.env` — never into `answers.env`, never into rendered files.
- **Don't modify anything outside `answers.env`, `.claude/`, `CLAUDE.md`, and `.gitignore`.**
- **Never overwrite an existing config silently.** The renderer now enforces this — against an existing `.claude/` tree (or root `CLAUDE.md`) it writes nothing without an explicit `--merge`/`--overwrite`. Run it once with no mode to show the user the per-file plan, then let them choose. `.claude/settings.local.json` is never touched. If both root `CLAUDE.md` and `.claude/CLAUDE.md` exist with different content, the renderer warns — surface that to the user and ask which is canonical.

## Honor conditional questions (`when:` clauses)

`template.config.yaml` lists each placeholder with an optional `when:` clause that gates whether the variable applies. **Honor those clauses strictly** — in the profile table, in the frontier round, and in the `answers.env` you write.

Concrete rules:

- **`mcp_plane_workspace` and `mcp_plane_host`** — only ask, only include in `answers.env`, only render related sections **if `ticket_tracker = Plane`**. For any other tracker, omit these lines entirely from the draft (don't include them as blank lines or commented placeholders). The renderer's mustache conditionals will skip the Plane-related blocks automatically because the synthetic flag `ticket_tracker_plane` won't be set.
- **`frontend_framework` and `frontend_dir`** — only ask if `has_frontend = yes`. If the project is API-only, omit both lines from `answers.env`. The renderer drops files marked `<!-- requires: has_frontend -->` (e.g., `frontend-dev` agent, `frontend-style` rule).
- **`has_e2e` and `enforce_layer_split`** — only ask if `has_frontend = yes`. Skip entirely for API-only projects.

The general rule: **if a `when:` clause isn't satisfied, the variable doesn't exist for this project.** Don't ask, don't write, don't display in the profile table. This keeps the conversation tight and the rendered output clean.

## Variant: just-go mode

If the user prefixes the command with explicit phrasing like *"setup, just go"* or passes `--auto`, skip the frontier round: every recommendation is accepted as if the user had replied `all defaults`, UNKNOWN values stay blank with their `# TODO` line (reported after the render), and the render runs immediately. Against an existing config the plan is still printed and applied with `--merge`; `--overwrite` is never automatic. Useful for throwaway projects, dangerous on real ones — the user is taking responsibility for any wrong inferences.

## What gets rendered

A full `.claude/` tree calibrated to the project:

- **`CLAUDE.md`** at the project root — principles, branch rules, agent map, dynamic context section, all referencing the project's actual test/lint/format commands and source dirs.
- **`.claude/HELP.md`** — decision tree + worked examples customized for the stack.
- **`.claude/settings.json`** — permissions tightened around the project's actual tools.
- **`.claude/mcp.json.example`** — MCP server template.
- **`.claude/rules/principles.md`**, **`backend-style.md`**, optional **`frontend-style.md`** — operating principles + style guides tailored to the stack.
- **`.claude/agents/`** — the orchestration/review agents plus only the dev specialists your `project_type` needs (`backend-dev` for web/API, `mobile-dev`, `game-dev`, `desktop-dev`, or `core-dev`; `frontend-dev`/`ui-designer` when there's a UI; `mutation-tester` when enabled), with placeholders rendered to specifics.
- **`.claude/commands/`** — the slash commands (`/spec`, `/feature`, `/fix`, `/verify`, `/audit`, `/commit`, `/pr`, `/design`, …), locally available (non-namespaced).
- **`.claude/hooks/`** — branch discipline, agent gating, auto-format — with the project's actual `src_dir` / `default_branch` baked in (no env-var fallback needed).

## Relationship to the plugin

After `/setup-template`, both layers are active:

| Layer | Source | Naming |
|---|---|---|
| Plugin commands/agents | `${CLAUDE_PLUGIN_ROOT}/...` | Namespaced (`/agent-config-template:feature`) |
| Project commands/agents | `./.claude/...` | Unnamespaced (`/feature`) |

The project-root versions take precedence when names collide. This is intentional — the project versions have the calibrated test commands, branch prefixes, and toggles baked in.

Companion tools (graphify, ponytail, ui-ux-pro-max when `has_ui`) follow step 8 above — routed by the recorded `companions` value, never pushed.

## Pre-filled examples

If the user wants to skip inference entirely and use a known-good preset, point them at `${CLAUDE_PLUGIN_ROOT}/examples/` (when present). Common stacks: `python-fastapi`, `python-django`, `node-express`, `node-nextjs`. They can copy one and run `setup.sh` directly without going through inference.

## Troubleshooting

- **`setup.sh: command not found`** — the plugin didn't ship the bundled template. Reinstall: `/plugin update agent-config-template@juantrujillodev`.
- **Missing `python3`** — `setup.sh` requires Python 3. Install it (it's preinstalled on macOS and most Linux).
- **`.git/index.lock` errors when committing afterward** — leftover from a crashed git process. Run `rm -f .git/index.lock` and retry.
- **"Existing Claude config detected … Nothing was written" (exit 1)** — expected, not an error. The project already has a config. Re-run with `--merge` (recommended) or `--overwrite` after the user has reviewed the printed plan.
