# Judge: host-aware-install  (@s15, @s22..@s24)

**Stats:** 5 hand-authored files (~190 LOC ins) + generated mirrors (plugin/setup.sh, plugin/template.config.yaml) + generated bundles (plugin/cursor/, plugin/codex/skills/). Within ≤6 files / ≤500 LOC. Branch typed (`feature/cursor-grok-portability`), main untouched, docs untouched (MF6 scope respected).

**Scenario → verification** (all re-run live against temp targets, not read off the diff):

- @s15 default byte-identity → `git show HEAD:setup.sh` rendered into t-old vs new setup.sh into t-new, `diff -r` empty ✓. `--host claude` == default ✓. `--host grok` delta = AGENTS.md only, zero `{{}}` ✓. `--host codex` = AGENTS.md + `.agents/skills/` byte-equal to `codex/skills/` ✓. `--host opencode` exits 1 naming `claude, cursor, codex (alias: grok)` and pointing to port-config ✓.
- @s22 `--host claude,cursor` → both trees, zero `{{}}`, `.claude/settings.json` hooks = {PreToolUse, PostToolUse, UserPromptSubmit} only, `.cursor/hooks.json` = {beforeShellExecution, afterFileEdit} only, no event doubled ✓. Collision abort verified by tampering a copied cursor tree's `.claude/agents/judge.md`: exit 1, error names the path, **target left with 0 files** (staging-before-apply holds) ✓. `cursor,claude` vs `claude,cursor`: `diff -r` empty (order-insensitive via canonical WANT_* ordering) ✓.
- @s23 `TARGET_HOSTS=claude,cursor` in answers.env renders exactly the multi set (diff-identical to `--host claude,cursor`) ✓; `--host codex` with same answers overrides (diff-identical to codex-only) ✓; re-render on existing target → plan shows 36/36 SAME ✓; `template.config.yaml` documents `target_hosts` multi-value, default `claude` ✓.
- @s24 setup-template.md: exactly one multi-select host question, inferred-default rule stated (claude always; cursor on `.cursor/`; codex on Codex project config), recorded as `TARGET_HOSTS`; wording-only inside existing step 2, no new steps ✓.

**Renderer integrity:** NOT duplicated — stage_file/stage_tree is a lift of the old walk body; every host feeds one staging dir through the same render()/apply pipeline. Non-destructive semantics re-proven: plan mode on an existing config writes nothing (rc=1 with per-file plan); `--merge` union-merged permissions.allow + additive hooks (user's `CustomUser` hook and `Bash(ls:*)` kept, template entries added), existing CLAUDE.md kept, `settings.local.json` byte-untouched. Detection markers correctly extend per selected host (AGENTS.md, `.cursor/*`, `.agents/skills`) without touching the claude-only default path.

**Bash 3.2:** no `declare -A`/`readarray`/`mapfile`/`${x^}`/`|&` in new code; `bash -n` clean; host parsing is plain `case` + `tr` — safe on stock macOS bash.

**Q4:** `.agents/skills/` for codex renders matches the spec's recommendation ("project-local Codex skill-discovery path, verify at implementation"), is consistent with the repo's own `.agents/plugins/marketplace.json` precedent and current official Codex project-skill discovery. Sound.

**build.sh bundling + --check:** `plugin/cursor` and `plugin/codex/skills` byte-equal to `cursor/` and `codex/skills/`; seeded drift in `plugin/cursor/AGENTS.md` → `--check` exits 1 with `DRIFT: plugin/cursor != cursor/`; restored clean. `plugin/setup.sh --host cursor,codex` renders correctly from the bundle. `validate-packaging.py` green.

**Three recorded decisions:**
1. Bundle generated trees into `plugin/` — sound; mirrors the `plugin/template` precedent, drift-guarded by `--check`, and is what makes the bundled `plugin/setup.sh` self-sufficient.
2. claude+grok double-walk resolving as identical-content no-op — sound and verified (`claude,grok` == `grok` render); trades a cheap second walk for zero special-casing.
3. Differing collision aborts the whole render — sound, matches D4/@s22, and the staging-first design means an abort leaves the target pristine (verified).

### Adversarial findings

- **Skeptic:** empty `--host ""`/empty `TARGET_HOSTS=` fall through to the claude default; commented `# TARGET_HOSTS=` lines correctly ignored by the `^TARGET_HOSTS=` sed anchor; last-line-wins on duplicates; missing cursor/codex source trees are guarded with actionable errors before python runs; collision exits propagate via `PY_RC` and staging is cleaned in `finally`. No hole found that reaches a written target.
- **Architect:** implementation is the contract's design note almost literally — host→tree mapping + a loop over the existing renderer, single call site, no second renderer. Fits.
- **Minimalist:** nothing speculative found; `grok` in template.config.yaml choices is justified by D4. Nothing to prune.

### Blockers

None.

### Nits

- setup.sh:492 — `skipped` double-counts when a host set walks the template tree twice (`--host claude,grok` prints "skipped 20 files" where a single render skips 10). Cosmetic message only; dedupe the count or skip re-walk if already staged.
- setup.sh:169/173 — "run scripts/build.sh first" is wrong advice inside an installed plugin bundle (no scripts/ ships). Unreachable in practice since build.sh always bundles the trees; reword when convenient.
- Host values are case-sensitive (`--host Claude` → unsupported). Matches the documented set; acceptable.
- Quoted `TARGET_HOSTS="claude,cursor"` in answers.env would fail (quotes kept). Consistent with the existing answers parser's no-quote convention; not new behavior.

### Verdict

- [x] APPROVED   - [ ] CHANGES REQUESTED

No behavior change on the no-flag path (byte-identity proven against HEAD). Security-reviewer not required: no auth/permissions/external-input surface changed — CLI args and answers parsing follow the pre-existing local-trust model.
