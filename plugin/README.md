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
- **11 slash commands** namespaced under `/agent-config-template:*` — `spec`, `feature`, `fix`, `integrate`, `verify`, `audit`, `commit`, `pr`, `design`, **`setup-template`**, **`setup-companions`** (install graphify + ponytail, with a confirmation gate).
- **7 skills**: `principles` (incl. the leverage ladder — reuse > stdlib > native > installed deps > new code), `sdd-workflow`, `code-query` (graph-first codebase querying — uses a knowledge graph like [graphify](https://github.com/Graphify-Labs/graphify) when available, deterministic repo map otherwise), `patterns` (design-pattern restraint — name the force, try the simplest default, keep a `pattern / force / rejected alternative` ledger; six domain references), `backend-style`, `frontend-style`, `port-config` (generate this config for another agent host from its current docs).
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

1. Infer the full project profile and cite each source with HIGH / LOW / UNKNOWN confidence.
2. Ask only decisions in one numbered frontier round; a second appears only if an answer unlocks gated choices.
3. Store project policy in committed `answers.env` and personal preferences in gitignored `.claude/answers.local.env`.
4. Wait for approval, then run bundled `setup.sh` to render `.claude/` + `CLAUDE.md`. Existing configs first get a non-destructive plan and require `--merge` or `--overwrite`.
5. Keep `.claude/settings.local.json`, `.claude/mcp.json`, and `.claude/answers.local.env` gitignored; never gitignore `answers.env`.
6. Route an accepted companion recommendation through the separately confirmed `/setup-companions` flow, then remind you to restart Claude Code.

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
