# Sync note — Codex port

`codex/skills/` is **generated** by `scripts/build.sh` from `plugin/skills/`,
`plugin/commands/`, and the override sources in `hosts/codex/`. Never hand-edit
it — edit `plugin/` or `hosts/codex/` and run `bash scripts/build.sh`.
CI (`bash scripts/build.sh --check`) fails on any drift.

Derivation rules (implemented in `build_codex_skills` in `scripts/build.sh`):

- `plugin/skills/<s>/SKILL.md` → `codex/skills/<s>/SKILL.md`, adding a
  `name:` frontmatter field (Agent Skills standard).
- `plugin/commands/<c>.md` → `codex/skills/<c>/SKILL.md`: frontmatter reduced
  to `name` + quoted `description` (no `argument-hint`), and workflow commands
  that spawn subagents (`spec`, `feature`, `fix`, `audit`, `design`) get the
  role-adaptation note (`hosts/codex/note-role-adaptation.md`) — Codex has no
  subagents, the agent plays each role in sequence with the same artifacts and
  gates.
- Codex-specific content deltas live as whole-file overrides in
  `hosts/codex/skills/<s>/SKILL.md` (`setup-companions` uses `codex plugin …`
  and `graphify install --platform codex`; `sdd-workflow` and `feature`
  describe hat-switching instead of subagent spawning; `port-config` names
  Claude Code among the target hosts).
- **Not ported:** `plugin/agents/` (no subagents on Codex — roles are notes in
  the workflow skills), `plugin/hooks/` (the protected-branch hard block has no
  Codex equivalent; Branch Discipline is enforced as a written rule in
  `principles`), and `setup-template` (renders a `.claude/` tree — Claude-only).

Still hand-authored (not touched by generation): `codex/assets/`,
`codex/.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`, and this
note.
