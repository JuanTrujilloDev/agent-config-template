## Judge: mf6 companions  (@s40..@s47)

**Stats:** 15 files (10 hand-edited sources, 5 build mirrors), +111/-54 lines.
**Scenario → test:** @s40 → mf6 item-4 group/count greps ✓ ; @s41 → grammar/scope greps ✓ ; @s42 → usage/detect/plan/gate/`before` ✓ (command text itself not asserted) ; @s43 → codex SKILL greps + `build.sh --check` ✓ ; @s44 → orchestrator line + parity ✓ ; @s45 → README/plugin README/upgrade-guide greps ✓ ; @s46 → has_ui-falsy wording ✓ ; @s47 → recorded-list not re-asked ✓

Checks: smoke 352 pass / 0 fail; `build.sh --check` rc=0; `validate-packaging.py` ✓; double build byte-identical (same tree hash pre/b1/b2). Codex override has no `claude plugin|mcp` commands (only `~/.claude/skills/graphify/`, graphify's own registration path). `PONYTAIL_SUBAGENT_MATCHER` exists in ponytail README §Subagents (v4.9.0). No caveman, no `require.*Plane` anywhere in the diff. Item 4 is one question answerable with one token or a list; still 5 numbered items.

### Blockers
- `plugin/commands/setup-companions.md:48` and `hosts/codex/skills/setup-companions/SKILL.md:49` — recorded command `npx ui-ux-pro-max-cli init --ai claude|codex` is not in the upstream README. README (fetched 2026-09-02, v2.15.0) documents `npm install -g ui-ux-pro-max-cli` then `uipro init --ai claude` / `--ai codex` (or, Claude only, `/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill` + `/plugin install ui-ux-pro-max@ui-ux-pro-max-skill`). npx would work (package's single bin is `uipro`) but @s42/D12/Q5 require the exact README command. One-line fix per file; also make the @s42 smoke grep the literal command so a drift is caught.

### Nits
- `core/.claude/agents/orchestrator.md:40` (+ mirrors) — "whose name matches `PONYTAIL_SUBAGENT_MATCHER`" implies opt-in; upstream: unset = inject into every subagent. Suggest "(all subagents when unset)". Contract wording is met as written.
- Source-file count 10 vs budget 8 (`plugin/README.md`, `scripts/smoke.sh` are the extras, each one line). Total 15 incl. 5 mechanical mirrors; not a micro-PR violation in substance.
- Supply chain: every install (pip/uv, plugin marketplace, npm) sits behind step 2's explicit-yes gate, and step 8 keeps that gate in just-go mode. Only residual: npm install is unpinned (`@2.15.0` optional).

### Verdict
- [ ] APPROVED   - [x] CHANGES REQUESTED
