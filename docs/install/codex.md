# Install on Codex

Codex gets the spec-driven workflow and reviews as **skills**, packaged as a native Codex plugin.

## Quick path (skills CLI)

From your project root:

```
npx skills add JuanTrujilloDev/agent-config-template
```

This installs the `SKILL.md` files into the universal `.agents/skills/` directory at your project root, which Codex reads natively (it also reads `~/.agents/skills` for personal skills). Start a new Codex session, then list them with `/skills` or type `$` to mention one.

## Native plugin

The repo ships a Codex plugin at [`codex/`](../../codex/) (`.codex-plugin/plugin.json` + bundled skills) and a marketplace catalog at [`.agents/plugins/marketplace.json`](../../.agents/plugins/marketplace.json).

Until Codex's official Plugin Directory opens self-serve publishing, install locally:

1. Clone this repo.
2. Add an entry to your repo or personal marketplace (`$REPO_ROOT/.agents/plugins/marketplace.json` or `~/.agents/plugins/marketplace.json`) whose `source.path` points at the cloned `codex/` directory — the bundled `.agents/plugins/marketplace.json` shows the exact shape.
3. Restart Codex, open the plugin directory, and install it.

We'll list it in the official Plugin Directory the moment self-serve publishing is available.

## What you get

- **Skills:** `spec`, `feature`, `fix`, `verify`, `security-audit`, `principles`, `sdd-workflow`, `backend-style`, `frontend-style` — the full SDD loop. Each workflow skill ends with a "hosts without subagents" adaptation: you play the `pmo`/`judge` roles yourself, same artifacts, same gates.
- **Rules:** the always-on baseline in [`AGENTS.md`](../../AGENTS.md) (Codex reads it automatically).
- Bundled MCP config slot (`.mcp.json`) if you add servers.

## What's different vs Claude Code

You get the principles, the spec-driven workflow, and the skills. The enforcement **hooks** (protected-branch block, format-on-write) and live multi-agent orchestration are Claude-Code-specific; Codex has its own native hooks system, so per-host enforcement is on the roadmap.
