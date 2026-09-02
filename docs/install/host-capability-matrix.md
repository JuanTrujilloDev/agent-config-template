# Host Capability Matrix

What each supported host runs natively, what this repo generates for it, and
what is a gap — documented, not faked.

- **native** — the host executes the shipped config as-is.
- **generated** — `scripts/build.sh` / `setup.sh --host` render a host-specific equivalent from the same `core/` source, drift-checked in CI.
- **gap** — not available on that host; the docs say so instead of pretending.

| Capability | Claude Code | Codex | Cursor | Grok Build | AGENTS.md-only |
|---|---|---|---|---|---|
| Subagents | native | gap¹ | native² | native | gap |
| Hooks | native | gap | generated³ | native | gap |
| Branch hard-block | native (pre-edit gate) | gap (advisory rule only) | generated, partial⁴ | native | gap |
| MCP | native | native (Codex's own config) | generated (`.cursor/mcp.json`) | native | gap |
| Skills discovery | native | generated⁵ | native (incl. `.claude/skills/`) | native | gap |
| Commands / skills invocation | native (slash commands) | generated (skills by name) | generated⁶ | native | gap |
| Autonomy / output banner | native (prompt hook) | generated (instruction fallback) | generated (always-on rule) | native (prompt hook) | gap |
| Brand MASTER.md | generated | generated (lazy via `/design`) | generated | generated | gap |

1. Codex plays every role itself in sequence; subagent-spawning workflow skills carry a role-adaptation note explaining the hat switches.
2. Cursor reads `.claude/agents/` natively but ignores the `tools:` frontmatter — treat `judge`, `security-reviewer`, and `ui-designer` as `readonly: true` ([details](cursor.md)).
3. `.cursor/hooks.json` + adapters over the same guard/format logic, registered on Cursor's native events (`beforeShellExecution`, `afterFileEdit`).
4. No pre-edit gate exists on Cursor: the guard denies `git commit`/`git push` on protected branches via a word-scan with a documented over-block ceiling — a guardrail, not a security boundary ([details](cursor.md)).
5. Rendered to `.agents/skills/` by `setup.sh --host codex`, or installed via the Codex plugin marketplace.
6. Slash commands become `.claude/skills/` entries with `disable-model-invocation: true` — explicit invocation only.

**AGENTS.md-only hosts** (anything not in the table — OpenCode, Gemini,
Windsurf, …) get the instructions file and nothing else this release; the
bundled `port-config` skill is the path to a fuller port for those hosts.

**Grok Build** needs no packaging tree at all: it reads the whole rendered
`.claude` tree plus `AGENTS.md`/`CLAUDE.md`; verify with `grok inspect`
([details](grok.md)).
