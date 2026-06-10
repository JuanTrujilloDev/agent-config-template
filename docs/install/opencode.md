# Install on OpenCode

OpenCode gets the workflow and reviews as **skills** plus the always-on rules.

## Install

From your project root:

```
npx skills add JuanTrujilloDev/agent-config-template
```

The skills CLI installs the `SKILL.md` files into the universal `.agents/skills/` directory at your project root (use `--global` for `~/.config/opencode/skills/`). OpenCode discovers skills in `.opencode/skills/`, `.claude/skills/`, and `.agents/skills/` automatically — restart OpenCode to pick them up.

For the rules layer, drop this repo's [`AGENTS.md`](../../AGENTS.md) at your project root (OpenCode reads `AGENTS.md` automatically; `/init` will scaffold one if you don't have it).

## What you get

- **Skills:** `spec`, `feature`, `fix`, `verify`, `security-audit`, `principles`, `sdd-workflow`, `backend-style`, `frontend-style` — the full SDD loop, loaded on demand via OpenCode's native `skill` tool. Each workflow skill ends with a "hosts without subagents" adaptation: you play the `pmo`/`judge` roles yourself, same artifacts, same gates.
- **Rules:** `AGENTS.md` (principles, spec-driven workflow, branch discipline, Definition of Done).

## What's different vs Claude Code

Same principles, workflow, and skills. OpenCode "plugins" proper are JavaScript event-hook modules (`tool.execute.before`, etc.) — a different mechanism from skills. That's the planned vehicle for hook **enforcement parity** (e.g. a protected-branch block as a small npm plugin installed via `opencode.json`); today the branch rule lives in `AGENTS.md` as guidance.
