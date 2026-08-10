---
name: port-config
description: "Port this configuration to another agent host (Claude Code, OpenCode, Gemini CLI / Antigravity, Cursor, Windsurf, …). Looks up the target host's CURRENT config format online, then generates equivalent rules, skills, and commands from this config. Use when the user wants this workflow on a different AI coding tool."
---

# Port the config to another host

Generate an equivalent of this configuration — principles, the SDD workflow,
review discipline — for a different agent host. Formats change fast, so the
target's **current official docs are the spec**: always research first, never
generate from memory.

## 1. Identify the target

Ask which host if not stated. Then locate its current official docs with web
search (e.g. "<host> skills SKILL.md format", "<host> rules file", "<host>
custom commands", "<host> plugin manifest"). Prefer the vendor's own docs over
blog posts. Typical entry points:

- Codex: developers.openai.com/codex (AGENTS.md, `.agents/skills/`, plugins)
- OpenCode: opencode.ai/docs (AGENTS.md, `.opencode/skills/`, `.agents/skills/`)
- Gemini CLI / Antigravity: geminicli.com/docs, antigravity.google (GEMINI.md, extensions, TOML commands)
- Cursor / Windsurf / others: their current rules/skills mechanisms

## 2. Establish the mapping

From the docs, decide where each piece of this config lands on the target:

| This config | Typical target equivalent |
|---|---|
| `principles` skill + CLAUDE.md rules | always-on rules file (AGENTS.md, GEMINI.md, .cursorrules, …) |
| `/spec`, `/feature`, `/fix`, `/verify`, `/audit` | skills (SKILL.md) or native commands |
| agents (`pmo`, `judge`, `security-reviewer`, dev specialists) | skills the agent role-plays — most hosts have no subagents |
| hooks (branch block, format-on-write) | usually **no equivalent** — port as written rules |

Where the host has no subagents, add a role-adaptation note: the agent plays
`pmo`/`judge`/`security-reviewer` itself, in sequence, switching hats
explicitly — same artifacts under `docs/specs/<slug>/`, same human gates
(contract approval; failing tests under TDD), same Definition of Done.

## 3. Generate

Write the files in the target's exact format, into the target's exact paths.
Keep ONE source of truth: derive content from this config's skills and rules;
don't invent new principles. Respect documented constraints (required
frontmatter fields, name patterns, description length caps).

## 4. Validate before declaring done

- **Strictly parse every frontmatter/manifest you generated** (YAML/JSON/TOML).
  An unquoted `:` inside a YAML value silently breaks skill discovery on strict
  hosts — quote values defensively.
- Confirm every referenced path exists.
- If the host has an install/validate CLI, run it.
- Tell the user explicitly what did **not** port (hooks enforcement, subagent
  orchestration) and where the rules now carry that weight instead.
