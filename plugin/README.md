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

- **The slice loop as skills**, namespaced under `/agent-config-template:*`: `epic` (draft an epic once: capability groups, one-case stories, AC, Given/When/Then test scenarios, layered slices; tracker or `docs/epics/<ID>/`), `slice` (brief one layer of one capability group), `tests-first` (all the slice's tests, red, then your yes; approved tests are locked), `implement` (code to green in your thread), `code-review` (Standards and Spec axes, one fix round), `council` (opt-in, single round, three providers).
- **More skills**: `principles` (incl. the leverage ladder — reuse > stdlib > native > installed deps > new code), `update-config` (upgrade a rendered project and migrate old `docs/specs/`), `code-query` (graph-first codebase querying — uses a knowledge graph like [graphify](https://github.com/Graphify-Labs/graphify) when available, deterministic repo map otherwise), `patterns` (design-pattern restraint — name the force, try the simplest default; six domain references), `backend-style`, `frontend-style`, `port-config` (generate this config for another agent host from its current docs), `lavish` (pinned local HTML visual review; not product UI), `orchestrator-init` (optional: scaffolds an orchestrator folder and prints two T3 schedule prompts to create by hand).
- **2 agents** (`/agents` to list): `security-reviewer`, `ui-designer`. There is no coordinator or dev subagent.
- **10 slash commands** — `fix`, `integrate`, `verify`, `audit`, `commit`, `pr`, `design`, **`setup-template`**, **`setup-companions plan|doctor|install|update|uninstall [list]`** (optional graphify + ponytail, and ui-ux-pro-max when `has_ui`), `orchestrator-init` (optional).
- **2 hooks**: branch discipline plus the approved-tests lock (hard blocks; `AGENT_CONFIG_UNLOCK_TESTS=1` lifts the lock), targeted auto-format on Edit/Write.

The hooks read environment variables with sensible defaults. Override per-project via `.envrc` (direnv) or your shell rc:

```bash
export CLAUDE_CONFIG_SRC_DIR=apps                       # default: src
export CLAUDE_CONFIG_FRONTEND_DIR=apps/frontend         # default: (none)
export AGENT_CONFIG_PROTECTED_BRANCHES="main,qa,prod"   # default: main,master
```

### Companion tools (optional, auto-detected)

Three external tools slot straight into the workflow when installed—nothing
here depends on them. Use
**`/agent-config-template:setup-companions plan|doctor|install|update|uninstall [list]`**;
the pinned metadata comes from `companions.lock.json`, and every mutation has a
per-tool confirmation gate.

- **[graphify](https://github.com/Graphify-Labs/graphify)** — codebase knowledge graph. The pinned install is `uv tool install graphifyy==0.9.38 && graphify install`. The `code-query` skill prefers the graph (`/graphify query|path|explain`) for structural questions during `epic`, `slice`, `implement` and `/fix`; without it, the skill falls back to a deterministic repo map.
- **[ponytail](https://github.com/dietrichgebert/ponytail)** — runtime minimal-code enforcement (`/plugin marketplace add DietrichGebert/ponytail`, then `/plugin install ponytail@ponytail`). It enforces at generation time what this config's **leverage ladder** (`principles` skill) bakes into the slice brief and the `/verify` over-engineering check — the ladder keeps behavior consistent on hosts where ponytail isn't installed.
- **[ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)** (MIT) — design-system skill for `ui-designer` and `fe` slices; recommended only when `has_ui` is truthy. Install with `npm install -g ui-ux-pro-max-cli@2.15.0`, then `uipro init --ai claude` (writes `.claude/skills/ui-ux-pro-max/`).

`/setup-template` records the choice in `.claude/answers.local.env` as `companions=yes|not_now|never|<comma list>` — a list such as `graphify,ponytail` installs only those, and the omitted tools are not re-recommended.

### 2. Plugin + `/setup-template` (fully calibrated)

When you want a specific project to have a `.claude/` tree calibrated to its exact stack — your test command, your branch prefix, your tracker — run the bundled command from inside the project:

```
/agent-config-template:setup-template
```

Claude will:

1. Infer the full project profile and cite each source with HIGH / LOW / UNKNOWN confidence.
2. Ask only decisions in one numbered frontier round; a second appears only if an answer unlocks gated choices.
3. Store project policy in committed `answers.env` and personal preferences in gitignored `.claude/answers.local.env`.
4. Wait for approval, then run bundled `setup.sh` to render `.claude/` + `CLAUDE.md`. Existing configs first get a non-destructive plan and require `--merge` or `--overwrite`.
5. Keep `.claude/settings.local.json`, `.claude/mcp.json`, and `.claude/answers.local.env` gitignored; never gitignore `answers.env`.
6. Route an accepted companion recommendation (`yes` or a comma list) through the separately confirmed `/setup-companions` flow, then remind you to restart Claude Code.

After this, both layers are active in that project — the plugin commands stay namespaced (`/agent-config-template:epic`), and the project-root commands are unnamespaced (`/epic`). The project-root versions take precedence when names collide because they have your specifics baked in.

## When to use which

|                                | Plugin only                                     | Plugin + `/setup-template`                              |
| ------------------------------ | ----------------------------------------------- | ------------------------------------------------------- |
| **Setup time**                 | Instant after install                           | ~1 minute per project                                   |
| **Project specifics**          | Generic defaults via env vars                   | Baked in — your test command, branch prefix, toggles    |
| **Style guides**               | Stack-agnostic skills                           | Tailored prose                                          |
| **Best for**                   | Quick adoption across many repos                | Flagship projects where you want full precision         |

## Updating

```
/plugin update agent-config-template@juantrujillodev
```

If you previously ran `/setup-template` in a project, the rendered `.claude/` tree is independent — run the `update-config` skill in that project to plan and apply the upgrade (it never overwrites files you edited).

## License

MIT.
