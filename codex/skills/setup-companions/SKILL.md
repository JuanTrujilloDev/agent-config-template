---
name: setup-companions
description: "Install the optional companion tools — graphify (codebase knowledge graph, powers code-query) and ponytail (runtime minimal-code enforcement) — with a confirmation gate. Idempotent: skips anything already installed."
---

# /setup-companions

Installs the two companion tools this config integrates with. Both are
**optional** — every skill and command works without them — but together they
sharpen the workflow: graphify gives the `code-query` skill a real knowledge
graph, and ponytail enforces at generation time what the leverage ladder bakes
into `/spec` and `/verify`.

## Usage

```
/setup-companions
```

## What it does

1. **Detect what's already there** (never reinstall):
   - graphify: `command -v graphify`, and the registered skill at `~/.claude/skills/graphify/`
   - ponytail: `codex plugin list` (or the plugin browser) shows `ponytail@ponytail`
2. **Show the plan and STOP for confirmation.** List exactly what will be
   installed, from where (PyPI package `graphifyy` — double-y, the single-y
   packages are unaffiliated; GitHub marketplace `DietrichGebert/ponytail`),
   and what each writes to the machine. Install nothing without an explicit yes.
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
5. **Verify and report**: `graphify --version`, `codex plugin list`. Remind
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
