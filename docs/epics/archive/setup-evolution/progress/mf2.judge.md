# Judge: autonomy-mode  (@s7..@s12)

**Stats:** 24 files, 153+/19− total churn — 9 hand-authored (core/{orchestrator,feature,pr,coding-reminder.sh,principles,CLAUDE.md}, setup.sh, plugin/commands/setup-template.md, features.json ≈ 60 LOC), 15 generated mirrors ride along per D10 convention (mf1 precedent). **Hand-authored count is 9 vs max_files=8** — see Major 2.

**Scenario → verification:**

| Scenario | Evidence | Status |
|---|---|---|
| @s7 | Rendered project, bash 3.2 (`3.2.57 arm64`): `autonomy_mode=autonomous` → exactly one line `mode: autonomous — say 'gate me' to switch`, byte-exact vs contract | ✓ |
| @s8 | `gated`, key-absent, and no-file all → gated banner + today's reminder intact, exit 0 | ✓ |
| @s9 | principles.md "Session keyword overrides": all three keywords ("just go" / "gate me" / "stop before commit"), "never write them to any file" — grep-verifiable | ✓ |
| @s10 | "ALWAYS apply regardless of mode" in principles.md, pr.md step 6, orchestrator.md step 9, feature.md DoD. No merge command exists; pr.md is the only push/publish surface — covered | ✓ |
| @s11 | principles.md "Hosts without hooks" + 1 CLAUDE.md line; shipped to cursor/plugin-cursor mirrors via build; no Cursor hook added (per D9 / release scope) | ✓ |
| @s12 | Junk value → no banner; binary garbage / unreadable (chmod 000) / spaced-key files → exit 0, **zero stderr**, reminder intact, prompt never blocked. Deviation on "no banner" for unreadable file — see ruling | ✓* |

Full matrix run (14 cases, /bin/bash 3.2): no-file, autonomous, gated, key-absent, junk value, shell-metachar injection payload, 512B urandom file, chmod-000 file, spaced key, duplicate keys (first wins via `head -1`), non-coding prompt ×2 (no output even with prefs present — banner correctly sits after the keyword filter), empty stdin, garbage JSON. All exit 0, no stderr, in every case.

## Rulings on interpretation calls

1. **Garbled file → gated banner; explicit junk value → no banner: UPHELD.** A garbled/unparseable file is indistinguishable from "key absent" at the `sed` layer, and @s8 + ratified D5/Q2 (Gate 1) make absent = gated → gated banner is the *true* statement of what the agent will do. An explicit unrecognized value matches @s12's literal "no banner". The protective core of @s12 (exit 0, no error output, never blocks) is fully met in all cases. **Condition:** @s12's text says "no banner" for a *malformed or unreadable file* while the hook prints the gated banner there — amend @s12 to record the settled semantics ("malformed value → no banner; unparseable/unreadable file → default gated banner; always exit 0, no stderr"). One line; contract is the signed artifact.
2. **No-file → gated banner: UPHELD.** @s8's parenthetical explicitly permits it; D5/Q2 ratified gated as default. Showing the default beats silence.

## Security review (prompt-injection via prefs file)

**PASS.** `$AUTONOMY` feeds only the `case` matcher; every string that reaches the injected reminder is a fixed literal in the script. Verified empirically: `autonomy_mode=autonomous"; echo INJECTED; "` and binary garbage produce zero file-derived output. No `eval`, no `source`, no expansion of file content; `2>/dev/null` + `set -uo pipefail` interplay checked under bash 3.2. Residual note (accepted): a hostile repo could *commit* `.claude/answers.local.env` to flip a clone to `autonomous` — impact is bounded because the value can't inject text and push/merge/publish/destructive gates ALWAYS apply per principles.md.

## Hook change quality

~9 lines including the why-comment; `sed -n 's/^…//p'`, `case`, `head -1` — POSIX, no bash-4isms, no new dependencies; matches the contract's Design note (one sed read + fixed echo) exactly. Placement after the coding-keyword filter is correct.

## Process

