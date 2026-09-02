# Install on Cursor

No clone is required. The native Cursor plugin packages the rules, skills,
agents, commands, and hooks.

## Install

1. Open **Customize → Plugins** in Cursor.
2. Search for **Agent Config Template** and select **Install**.
3. Choose project or user scope.
4. Run `/setup-template` in the project.

Cursor installs the plugin from its marketplace and exposes the bundle through
`CURSOR_PLUGIN_ROOT`. `/setup-template` uses the bundled renderer, asks one
decision round, writes `answers.env`, previews existing-file conflicts, and
applies only after approval. It selects the Cursor host automatically.

The plugin repository must first pass Cursor's marketplace review. Maintainers
submit it at [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish).
Normal users install from Cursor; they do not clone this repository.

## What you get

- **`AGENTS.md`** — the distilled operating guide (principles, branch naming, agent table).
- **`.cursor/rules/`** — `principles.mdc` (`alwaysApply: true`, points at the full `.claude/rules/principles.md`) plus `backend-style.mdc` / `frontend-style.mdc` auto-attached by glob.
- **`.cursor/mcp.json`** — derived from the Claude MCP example config.
- **`.cursor/hooks.json`** + two hook adapters (below).
- **`.claude/agents/`** — the full agent library, read natively by Cursor.
- **`.claude/skills/`** — the stack-dependent command set as skills with
  `disable-model-invocation: true`; file-level `requires:` directives omit items
  that do not apply to the rendered project. Invoke the installed skills by
  name; they never auto-trigger.
- **No Claude hooks surface.** The cursor render ships no `.claude/settings.json` hooks block, so a dual-host render (`--host claude,cursor`) never double-fires an event.

The installed plugin works immediately with generic defaults. The rendered
project files take precedence after `/setup-template` because they contain the
project's actual stack, commands, paths, and branch policy.

## Update

Open **Customize → Plugins → Yours**, select **Agent Config Template**, and
update it. Run `/setup-template` again to preview project-file changes; use the
recommended merge path after reviewing the plan.

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

Protected branches come from `AGENT_CONFIG_PROTECTED_BRANCHES`; both Cursor and
Claude guards honor `CLAUDE_CONFIG_PROTECTED_BRANCHES` as a legacy fallback.

The second adapter, `afterFileEdit`, runs the same targeted autofix as the
Claude format hook (e.g. `ruff check --fix` on Python) and never blocks.

## Capability differences

See the [host capability matrix](host-capability-matrix.md) for the full
native / generated / gap breakdown across hosts.
