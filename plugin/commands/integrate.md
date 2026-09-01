---
description: "Research and safely connect an external tool through MCP"
argument-hint: "<tool>"
---

# Integrate a tool

Connect `$ARGUMENTS` through MCP without guessing or making silent changes.

## 1. Research only

If no tool was named, ask for one and stop.

Search current official vendor documentation and official repositories for its MCP server. Prefer an official server. If only a community server exists, label it clearly and verify its source, maintenance, install method, and security implications.

Collect:

- canonical source URL
- package, executable, or endpoint
- transport and required environment variables
- exact `mcpServers` entry
- install command, if one is required
- files that would change

Never invent missing details. Do not install anything or write files during research. Never ask the user to paste secrets into a tracked file; use `${ENV_VAR}` placeholders.

If research fails or the environment is offline, make no changes. Ask for the canonical package or URL, or provide manual JSON wiring instructions, then stop.

## 2. Show the plan and stop

Show the source, package or endpoint, security notes, required environment variables, exact install command, and proposed JSON entry.

List the only project files this command may change:

- `.claude/mcp.json`
- `CLAUDE.md`
- `answers.env` only after a separate tracker confirmation

Explain that existing MCP servers and unrelated content will be preserved. If `CLAUDE.md` or its `### MCP Servers` heading is missing, include creating it in the plan.

Ask for explicit confirmation. **STOP.** A decline or anything other than an unambiguous yes means zero installs and zero writes.

## 3. Apply after confirmation

1. Preflight every target. If `.claude/mcp.json` exists, parse it before any install or write; if invalid, stop untouched and report the error.
2. If `.claude/mcp.json` is absent, prepare it from `.claude/mcp.json.example`. If the example is unavailable, prepare the minimal valid structure `{"mcpServers": {}}`; do not copy an unrendered template containing placeholders.
3. Run the disclosed install command only if installation is required.
4. Merge only the named `mcpServers.<name>` entry. Preserve every unrelated key and server.
5. Under `### MCP Servers` in `CLAUDE.md`, add one concise bullet with the server name, purpose, and source URL. Create the heading if the approved plan said it was missing. Update or deduplicate an existing bullet instead of adding another.
6. Parse the final JSON and verify the new entry, the single documentation bullet, and the absence of literal secrets.

Do not run remote shell pipelines such as `curl ... | sh`. Show any additional privileged or global install separately and ask before running it.

## 4. Optional tracker setting

If the integrated tool is a ticket tracker, ask separately whether to set it as `ticket_tracker` in `answers.env`. Do not edit `answers.env` unless the user explicitly agrees. Preserve all other answers and replace or add only that key.

Finish with the verification result and any required editor or agent restart.
