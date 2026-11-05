## Judge: mf7 merge-reporting-release  (@s48..@s57)

**Stats:** 9 files (8 hand-authored + plugin/setup.sh mirror), +178/-32 lines. Branch feature/v0.8.2-adaptive-skills, main untouched.
**Scenario → test:** @s48 → mf7-merge.sh "plan exits 1 / three labels / writes nothing" ✓ ; @s49 → "exactly one --overwrite-files line / list = STALE-MANAGED only" ✓ ; @s50 → "--merge alone keeps…" + "overwrite-files … 1 overwritten" ✓ ; @s51 → ".claude/CLAUDE.md is a symlink to ../CLAUDE.md / root untouched" ✓ ; @s52 → unknown path / no mode / --overwrite → one-line error, nothing written ✓ ; @s53 → bash -n, no declare -A, ast.parse, plugin parity ✓ ; @s54 → section greps ✓ (see Blocker 2: passes on wrong assertion) ; @s55 → ci greps ✓ ; @s56 → --help grep ✓ ; @s57 → manifests + validate-packaging ✓

Verified by execution: `bash scripts/smoke.sh` 422 PASS / 0 FAIL under /bin/bash 3.2.57. HEAD vs new `setup.sh` rendered into temp dirs for fresh, `--host cursor,codex`, plan, `--merge`, `--overwrite`, `--abort`, `--mode bogus`: every target tree `diff -r` identical; stdout differs only in the plan labels, the copy-paste line, and the contract-mandated `0 overwritten` token in the merge summary. `ci.yml` parses (yaml.safe_load), grok/codex renders + `bash scripts/smoke.sh` wired into `render-smoke`. `validate-packaging.py` → `packaging valid @ v0.8.2`. Real portfolio plan (no mode): rc=1, `find -newer` empty, git dirty count unchanged (6→6); printed 32 STALE-MANAGED (all `.claude/{agents,commands,hooks,rules,skills}`, `.agents/skills/*`, `.cursor/rules/principles.mdc`), `.claude/settings.json (mergeable)` excluded from the line, 15 ADD, `CUSTOMIZED CLAUDE.md`, `SYMLINK-CONFLICT .claude/CLAUDE.md`, 26 SAME.

### Blockers
- setup.sh:381 (`NON_MANAGED = {"CLAUDE.md"}`) — deviates from D13 without justification. D13 enumerates the STALE-MANAGED set (`.claude/{agents,commands,rules,hooks,skills}/`, `.claude/HELP.md`, `.cursor/`, `.agents/skills/`, `AGENTS.md`); the implementation labels *every* staged path except root `CLAUDE.md`. Reproduced: append one line to `docs/design-system/MASTER.md` (D8: user-filled brand file with `TODO:` markers) → plan prints `STALE-MANAGED docs/design-system/MASTER.md` and puts it in the "safe" copy-paste line → pasting the line overwrites the user's brand system. Same class as `.claude/patterns/*.md` (harmless, template-owned) but MASTER.md is project-specific by design — exactly what D13 says is never auto-listed. Fix: exclude `docs/design-system/` from `stale` (label it CUSTOMIZED or leave it out of the printed line) or amend D13 in writing.
- docs/upgrade-guide.md:65-73 (@s54 accuracy) — three factual errors vs shipped v0.8.2: (1) `output_style` values are `concise|balanced|detailed|terse` (core/.claude/rules/principles.md:193, contract @s2), guide says `default|concise|full|terse`; (2) `agent_style` is `terse|descriptive` (principles.md:218, @s59), guide says "the same four values"; (3) both keys are read from the personal, gitignored `.claude/answers.local.env`, guide presents them as `answers.env` keys. The @s54 smoke regexes (`output_style=(concise|full|terse)`, `agent_style.*default.*terse`) pass on this wrong text — tighten them to the real value lists so the test bites.

