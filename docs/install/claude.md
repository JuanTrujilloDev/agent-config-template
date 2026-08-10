# Install on Claude Code

The richest experience: agents, slash commands, skills, **enforcement hooks**, and live sub-agent orchestration.

## Install

Inside Claude Code:

```
/plugin marketplace add JuanTrujilloDev/agent-config-template
/plugin install agent-config-template@juantrujillodev
```

## What you get

- **Agents:** `orchestrator` (runs the SDD flow, never edits code), `pmo` (spec + Given/When/Then contract + mini-features), a per-stack dev library (`backend-dev`/`frontend-dev` for web, `mobile-dev`, `game-dev`, `desktop-dev`, `core-dev`), `ui-designer`, `judge` (reviews code + tests; adversarial mode on large diffs), `security-reviewer` (OWASP audit), plus `mutation-tester` when enabled.
- **Commands:** `/spec`, `/feature`, `/fix`, `/verify`, `/audit`, `/commit`, `/pr`, `/design`, `/setup-template`, `/setup-companions` (optional: installs graphify + ponytail, gated on your confirmation).
- **Skills:** `principles` (incl. the leverage ladder), `sdd-workflow`, `code-query` (graph-first codebase querying), `backend-style`, `frontend-style`, `port-config` (generate this config for another agent host).
- **Hooks:** protected-branch hard block, advisory agent guidance, targeted format-on-write.

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

`/spec <task>` → approve the contract → `/feature <task>` (one mini-feature at a time, optional TDD) → `/verify` before done. Small scoped fix: `/fix`. See [the workflow](../sdd-workflow.md).
