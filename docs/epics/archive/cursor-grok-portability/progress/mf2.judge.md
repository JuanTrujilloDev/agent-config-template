# Judge: model-agnostic-phrasing  (@s5..@s6)

**Stats:** 7 files (4 source: core/CLAUDE.md, core/.claude/HELP.md, core/.claude/agents/judge.md, features.json; 3 generated mirror under plugin/template/), 25/25 lines. Well within 12 files / 400 LOC.

**Scenario → verification:**
- @s5 → full grep of `core/CLAUDE.md`, `core/.claude/{rules,agents,commands,hooks}` + HELP.md, re-run independently ✓
- @s6 → `build.sh` ✓, `build.sh --check` ("generated trees in sync") ✓, `validate-packaging.py` (exit 0) ✓; placeholder set byte-identical vs HEAD (`git archive HEAD` extract, `grep -rho '{{[^}]*}}' | sort -u` diff empty) ✓; headings unchanged in all three edited files ✓; file set unchanged (all M, no A/D) ✓

## @s5 detail — surviving "Claude" matches, each classified

| Match | Class | Verdict |
|---|---|---|
| `.claude/...` path references (everywhere) | path | keep ✓ |
| `CLAUDE_CONFIG_PROTECTED_BRANCHES`, `CLAUDE_PROJECT_DIR` (hooks) | env var | keep ✓ |
| `claude --agent orchestrator` (orchestrator.md:31) | CLI invocation | keep ✓ |
| "Claude Code subagents cannot spawn other subagents" (orchestrator.md:24, feature.md:21) | factual host limitation | keep ✓ |
| "PreToolUse/PostToolUse hook for Claude Code" (hook headers) | factual host mechanic | keep ✓ |
| CLAUDE.md:99 `## Claude Code Workflow` heading | factual host section; heading must stay per @s6 | keep ✓ |
| CLAUDE.md:171 Dynamic Context | gained the exact "Claude Code only" qualifier @s5 prescribes, plus "(other hosts treat these lines as plain text)" | ✓ |
| HELP.md:1 title "Claude Code Usage Guide" | factual host naming of the guide in `.claude/` | keep ✓ (see Nit 1) |

No actor idioms remain: no "Claude will/should", "ask Claude", "Claude pulls/fetches", speaker-label "Claude:", or universalized "Claude Code expands". Rewordings checked for wrongly-genericized mechanics: none found.

## Meaning preservation (hunk-by-hunk)

- **judge.md** "three Claude lenses" → "three same-model lenses": the same-model vs cross-model contrast is preserved — arguably sharpened, since "same-model" names the property the trade-off hinges on. ✓
- **HELP.md speaker labels** `Claude:` → `Agent: ` (two spaces): column alignment of the transcript preserved; dialogue coherent. ✓
- **HELP.md** "Claude didn't spawn an agent" → "No agent was spawned"; "Restart Claude Code" → "Restart the host app": semantics intact (the mcp.json fix applies on any host reading `.claude/mcp.json`). ✓
- **CLAUDE.md Dynamic Context**: universal claim correctly narrowed to Claude Code without deleting the feature doc, exactly per contract. ✓

## Micro-PR / process

- 25 LOC, 4 source files, mirror regenerated (not hand-edited — `--check` green). Branch `feature/cursor-grok-portability` is typed; main untouched. Surgical: zero non-reword edits. No security surface touched — security-reviewer not required.

### Blockers
- none

### Nits
1. `core/.claude/HELP.md:1` — title keeps "Claude Code Usage Guide" while the body is now agent-generic. Contract permits it (factual host naming; also a heading, frozen by @s6). Note for MF3: the cursor render may want a host-appropriate title.
2. `docs/specs/cursor-grok-portability/features.json` — status left `in_progress`; flip to `done` on commit after this approval.

### Verdict
- [x] APPROVED   - [ ] CHANGES REQUESTED
