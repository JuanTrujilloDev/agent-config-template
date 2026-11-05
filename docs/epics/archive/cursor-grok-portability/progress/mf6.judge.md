# Judge: portability-docs  (@s16..@s18)

**Stats:** 5 files (3 new docs, README + features.json edits), ~133 lines added. Well inside ≤5 files / ≤900 LOC.
**Scenario → artifact:** @s16 → `docs/install/cursor.md` ✓ ; @s17 → `docs/install/grok.md` ✓ ; @s18 → `docs/install/host-capability-matrix.md` ✓ ; README pointer (design notes) ✓.

## Letter-of-contract

- **@s16** — Lead line "Skills and agents: zero porting. Rules, hooks, commands: generated." present verbatim (cursor.md:3). Render flow (`setup.sh --host cursor`) documented. `tools:` frontmatter-ignored note + `readonly: true` guidance for judge/security-reviewer/ui-designer present. Branch hard-block gap stated with @s12 semantics (deny commit/push, edits not blocked, guardrail-not-boundary). ✓
- **@s17** — `.claude` tree + AGENTS.md + CLAUDE.md native discovery documented; `grok inspect` shown as verification; `--host grok` documented as claude tree + AGENTS.md (D4); "no `grok/` packaging tree" stated and true (repo root has none). ✓
- **@s18** — Table is exactly hosts {Claude Code, Codex, Cursor, Grok Build, AGENTS.md-only} × capabilities {Subagents, Hooks, Branch hard-block, MCP, Skills discovery, Commands/skills invocation}. Cell statuses match @s4 (codex generated skills / hook gap), @s11 (cursor generated hooks on native events), @s12 (cursor branch guard partial, over-block ceiling), @s17 (Grok column all native). ✓

## Executable claims — all run and confirmed

- `./setup.sh --host cursor --target <tmp> --answers examples/python-fastapi/answers.env` → exit 0; tree matches the "What you get" list exactly: `AGENTS.md`, `.cursor/rules/*.mdc`, `.cursor/mcp.json`, `.cursor/hooks.json` + 2 adapters, `.claude/agents/`, `.claude/skills/` with `disable-model-invocation: true`; **no** `.claude/settings.json` (no Claude hooks surface, as claimed); zero `{{...}}` leftovers. Frontend-conditional items (`design` skill, `ui-designer`, `frontend-style.mdc`) confirmed present on a node-nextjs render.
- `./setup.sh --host grok --target <tmp>` → `diff -r` vs a plain claude render differs **only** by `AGENTS.md` — grok.md's "the alias just adds the AGENTS.md shortcut" is byte-accurate.
- `--host opencode` → exit 1 naming supported set + port-config skill; message's "opencode, gemini, windsurf" matches README's updated port-config list (Cursor correctly removed).
- Branch guard payload tests: `git push` on main → deny with typed-branch guidance; `sh -c "git push"` → deny; `/usr/bin/git push` → deny; documented over-block `git log --grep commit` → deny (as the doc honestly claims); `git push` on `feature/x` → allow. Env vars verified in source: `AGENT_CONFIG_PROTECTED_BRANCHES` with `CLAUDE_CONFIG_PROTECTED_BRANCHES` fallback (`hosts/cursor/hooks/branch-guard.sh:53`); core hook reads only `CLAUDE_CONFIG_*` (`core/.claude/hooks/agent-enforcement.sh:67`) — the dual-render override advice is correct.
- Format adapter: `ruff check --fix` path confirmed (`hosts/cursor/hooks/format-on-edit.sh:34`), never blocks.
- `bash -n` passes on both rendered adapters; `hooks.json` registers only `beforeShellExecution`/`afterFileEdit`.
- TARGET_HOSTS claims: `setup.sh` parses `TARGET_HOSTS` from answers with `--host` winning (setup.sh:135-139); `template.config.yaml` documents `target_hosts`; `plugin/commands/setup-template.md` asks exactly one multi-select host question with `cursor` added by default when `.cursor/` exists — matches cursor.md:19-22 word for word in substance.
- Matrix footnote 5 (`--host codex` → `.agents/skills/`) confirmed by render. Unverifiable host claims (Cursor native `.claude` reading, Grok discovery, `grok inspect`) are the spec's ratified external facts (spec.md D4/D10) and are presented as host behavior, not our guarantee. ✓

## Consistency / tone

- README pointer added, one sentence, port-config list now OpenCode/Gemini/Windsurf — consistent with setup.sh error and matrix's AGENTS.md-only host list.
- Cross-links (cursor.md ↔ matrix ↔ grok.md) all resolve. Matrix legend (native/generated/gap) used consistently.
- Tone matches claude.md/codex.md: terse, factual, no marketing.
- Scope clean: only the 3 contracted docs + README + features.json status flip.

### Blockers

None.

### Major

None.

### Minor

- `docs/install/codex.md:30` — pre-existing line "No `setup-template`. It renders a `.claude/` project tree — Claude-only" has a now-stale rationale: since MF5, `setup.sh`/`setup-template` render codex (`.agents/skills/`) and cursor trees too, and the new matrix footnote 5 says so. The claim itself ("no setup-template skill on Codex") remains true — only the reason is outdated. Not in @s16–@s18 scope and fixing it here would exceed the 5-file budget; recommend a one-line follow-up (MF7 or a chore commit).

### Nits

- `docs/install/cursor.md:31` — "every slash command (…`design`…)" is the full-stack set; backend-only stacks omit `design` (and `ui-designer`, `frontend-style.mdc`). Same presentation style as claude.md, so acceptable — a parenthetical "(frontend commands stack-dependent)" would be strictly more accurate.

### Verdict

- [x] APPROVED   - [ ] CHANGES REQUESTED