- `bash scripts/build.sh` ×2 → working-tree diff checksum byte-identical before/after; `validate-packaging.py` green (v0.8.0 — bump correctly deferred to mf6).
- Mirror diffs scanned: autonomy content only, zero drive-by changes.
- Branch typed (`feature/setup-evolution`), main untouched.
- sdd-workflow.md gates uncontradicted: Gates 1–2 are contract/tests, orthogonal to the commit-step autonomy wording. pr.md confirmation correctly mode-independent.
- CLAUDE.md always-loaded cost: exactly 1 line.

### Blockers

- None.

### Major

1. **`core/.claude/commands/commit.md:23-24` contradicts autonomous mode.** It unconditionally requires "explicit confirmation" before `git commit`, and principles.md's Commits section routes every green point "via `/commit`" — so an autonomous session following instructions literally still pauses at every commit, hollowing out @s7/@s8's purpose. `commit.md` is in mf2's `files_hint` and was not touched. Fix: one clause mirroring the pr.md pattern (confirmation follows autonomy mode; commit is not in the ALWAYS list — push/merge/publish/destructive are).
2. **`plugin/commands/setup-template.md` autonomy question is out of scope (mf3, @s15/@s16) and pushes hand-authored files to 9 vs max_files=8.** mf3's frontier-round rewrite will restructure this exact file and wants autonomy folded into the ONE numbered round, not a standalone step-2 question. Fix: revert this hunk and carry it in mf3 — resolves the micro-PR overage simultaneously (8/8, ~55 LOC, well under 350).

### Minor

- Amend @s12 wording per Ruling 1 (record the settled malformed-file semantics in the contract).

### Nits

- CRLF-edited prefs file (`autonomous\r`) silently degrades to no banner; a `tr -d '\r'` (or `[\r]*` in the sed) would be one token. Optional.
- "just go" now carries two meanings (Read-Before-Write narration bypass in principles.md + autonomy switch). Compatible in spirit; consider a cross-reference if it ever confuses.
- `docs/install/host-capability-matrix.md` (in files_hint) gained no autonomy row; not contract-required (@s11 only names principles.md/CLAUDE.md), but a one-line row would keep the matrix honest.

### Verdict

- [ ] APPROVED   - [x] CHANGES REQUESTED

Both Majors are one-hunk fixes: add the autonomy clause to `commit.md`, move the setup-template hunk to mf3. With those done (plus the @s12 contract amendment), this approves — hook behavior, security posture, instruction traceability, and build hygiene are all verified green.

## Re-review (fix pass, 2026-09-01)

Scope: the two Majors + @s12 amendment + build hygiene only.

1. **Major 1 (commit.md) — FIXED.** `core/.claude/commands/commit.md:23-24` now makes the commit-message confirmation `gated`-mode-only; `autonomous` proceeds after judge review, explicitly citing principles.md "Autonomy Mode". Push/PR confirmations stated as never skipped; the `{{default_branch}}` protection line is untouched and unconditional. No contradiction with principles.md (autonomous = no pause at commit step; ALWAYS list = push/merge/publish/destructive) or pr.md (its step 6 remains mode-independent). Mirrors verified: plugin/template commit.md byte-identical to core; cursor + plugin-cursor commit SKILL.md carry the same two lines.
2. **Major 2 (setup-template.md) — FIXED.** `git diff HEAD -- plugin/commands/setup-template.md` is empty; the only `autonomy_mode` mention is the MF1 Local-prefs table row committed in `8810912`. Hand-authored count back to 8/8.
3. **@s12 amendment — matches Ruling 1.** Contract now reads: unrecognized value → no banner; unreadable/garbled file → gated banner; always exit 0, no error output; amendment provenance noted inline.
4. **Hygiene:** `scripts/build.sh` idempotent (working-tree diff byte-identical pre/post), `scripts/build.sh --check` → "generated trees in sync", `validate-packaging.py` green @ v0.8.0.

### Verdict (final)

- [x] APPROVED   - [ ] CHANGES REQUESTED
