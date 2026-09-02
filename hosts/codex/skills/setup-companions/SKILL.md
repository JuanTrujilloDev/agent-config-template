---
name: setup-companions
description: "Install the optional companion tools — graphify (codebase knowledge graph, powers code-query), ponytail (runtime minimal-code enforcement) and, for UI projects, ui-ux-pro-max (design-system skill) — with a confirmation gate. Accepts an optional comma list. Idempotent: skips anything already installed."
---

# /setup-companions

Installs the companion tools this config integrates with. All are
**optional** — every skill and command works without them — but they sharpen
the workflow: graphify gives the `code-query` skill a real knowledge graph,
ponytail enforces at generation time what the leverage ladder bakes into
`/spec` and `/verify`, and ui-ux-pro-max (UI projects only — `has_ui`) gives
`ui-designer` and `frontend-dev` a design-system reference.

## Usage

```
/setup-companions [graphify,ponytail,ui-ux-pro-max]
```

Without an argument: graphify + ponytail, plus ui-ux-pro-max when the project
has a UI. With a comma list: exactly those tools, nothing else.

## What it does

1. **Detect what's already there** (never reinstall):
   - graphify: `command -v graphify`, and the registered skill at `~/.claude/skills/graphify/`
   - ponytail: `codex plugin list` (or the plugin browser) shows `ponytail@ponytail`
   - ui-ux-pro-max: `.agents/skills/ui-ux-pro-max/` exists in the project
2. **Show the plan and STOP for confirmation.** List exactly what will be
   installed with the exact install command per tool, from where (PyPI package
   `graphifyy` — double-y, the single-y packages are unaffiliated; GitHub
   marketplace `DietrichGebert/ponytail`; npm `ui-ux-pro-max-cli@2.15.0` from
   github.com/nextlevelbuilder/ui-ux-pro-max-skill, MIT), and what each writes
   to the machine. Install nothing without an explicit yes.
3. **Install graphify** (first available installer wins):
   ```bash
   uv tool install graphifyy || pipx install graphifyy || pip install --user graphifyy
   graphify install --platform codex   # registers the graphify skill for Codex
   ```
4. **Install ponytail**:
   ```bash
   codex plugin marketplace add DietrichGebert/ponytail
   codex plugin add ponytail@ponytail
   # then open /hooks in codex, review and trust ponytail's two lifecycle hooks
   ```
5. **Install ui-ux-pro-max** (only when requested or `has_ui`; project-local):
   ```bash
   npm install -g ui-ux-pro-max-cli@2.15.0
   uipro init --ai codex               # writes .agents/skills/ui-ux-pro-max/
   ```
   To deliberately use the unpinned latest release instead, run `npm install -g ui-ux-pro-max-cli`; this is never the default.
6. **Verify and report**: `graphify --version`, `codex plugin list`, `ls .agents/skills/ui-ux-pro-max`. Remind
   the user to restart Codex so the new plugin and skill load, and that
   `/graphify .` builds the graph for the current project.

## Options to mention after install (don't set them unprompted)

- Ponytail intensity: `/ponytail lite|full|ultra|off` (default `full`), or
  `PONYTAIL_DEFAULT_MODE` to persist.
- To inject ponytail's ruleset into this plugin's dev subagents:
  `export PONYTAIL_SUBAGENT_MATCHER="dev|explore|general"`.
- Graphify semantic extraction of docs/PDFs uses a configurable LLM backend
  and is opt-in; pure code extraction is local and deterministic.

## Failure handling

If an installer is missing (no `uv`/`pipx`/`pip`) or a network step fails,
report the exact failing command and the manual fallback — don't retry in a
loop, and don't let a companion failure block the rest of the setup. The
plugin remains fully functional without them.
