# Judge: cursor-hooks-and-skills  (@s11..@s14)

**Stats:** 5 hand-authored files (~156 LOC: `scripts/build.sh` +27, `hosts/cursor/hooks.json` 7, `hosts/cursor/hooks/branch-guard.sh` 72, `hosts/cursor/hooks/format-on-edit.sh` 49, `features.json` status flip). Generated files (2 hook copies + hooks.json + 8 SKILL.md) ride along per D2. Well within 8 files / 800 LOC.

**Scenario → verification (all re-run by judge):**

- @s11 → PASS. `build.sh` run + `--check` exits 0 (idempotent). `cursor/.cursor/hooks.json` parses as JSON; events exactly `{beforeShellExecution, afterFileEdit}` — no Claude event names anywhere under `cursor/` (`PreToolUse|PostToolUse|UserPromptSubmit` grep empty; no `settings.json` exists, D3 invariant holds). Both referenced scripts exist in the generated tree, `bash -n` clean, mode `-rwxr-xr-x` (source files in `hosts/cursor/hooks/` also +x, and `build.sh` re-chmods).
- @s12 → PASS. Rendered both adapters (`{{default_branch}}`→main, prefix section stripped) into a scratch git repo. On `main`: `git commit -m x` and `git push origin main` → `{"permission": "deny", ...}` with the typed-branch guidance (feature/fix/hotfix/refactor/chore checkout lines, protected list, override var). On `feature/x`: both allowed. Non-git dir: allowed. Unparseable payload / missing `command`: allowed (fail-open as contracted).
- @s13 → PASS. `.py` payload dispatches `ruff check --fix` (verified with an instrumented fake `ruff`); tool failure (exit 2, stderr "boom") → findings surfaced to stderr, still `{"permission":"allow"}`, exit 0. Never blocks on: unparseable payload, missing `file_path`, quoted-filename path, nonexistent file, tool crash. No `set -e` in the script — the "never blocks" claim is structural, not luck.
- @s14 → PASS. All 8 core commands → `cursor/.claude/skills/<c>/SKILL.md`. Frontmatter is exactly `name: <c>` / quoted `description` / `disable-model-invocation: true` (extra core keys like `argument-hint` correctly dropped). Bodies compared byte-for-byte against core command bodies via `cmp` — all 8 verbatim; subagent references preserved (D6). `design`'s `<!-- requires: has_ui -->` kept on line 1 — verified `setup.sh` strips that line at render time (plugin/setup.sh:235), so rendered skills start at `---`.

**Adapter fidelity (blessed pattern, not stretched):**

- `branch-guard.sh` vs `agent-enforcement.sh`: `branch_in_list` duplicated verbatim (2nd occurrence — rule of three says don't extract yet; contract explicitly left this to implementer's call), same protected-list default `{{default_branch}},master`, same guidance text minus the `.claude/HELP.md` pointer (correct: the cursor tree ships no HELP.md). The intentional remap — block mutating git commands instead of pre-edit — is exactly D5. No new abstraction layers; flat script, same shape as core.
- `format-on-edit.sh` vs `auto-format.sh`: `surface()`, per-extension dispatch, ruff/eslint `--fix` flags, and the "whole-file formatters stay in DoD" comments are line-for-line faithful. Only adapted: payload path (`file_path` top-level vs `tool_input.file_path`), project root (`git rev-parse --show-toplevel` vs `$CLAUDE_PROJECT_DIR` — right call, Cursor sets no such var), allow-JSON on stdout vs bare exit 0. The `go|rs|html` no-op arm was dropped — behavior identical (default case is also a no-op). No divergence found.

**Security/robustness probes:**

- JSON output injection: branch `weird"quote` set as protected, deny path exercised → output parses as valid JSON with the quote embedded safely. Both JSON emissions go through `json.dumps` / are static strings; env-var passing (`HOOK_INPUT`, `HOOK_MSG`) avoids shell interpolation into python. Verified, claim holds.
- Word-scan bypass (under-block): `git -C /x commit`, `GIT_DIR=/x git push`, `&&`/`;` chains, `git commit --amend`, `git    push` all correctly denied. Three vectors slip through: `sh -c "git push"` (quote before `git` not in the boundary class), `/usr/bin/git push` (absolute path), and a multi-line command with `git commit` on line 2 (grep is line-based). See Minor below.
- Over-block (safe direction, per the recorded ponytail ceiling): `git log --grep commit` and `git diff HEAD -- push` denied on main. Annoying but fail-safe; matches the comment's stated trade.
- Fail-open on missing/broken python3 → allow. Same posture as the core hook (empty SUMMARY → exit 0); faithful, not a regression.

**Implementer decisions spot-checked:**

- #3 (no setup-template exclusion): verified — `setup-template.md` exists only in `plugin/commands/`, not `core/.claude/commands/`; loop over core is exclusion-free by construction. Sound.
- #4 (env var back-compat): `AGENT_CONFIG_PROTECTED_BRANCHES` primary with `CLAUDE_CONFIG_PROTECTED_BRANCHES` fallback — sound, and the deny message advertises the right var. Cross-host note in Nits.
- #5 (word-scan ponytail comment): present (branch-guard.sh:34–36), names the ceiling ("safe over-block") and the upgrade path ("real tokenizing"). Honest about exactly the limitation the probes confirmed.
- Remaining decisions verified against artifacts: D9 not porting coding-reminder (no `beforeSubmitPrompt` registered), requires-line preservation (works end-to-end), verbatim bodies, format hook allow-always — all match the code.

### Blockers

None.

### Minor

- `hosts/cursor/hooks/branch-guard.sh:37` — three under-block vectors: `sh -c "git push"`, `/usr/bin/git push`, and multi-line commands (`grep` matches per line). Severity assessed as Minor, not Blocker: this is advisory-depth defense against a cooperating agent's accidental commit (D5 documents the gap; a determined bypass defeats any word-scan, and the Claude-side hook has equivalent limits). Cheap hardening for a follow-up: add `"'/` to the boundary character class and pipe `$CMD` through `tr '\n' ' '` before the grep — catches all three probed vectors in ~1 line. Not required for merge; the matrix doc (MF6/@s18) should keep calling this a gap, not a hard block.

### Nits

- Env-var split across hosts: a dual-host render (MF5 @s22) will have the Claude hook honoring only `CLAUDE_CONFIG_PROTECTED_BRANCHES` while the Cursor hook prefers `AGENT_CONFIG_PROTECTED_BRANCHES`. The fallback keeps one shared var working (`CLAUDE_...` set → both hooks agree), so this is cosmetic — but docs (MF6) should recommend `CLAUDE_CONFIG_PROTECTED_BRANCHES` as the cross-host override until core learns the new name.
- `scripts/build.sh` description extraction (`sed -n 's/^description: //p'`) would mis-emit YAML if a core description ever contains an inner double quote. None do today, and MF7's validator (@s19/@s20) will catch it if one appears. No action.
- `format-on-edit.sh` emits `{"permission":"allow"}` on an *after* event where Cursor likely ignores the verdict — harmless, keeps the two adapters symmetrical.

### Verdict

- [x] APPROVED   - [ ] CHANGES REQUESTED

No security-reviewer escalation required: the hooks consume host-provided payloads and the injection surface (JSON output) was probed and is safe; no auth/permissions/data-exposure boundary is touched. The under-block finding is documented-gap territory (D5), not a security regression.
