# Install on Codex

The repo doubles as a Codex plugin marketplace (`.agents/plugins/marketplace.json`
→ `codex/`). Inside Codex:

```
codex plugin marketplace add JuanTrujilloDev/agent-config-template
codex plugin add agent-config-template@juantrujillodev
```

Restart Codex (or start a new thread) to load it.

## What you get

- **15 skills**, invoked by name or auto-triggered: the workflows (`spec`,
  `feature`, `fix`, `verify`, `audit`, `commit`, `pr`, `design`,
  `setup-companions`) plus the knowledge skills (`principles` incl. the
  leverage ladder, `sdd-workflow`, `code-query`, `backend-style`,
  `frontend-style`, `port-config`).

## What's different from the Claude Code plugin

- **No subagents.** Codex plays every role itself — pmo, dev specialist,
  judge, security-reviewer — in sequence, announcing each hat switch. Same
  spec artifacts under `docs/specs/<slug>/`, same human gates.
- **No hook enforcement.** The protected-branch hard block doesn't exist on
  Codex; Branch Discipline is a written rule in `principles`. For always-on
  weight, add one line to your project's `AGENTS.md`:
  `Follow the agent-config-template principles skill for every coding task.`
- **No `setup-template`.** It renders a `.claude/` project tree — Claude-only.

## Companions

`graphify install --platform codex` registers the graphify skill;
`codex plugin marketplace add DietrichGebert/ponytail` + `codex plugin add
ponytail@ponytail` adds ponytail (trust its two hooks via `/hooks`). Or invoke
the `setup-companions` skill and let Codex run the sequence with your approval.
