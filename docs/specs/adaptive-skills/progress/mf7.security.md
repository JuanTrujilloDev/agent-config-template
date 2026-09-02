# MF7 security review — `setup.sh --overwrite-files`, `.github/workflows/ci.yml`

Scope: `git diff HEAD -- setup.sh .github/workflows/ci.yml` on `feature/v0.8.2-adaptive-skills` (plugin/setup.sh is byte-identical to setup.sh).
Method: read the full bash+python flow, then crafted fixtures in a scratch mktemp (never touched portfolio/).

## Verdict: 0 critical, 0 serious, 2 moderate, 0 dependency CVEs

## Verified clean

| Check | Result |
|---|---|
| Traversal in list (`../../x`, absolute, `.claude/../CLAUDE.md`, `./path`) | Rejected at step 6a by exact-match against `staged` (os.walk relpaths, never contain `..`). rc=1, target tree hash unchanged, no file outside written. |
| Untouchables under every list | `CLAUDE.md` (root) → `NON_MANAGED`, `settings.local.json` → basename filter; both rejected even when mixed with valid entries. Merge loop also `continue`s on settings.local.json before the `in OVERWRITE_FILES` branch. |
| Unknown path exits before any write | 6a runs before step 7/8; only prior side effect is pre-existing `mkdir -p "$TARGET"`. |
| `--overwrite-files` with `--overwrite`/no mode | Rejected in bash before python. |
| Relink removes only `.claude/CLAUDE.md` | `os.remove` gated on `symlink_conflict()` = isfile AND not islink at exactly `tpath(".claude/CLAUDE.md")`. When it is a symlink elsewhere, only the link is replaced; the link target is untouched (tested). |
| Printed copy-paste line | `SCRIPT`, `TARGET`, `ANSWERS_FILE` go through `shlex.quote` — tested with spaces, `$HOME`, quotes and backticks: pasted line is inert. `stale` list is unquoted but template-controlled; no template filename contains a shell metachar (`find core cursor codex | grep '[^A-Za-z0-9._/-]'` empty). |
| ci.yml | `pull_request` (not `_target`), no secrets referenced, runs only repo-tracked scripts under default read-only `GITHUB_TOKEN`. |

## Moderate

### M1 — `write_file` follows destination symlinks: a listed path can clobber a file outside TARGET
- `setup.sh` `write_file()` → `shutil.copy2(src, dst)`; `os.path.exists(tpath(rel))` is true for a symlink, so `--merge --overwrite-files` (and pre-existing `--overwrite`) writes *through* it.
- Repro: replace `.claude/patterns/desktop.md` in TARGET with a symlink to `$W/outside2`. Plan labels it `STALE-MANAGED` and puts it in the copy-paste line; running that line overwrote `outside2` with template content (rc=0). Same with an intermediate directory symlink (`.claude/patterns` → elsewhere: 6 files written there).
- Attack: hostile repo ships `.claude/<managed>.md` → `~/.zshrc`, `~/.ssh/config`, etc.; user runs the printed line → file destroyed (content is template text, so clobber not injection). Pre-existing under `--overwrite`; new flag adds a "just paste this" path.
- Fix (additive, in `write_file`): `real = os.path.realpath(dst); if not real.startswith(os.path.realpath(TARGET) + os.sep): print(error); sys.exit(1)`. Optionally `if os.path.islink(dst): os.remove(dst)` first so in-tree symlinks become regular files.
- Risk if changed: none for normal trees; users who deliberately symlink `.claude/rules` to a shared dir outside the repo will get a hard error instead of a silent write-through.

### M2 — Listing `.claude/CLAUDE.md` with no root `CLAUDE.md` destroys the user's instructions
- `setup.sh` merge branch: `os.remove(tpath(DOT_CLAUDE_MD))` runs unconditionally once listed; `relink_claude_md()` then points it at the *template's* just-added root `CLAUDE.md`.
- Repro: target with only `.claude/CLAUDE.md` = "USER INSTRUCTIONS", no root file → after `--merge --overwrite-files .claude/CLAUDE.md`: `+ CLAUDE.md` (template), `~ .claude/CLAUDE.md (relinked)`; user text gone, no backup.
- Mitigation already present: the plan never auto-adds `.claude/CLAUDE.md` to the copy-paste line — the user must type it. Still a one-flag data-loss path.
- Fix (in 6a, before writes): if `DOT_CLAUDE_MD in OVERWRITE_FILES and not os.path.isfile(tpath("CLAUDE.md"))` → error "no root CLAUDE.md to link to; move .claude/CLAUDE.md to CLAUDE.md first".
- Risk if changed: none; the error fires only in the exact scenario that loses data today.

## Not findings (noted)
- `.claude/settings.json` listed in `--overwrite-files` replaces instead of deep-merging — by design (`in OVERWRITE_FILES` branch precedes `SETTINGS_REL`); plan marks it `(mergeable)` and never adds it to the stale line.
- `relink_claude_md()` silently repoints a deliberate user symlink `.claude/CLAUDE.md → elsewhere` to `../CLAUDE.md` — pre-existing behaviour, unchanged by this diff.

## Re-check (fixed setup.sh, uncommitted; plugin/setup.sh byte-identical)

Fixtures re-run in a scratch mktemp (portfolio untouched). Baseline: python-django render with HEAD's `setup.sh` (`git archive`) vs fixed script → 36 entries, byte-identical incl. symlink targets.

| Finding | Status | Evidence |
|---|---|---|
| M1 write-through symlink | **RESOLVED** | Listed file → symlink outside: `--merge --overwrite-files`, `--overwrite` → rc=1, one stderr line, nothing newer anywhere in mktemp, outside file intact. Intermediate dir symlink (`.claude/patterns` → outside): same for both modes and for a fresh render into such a target (all 6 paths named); `--merge` alone writes nothing into the outside dir. Plan still lists it, writes nothing. |
| M2 `.claude/CLAUDE.md` with no root | **RESOLVED** | rc=1 before any write; user `.claude/CLAUDE.md` byte-kept, no root CLAUDE.md added. Root CLAUDE.md as symlink also refused. |
| `.claude/settings.json` in list | verified | rc=1 one line, alone and mixed with a valid entry (valid entry not written). |
| Bypasses | verified | `.claude/./X`, `.claude//X`, `X/`, `.claude/claude.md`, `.CLAUDE/CLAUDE.md`, `.Claude/Claude.MD`, `.claude/Settings.json`, `.claude/SETTINGS.JSON`, `.claude/Agents/backend-dev.md` — all rc=1 "not managed" (exact-match against `staged`, so APFS case-folding never reaches `os.path.exists`); target files byte-kept. |

### M3 (new, Moderate, pre-existing) — `merge_settings` writes through a symlinked `.claude/settings.json`
- `--merge` skips `check_inside` for existing files; `merge_settings()` opens `tpath(rel)` for write. Repro: `.claude/settings.json` → symlink to an outside valid-JSON file; `--merge` → rc=0, "1 settings merged", outside file modified.
- Attack: hostile repo ships `.claude/settings.json -> ~/.claude/settings.json`; plain `--merge` unions template `permissions.allow`/`hooks` into the user's global Claude settings (template-controlled content, so tampering not injection).
- Fix: `check_inside([rel])` as first line of `merge_settings` (mirrors `write_file`). Risk if changed: none for normal trees.
