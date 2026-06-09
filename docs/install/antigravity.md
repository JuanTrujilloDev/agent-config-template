# Install on Antigravity / Gemini

Antigravity gets the rules as loaded context plus the workflow, via a native extension.

## Install

```
gemini extensions install https://github.com/JuanTrujilloDev/agent-config-template
```

The extension is defined by [`gemini-extension.json`](../../gemini-extension.json) at the repo root, which points at [`GEMINI.md`](../../GEMINI.md) as its context file.

> Note: Google is transitioning Gemini CLI to **Antigravity CLI** (mid-2026). The `gemini extensions install` mechanism carries over; if the command name changes on your install, use the Antigravity CLI equivalent.

## What you get

- **Native slash commands:** the extension ships `commands/*.toml`, so `/spec`, `/feature`, `/fix`, `/verify`, and `/audit` work as first-class commands (generated from the same sources as every other host).

- **Context / rules:** `GEMINI.md` is loaded as standing context — the principles, the spec-driven workflow, branch discipline, and the Definition of Done. Antigravity also reads `AGENTS.md` (the cross-tool rules file) as a fallback; both carry the same content, so there's no conflict.
- **Skills:** the extension's `skills/` tree (`spec`, `fix`, `verify`, `security-audit`, …) is auto-discovered as Agent Skills by recent Gemini CLI versions — activated on demand, no extra wiring. On older versions, copy them into your skills directory manually.

## What's different vs Claude Code

You get the principles, the workflow, and the rules as context. Enforcement hooks and live multi-agent orchestration are Claude-Code-specific. Antigravity's own rules system (`GEMINI.md`, `AGENTS.md`, `.agent/rules/`) carries the guidance; enforcement parity isn't wired yet.
