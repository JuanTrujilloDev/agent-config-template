# Install on Grok Build

Nothing to port: Grok Build discovers the rendered `.claude` tree — agents,
rules, skills, hooks, and MCP config — plus `AGENTS.md` and `CLAUDE.md`
natively. That's why this repo ships **no `grok/` packaging tree**: the claude
render *is* the Grok Build render.

## Render

```bash
cp examples/<stack>/answers.env ./answers.env   # edit to your project
./setup.sh --host grok --target /path/to/project --answers ./answers.env
```

`grok` is an alias, not a separate tree: it renders the standard `.claude/`
tree + `CLAUDE.md`, plus a rendered `AGENTS.md` on top. A plain claude render
also works — the alias just adds the `AGENTS.md` shortcut.

## Verify

```bash
grok inspect
```

Run it in the rendered project to confirm Grok Build picked up the agents,
rules, skills, hooks, and MCP config from the `.claude` tree.

## Capability differences

See the [host capability matrix](host-capability-matrix.md) — Grok Build's
column is all native.
