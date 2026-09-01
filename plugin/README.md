# agent-config-template (plugin)

Plugin distribution of [agent-config-template](https://github.com/JuanTrujilloDev/agent-config-template). Install once, get the full toolkit across every project.

## Install

Inside Claude Code:

```
/plugin marketplace add JuanTrujilloDev/agent-config-template
/plugin install agent-config-template@juantrujillodev
```

That's it. You now have agents, slash commands, skills, and hooks available everywhere.

Then, optionally, install the companion tools (one confirmation, skips what's already there):

```
/agent-config-template:setup-companions
```

## Two ways to use it

### 1. Just the plugin (generic defaults)

After install you immediately get:

- **11 agents** (`/agents` to list): `orchestrator`, `pmo`, `judge`, `security-reviewer`, `ui-designer`, plus a dev library Claude picks from per project type — `backend-dev` (web/API), `frontend-dev` (web UI), `mobile-dev`, `game-dev`, `desktop-dev`, `core-dev` (library/CLI/data). Each with an embedded "Gotchas" section.
- **10 slash commands** namespaced under `/agent-config-template:*` — `spec`, `feature`, `fix`, `verify`, `audit`, `commit`, `pr`, `design`, **`setup-template`**, **`setup-companions`** (install graphify + ponytail, with a confirmation gate).
- **6 skills**: `principles` (incl. the leverage ladder — reuse > stdlib > native > installed deps > new code), `sdd-workflow`, `code-query` (graph-first codebase querying — uses a knowledge graph like [graphify](https://github.com/Graphify-Labs/graphify) when available, deterministic repo map otherwise), `backend-style`, `frontend-style`, `port-config` (generate this config for another agent host from its current docs).
- **3 hooks**: branch discipline (hard block on protected branches), agent guidance (advisory — guides, doesn't block), targeted auto-format on Edit/Write.

The hooks read environment variables with sensible defaults. Override per-project via `.envrc` (direnv) or your shell rc:

```bash
export CLAUDE_CONFIG_SRC_DIR=apps                       # default: src
export CLAUDE_CONFIG_FRONTEND_DIR=apps/frontend         # default: (none)
export CLAUDE_CONFIG_PROTECTED_BRANCHES="main,qa,prod"  # default: main,master
```

### Companion tools (optional, auto-detected)

Two external tools slot straight into the workflow when installed — nothing here depends on them. **`/agent-config-template:setup-companions` installs both** (with a confirmation gate; idempotent), or install by hand:

- **[graphify](https://github.com/Graphify-Labs/graphify)** — codebase knowledge graph. Install with `uv tool install graphifyy && graphify install`. The `code-query` skill prefers the graph (`/graphify query|path|explain`) for structural questions during `/spec`, `/feature`, and `/fix`; without it, the skill falls back to a deterministic repo map.
- **[ponytail](https://github.com/dietrichgebert/ponytail)** — runtime minimal-code enforcement (`/plugin marketplace add DietrichGebert/ponytail`, then `/plugin install ponytail@ponytail`). It enforces at generation time what this config's **leverage ladder** (`principles` skill) bakes into `/spec` Design notes and the `/verify` over-engineering check — the ladder keeps behavior consistent on hosts where ponytail isn't installed. To have ponytail's ruleset reach this plugin's dev subagents too, widen its matcher: `export PONYTAIL_SUBAGENT_MATCHER="dev|explore|general"`.

### 2. Plugin + `/setup-template` (fully calibrated)

When you want a specific project to have a `.claude/` tree calibrated to its exact stack — your test command, your branch prefix, your layer-split toggle — run the bundled command from inside the project:

```
/agent-config-template:setup-template
```

Claude will:

1. Read `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / `manage.py` / etc.
2. Draft an `answers.env` with confidence labels (HIGH / LOW / UNKNOWN).
3. Show it to you and **wait for approval or edits.**
4. Run the bundled `setup.sh` to render a full `.claude/` tree + `CLAUDE.md`. It's **non-destructive** — against an existing config it shows a per-file change plan and won't write without your `--merge` / `--overwrite` choice.
5. Add `.claude/settings.local.json`, `.claude/mcp.json`, and `.claude/answers.local.env` to `.gitignore` (`answers.env` is committed project policy).
6. Remind you to restart Claude Code.

After this, both layers are active in that project — the plugin commands stay namespaced (`/agent-config-template:feature`), and the project-root commands are unnamespaced (`/feature`). The project-root versions take precedence when names collide because they have your specifics baked in.

## When to use which

|                                | Plugin only                                     | Plugin + `/setup-template`                              |
| ------------------------------ | ----------------------------------------------- | ------------------------------------------------------- |
| **Setup time**                 | Instant after install                           | ~1 minute per project                                   |
| **Project specifics**          | Generic defaults via env vars                   | Baked in — your test command, branch prefix, toggles    |
| **Style guides**               | Stack-agnostic skills                           | Tailored prose                                          |
| **Layer-split (BE/FE PR rule)**| Off                                             | Toggleable per project                                  |
| **Best for**                   | Quick adoption across many repos                | Flagship projects where you want full precision         |

## Updating

```
/plugin update agent-config-template@juantrujillodev
```

If you previously ran `/setup-template` in a project, the rendered `.claude/` tree is independent — re-run `/setup-template` after upgrading if you want the latest patterns there too.

## License

MIT.
