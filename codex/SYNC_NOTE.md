# Sync note — Codex port

`codex/` is a **hand-maintained port** of `plugin/` for the Codex plugin
system (`.codex-plugin/plugin.json` + `skills/`, marketplace manifest at
`.agents/plugins/marketplace.json`).

Derivation rules (applied when re-syncing after `plugin/` changes):

- `plugin/skills/<s>/SKILL.md` → `codex/skills/<s>/SKILL.md`, adding a
  `name:` frontmatter field (Agent Skills standard).
- `plugin/commands/<c>.md` → `codex/skills/<c>/SKILL.md`: frontmatter reduced
  to `name` + quoted `description` (no `argument-hint`), and workflow commands
  that spawn subagents (`spec`, `feature`, `fix`, `audit`, `design`) get the
  role-adaptation note — Codex has no subagents, the agent plays each role in
  sequence with the same artifacts and gates.
- **Not ported:** `plugin/agents/` (no subagents on Codex — roles are notes in
  the workflow skills), `plugin/hooks/` (the protected-branch hard block has no
  Codex equivalent; Branch Discipline is enforced as a written rule in
  `principles`), and `setup-template` (renders a `.claude/` tree — Claude-only).
- Codex-specific content edits: `setup-companions` uses `codex plugin …` and
  `graphify install --platform codex`; the orchestrator notes in `sdd-workflow`
  and `feature` describe hat-switching instead of subagent spawning.

After editing `plugin/`, re-apply these rules to the corresponding `codex/`
files. CI does not check this tree for drift (yet).
