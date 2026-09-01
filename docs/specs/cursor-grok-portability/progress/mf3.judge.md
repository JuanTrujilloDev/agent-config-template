# Judge: cursor-static-target  (@s7..@s10)

**Stats:** 4 hand-authored files (~172 LOC hand-authored: `scripts/build.sh` +47, `hosts/cursor/AGENTS.md` 99, `hosts/cursor/principles.mdc` 26, `features.json` status flip). Generated `cursor/` (22 files) rides along per D2. Well within the 8-file / 800-LOC contract limit.

**Scenario → verification (all re-run by judge, not taken on faith):**

- @s7 → PASS. `build.sh` run twice; cursor tree md5-identical across runs (`a9e7d8…` both). Tree contains AGENTS.md (templated, from `hosts/cursor/`), `principles.mdc` (`alwaysApply: true`, body **182 words** < 200, points at `@.claude/rules/principles.md`), `backend-style.mdc`/`frontend-style.mdc` (bodies = core rule content byte-for-byte after frontmatter; globs `{{src_dir}}/**` / `{{frontend_dir}}**`, matching core's own "Applies to" headers), `.cursor/mcp.json` derived from `core/.claude/mcp.json.example` (comment line reworded via sed, rest byte-identical), and byte copies of `core/.claude/agents/` + `core/.claude/rules/`.
- @s8 → PASS. Seeded edit to `core/.claude/rules/backend-style.md` without rebuild: `--check` exits 1, prints `DRIFT: cursor/ != generated (core/ + hosts/cursor/)`. Also verified the reverse direction (hand-edit to `cursor/AGENTS.md`) trips the same line. Restored; clean `--check` exits 0.
- @s9 → PASS. All three `.mdc` frontmatters parse with PyYAML; key sets: principles `{description, alwaysApply}`, backend/frontend `{description, globs}` — whitelist respected, no extras.
- @s10 → PASS. No `settings.json` anywhere under `cursor/`; `grep -rn '"hooks"' cursor/` empty; no `PreToolUse|PostToolUse|UserPromptSubmit` registrations. D3 double-fire prevention is structural as specified.

**Render proof (beyond the contract's minimum, since `--host` lands in MF5):** rendered the cursor tree through the real `setup.sh` renderer (scratch harness: `setup.sh` + cursor tree as `core/`) against 4 example answer sets (python-fastapi, node-nextjs, python-django, flutter-mobile). Zero placeholder leftovers (the single `{{` grep hit is JSX prose `style={{...}}` in `frontend-dev.md`, pre-existing in core, untouched by `VAR_RE`). `mcp.json` parses as valid JSON post-render in all combos (playwright+linear comma path, playwright-only, empty). `frontend-style.mdc` and `.claude/rules/frontend-style.md` correctly dropped when `has_frontend=no` — the `<!-- requires: -->` line-1 preservation in `mdc_rule` works.

**Content quality — hand-authored sources:**

- `hosts/cursor/AGENTS.md` vs `core/CLAUDE.md`: no contradictions found. Load-bearing rules present: branch discipline + full branch-naming table (both `branch_prefix` variants, nested `enforce_layer_split` sections), micro-PR limits, Definition of Done, agent map (pmo/orchestrator/dev/judge/security-reviewer, has_frontend/has_ui gated), commands block, trivial-work threshold (">50 lines or more than one def/class" — consistent with core's definition), security footer. Mustache sections balanced (checked by regex and by real render); all 21 vars + 4 section flags exist in core's answer/derived-var set.
- `hosts/cursor/principles.mdc`: genuinely a pointer per D8 — directs to the canonical file, each "What it covers" one-liner matches its source heading, 182 words.
- `build.sh` additions: same idiom as the MF1 codex block (function + derivation-rules header comment, `out="$1"; rm -rf; mkdir -p`, `--check` reuses the same `$tmp` + `diff -r` pattern, single call site each, header map and `Built:` echo updated). No parallel mechanism introduced.
- `python3 scripts/validate-packaging.py` → exit 0. Scope clean: only `scripts/build.sh`, `hosts/cursor/`, `cursor/`, and the `features.json` status flip touched.

### Blockers

None.

### Nits / notes for later mini-features

- **Implementer flag #1 (mcp.json not valid JSON pre-render) — deferral ACCEPTED.** @s7 requires only "derived from core/.claude/mcp.json.example", which holds; the source example has the identical property and the claude packaging has shipped that way all along. Verified post-render validity across all conditional combos. **However**, contract @s19 (MF7) literally says "`cursor/.cursor/mcp.json` parse[s] as JSON" — unsatisfiable on the checked-in tree unless MF7's validator strips/renders mustache sections first or the wording is amended at MF7. Hand this note to the MF7 implementer explicitly.
- `cursor/.cursor/rules/frontend-style.mdc:1` — the `<!-- requires: has_frontend -->` directive precedes the `---` frontmatter. Correct for setup.sh gating (verified), and the rendered file Cursor actually reads starts with `---`; but MF7's mdc frontmatter check must skip that line (existing `parse_frontmatter` likely expects `---` at line 1).
- `hosts/cursor/AGENTS.md` omits the Design First hard rule and the `mutation-tester` row from core/CLAUDE.md's agent map. Both are covered elsewhere in the rendered target (agent files are read natively; mutation testing is opt-in) — acceptable distillation, noting for the record.
- `hosts/cursor/AGENTS.md` has no commands/skills section; after MF4 ships `cursor/.claude/skills/`, consider one pointer line there (MF4's call, not a defect here).

### Verdict

- [x] APPROVED (with nits)   - [ ] CHANGES REQUESTED

Security-reviewer not required: no auth/permissions/external-input surface in this diff (file copies and text transforms in the build pipeline).
