# Install on Claude Code

The richest experience: agents, slash commands, skills, **enforcement hooks**, and live sub-agent orchestration.

## Install

Inside Claude Code:

```
/plugin marketplace add JuanTrujilloDev/agent-config-template
/plugin install agent-config-template@juantrujillodev
```

## What you get

- **Agents:** `ui-designer`, `security-reviewer` (OWASP audit), plus `mutation-tester` when enabled. No coordinator or dev subagents.
- **Slice loop (skills):** `epic`, `slice`, `tests-first`, `implement`, `code-review`, `council` (opt-in).
- **Commands:** `/fix`, `/verify`, `/audit`, `/commit`, `/pr`, `/design`, `/integrate`, `/setup-template`, `/setup-companions` (optional: installs graphify + ponytail, gated on your confirmation).
- **Other skills:** `principles` (incl. the leverage ladder), `update-config`, `code-query` (graph-first codebase querying), `patterns`, `backend-style`, `frontend-style`, `port-config` (generate this config for another agent host).
- **Hooks:** protected-branch hard block, approved-tests lock, targeted format-on-write.

The hooks read env vars with sensible defaults — override per project:

```bash
export CLAUDE_CONFIG_SRC_DIR=apps                       # default: src
export CLAUDE_CONFIG_FRONTEND_DIR=apps/frontend         # default: (none)
export CLAUDE_CONFIG_PROTECTED_BRANCHES="main,qa,prod"  # default: main,master
```

## Calibrate to a project

```
/agent-config-template:setup-template
```

Renders a `.claude/` tree + `CLAUDE.md` tuned to your stack. **Non-destructive** — against an existing config it shows a per-file plan and won't write without your `--merge` / `--overwrite` choice; `.claude/settings.local.json` is never touched. Manual clone path: `setup.sh --target . --answers ./answers.env [--merge]`.

## Update

```
/plugin marketplace update juantrujillodev
/reload-plugins
```

## Use it

`/epic <task>` → approve the draft → `/slice <ID> <n>` → `tests-first` (approve the tests) → `implement` → `code-review` → `/pr`. Small scoped fix: `/fix`. See [the workflow](../epic-story-slice.md).
