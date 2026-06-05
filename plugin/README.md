# claude-config-template (plugin)

Plugin distribution of [claude-config-template](https://github.com/JuanTrujilloDev/claude-config-template). Install once, get the full toolkit across every project.

## Install

Inside Claude Code:

```
/plugin marketplace add JuanTrujilloDev/claude-config-template
/plugin install claude-config-template@juantrujillodev
```

That's it. You now have agents, slash commands, skills, and hooks available everywhere.

## Two ways to use it

### 1. Just the plugin (generic defaults)

After install you immediately get:

- **7 agents** (`/agents` to list): `pm`, `po-manager`, `backend-dev`, `frontend-dev`, `ui-designer`, `code-reviewer`, `security-reviewer`. Each with embedded "Gotchas" sections.
- **10 slash commands** namespaced under `/claude-config-template:*` — `feature`, `fix`, `plan`, `commit`, `pr`, `audit`, `design`, `idea`, `sow`, **`setup-template`**.
- **3 skills**: `principles`, `backend-style`, `frontend-style`.
- **3 hooks**: branch discipline (hard block on protected branches), agent guidance (advisory — guides, doesn't block), targeted auto-format on Edit/Write.

The hooks read environment variables with sensible defaults. Override per-project via `.envrc` (direnv) or your shell rc:

```bash
export CLAUDE_CONFIG_SRC_DIR=apps                       # default: src
export CLAUDE_CONFIG_FRONTEND_DIR=apps/frontend         # default: (none)
export CLAUDE_CONFIG_PROTECTED_BRANCHES="main,qa,prod"  # default: main,master
```

### 2. Plugin + `/setup-template` (fully calibrated)

When you want a specific project to have a `.claude/` tree calibrated to its exact stack — your test command, your branch prefix, your layer-split toggle — run the bundled command from inside the project:

```
/claude-config-template:setup-template
```

Claude will:

1. Read `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / `manage.py` / etc.
2. Draft an `answers.env` with confidence labels (HIGH / LOW / UNKNOWN).
3. Show it to you and **wait for approval or edits.**
4. Run the bundled `setup.sh` to render a full `.claude/` tree + `CLAUDE.md`. It's **non-destructive** — against an existing config it shows a per-file change plan and won't write without your `--merge` / `--overwrite` choice.
5. Add `.claude/settings.local.json`, `.claude/mcp.json`, and `answers.env` to `.gitignore`.
6. Remind you to restart Claude Code.

After this, both layers are active in that project — the plugin commands stay namespaced (`/claude-config-template:feature`), and the project-root commands are unnamespaced (`/feature`). The project-root versions take precedence when names collide because they have your specifics baked in.

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
/plugin update claude-config-template@juantrujillodev
```

If you previously ran `/setup-template` in a project, the rendered `.claude/` tree is independent — re-run `/setup-template` after upgrading if you want the latest patterns there too.

## License

MIT.