### Nits
- scripts/smoke/mf7-merge.sh — new hand-authored file makes 8 hand-authored files vs features.json `max_files: 7`. Caused by the pre-existing smoke split (a36e917) that features.json predates; within the 12-file micro-PR limit. Update features.json rather than fold the file back.
- setup.sh:560 — `--overwrite-files .claude/settings.json` is accepted and wholesale-replaces the user's settings (lost `Bash(mine:*)` in probe) although the plan labels it `(mergeable)`. Explicit opt-in and excluded from the printed line, so acceptable; consider rejecting it or noting in the label.
- setup.sh:527 — `--answers -` (stdin) yields a printed line with `--answers -`, not re-runnable as-is. Edge; leave.
- docs/upgrade-guide.md:81 — STALE-MANAGED scope list omits `.claude/patterns/`, `.claude/HELP.md`, `mcp.json.example`; align once Blocker 1 settles the set.
- security-reviewer is listed in features.json `reviews` and not yet run; setup.sh consumes external input (`--overwrite-files`, answers) — mandatory before merge.

### Adversarial findings
- Skeptic: unknown-path check (setup.sh:398) runs after render but before `present` detection and any target write — confirmed nothing lands in the target; error is one stderr line. Listing `.claude/CLAUDE.md` when it is already a symlink is a silent no-op (fine). Root `CLAUDE.md` missing + `.claude/CLAUDE.md` listed: staged loop ADDs root first, then relink succeeds (fine). Whitespace after commas (`a, b`) → "unknown path" (strict; fine). Dropped: duplicate entries, `--overwrite-files ""` — no failure mode.
- Architect: shape matches D13 Design notes (labels in `print_plan`, one flag, one merge branch); `symlink_conflict()` and `overwritable` are the minimum. Passing `SCRIPT`/`ANSWERS_FILE` env solely to print the line is acceptable. The D13 set deviation is the one real architectural miss (Blocker 1).
- Minimalist: no dead code, no speculative options; `diffs += 1` for the symlink conflict changes the "differ" count — intentional and readable. Nothing to prune.

### Verdict
- [ ] APPROVED   - [x] CHANGES REQUESTED

## Re-review (fixes only)

- Blocker 1 (D13 set) — fixed. `non_managed()` covers root `CLAUDE.md`, `docs/CONTEXT.md`, `docs/design-system/**`; `overwritable` excludes them so they can be neither listed nor pasted. Smoke fixture appends a Colors section to `docs/design-system/MASTER.md` → `CUSTOMIZED docs/design-system/MASTER.md`, zero `STALE-MANAGED` hits, `@s49` list == `backend-dev.md,backend-style.md` exactly. Verified by execution.
- Blocker 2 (@s54 accuracy) — fixed. Guide now states `output_style=concise|balanced|detailed|terse` (default `concise`), `agent_style=terse|descriptive` (default `terse`), both in gitignored `.claude/answers.local.env`; matches principles.md:193/218. Smoke regexes are literal under `grep -E` (`concise\|balanced\|detailed\|terse`, `terse\|descriptive`) plus a negative check for the old `default|full` / "same four values" text; STALE-MANAGED scope list now includes patterns, HELP.md, mcp.json.example.
- Nit (features.json) — reconciled: `max_files: 8`, `scripts/smoke/mf7-merge.sh` added to files, budget_note explains the smoke split.
- Security M1/M2 landed (`check_inside`, root-CLAUDE.md precondition) with smoke coverage; `mf7.security.md` present.

Execution: smoke 439 PASS / 0 FAIL; `build.sh` 0, `build.sh --check` 0, double build identical (git diff --stat md5 equal), `validate-packaging` → v0.8.2; `setup.sh` == `plugin/setup.sh`. HEAD-vs-new render into temp dirs: fresh, `--host cursor,codex`, plan, `--merge`, `--overwrite` — all five target trees `diff -r` identical; stdout differs only in labels, the printed line, and `0 overwritten`. Portfolio read-only plan (no mode): rc=1, dirty 6→6, `find -newer` 0; `docs/design-system/MASTER.md` is ADD (not present there) and absent from the copy-paste line; line contains only `.claude/`, `.agents/skills/`, `.cursor/` paths; `CUSTOMIZED CLAUDE.md`, `SYMLINK-CONFLICT .claude/CLAUDE.md` as before.

### Verdict
- [x] APPROVED   - [ ] CHANGES REQUESTED
