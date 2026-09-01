# Install on Cursor

**Skills and agents: zero porting. Rules, hooks, commands: generated.**

Cursor reads `.claude/agents/` and `.claude/skills/` natively, so those ship
as-is. Rules (`.cursor/rules/*.mdc`), hooks (`.cursor/hooks.json`), MCP config
(`.cursor/mcp.json`), and the slash commands are generated from the same
`core/` source by `scripts/build.sh` — never hand-edited, drift-checked in CI.

## Render

From a clone:

```bash
cp examples/<stack>/answers.env ./answers.env   # edit to your project
./setup.sh --host cursor --target /path/to/project --answers ./answers.env
```

Or via the Claude Code plugin: `/setup-template` batches target hosts with the
other setup decisions — keep `cursor` selected (recommended when `.cursor/`
exists). The choice is recorded as `TARGET_HOSTS` in committed `answers.env`,
so re-renders stay consistent. `--host` on the CLI overrides it.

## What you get

- **`AGENTS.md`** — the distilled operating guide (principles, branch naming, agent table).
- **`.cursor/rules/`** — `principles.mdc` (`alwaysApply: true`, points at the full `.claude/rules/principles.md`) plus `backend-style.mdc` / `frontend-style.mdc` auto-attached by glob.
- **`.cursor/mcp.json`** — derived from the Claude MCP example config.
- **`.cursor/hooks.json`** + two hook adapters (below).
- **`.claude/agents/`** — the full agent library, read natively by Cursor.
- **`.claude/skills/`** — every slash command (`spec`, `feature`, `fix`, `integrate`, `verify`, `audit`, `commit`, `pr`, `design`) as a skill with `disable-model-invocation: true`: invoke them by name, they never auto-trigger.
- **No Claude hooks surface.** The cursor render ships no `.claude/settings.json` hooks block, so a dual-host render (`--host claude,cursor`) never double-fires an event.

## Agents: `tools:` is ignored

Cursor ignores the `tools:` frontmatter that restricts Claude Code agents.
Treat the read-only agents — `judge`, `security-reviewer`, `ui-designer` — as
`readonly: true`: add that key to their frontmatter in your render if you want
Cursor to enforce it; otherwise it's on you (and the agent's own instructions)
to keep them from editing.

## Branch discipline: what's enforced, what isn't

Cursor has no pre-edit gate, so the Claude-side "hard block on protected
branches before any edit" does not exist here — this is a documented gap, not
something the render fakes. The nearest equivalent ships as a
`beforeShellExecution` hook: `git commit` / `git push` on a protected branch is
denied with the typed-branch guidance; edits themselves are not blocked.

The guard is a word-scan, not a shell parser. It flattens newlines and catches
`sh -c "git push"`, `/usr/bin/git push`, and command chains — but it deliberately
over-blocks (`git log --grep commit` on a protected branch is denied too), and a
determined bypass can defeat it. Treat it as a guardrail for a cooperating
agent, not a security boundary.

Protected branches come from `AGENT_CONFIG_PROTECTED_BRANCHES` (the legacy
`CLAUDE_CONFIG_PROTECTED_BRANCHES` is honored as a fallback). On a dual
Claude+Cursor render, the Claude hook reads only the `CLAUDE_CONFIG_*` name —
set `CLAUDE_CONFIG_PROTECTED_BRANCHES` as the cross-host override until core
learns the new one.

The second adapter, `afterFileEdit`, runs the same targeted autofix as the
Claude format hook (e.g. `ruff check --fix` on Python) and never blocks.

## Capability differences

See the [host capability matrix](host-capability-matrix.md) for the full
native / generated / gap breakdown across hosts.
