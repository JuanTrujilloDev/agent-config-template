## Judge: output-style  (@s1..@s9)

**Stats:** 9 hand-authored files (+ `features.json` status flip), 78+/15- hand-authored LOC; 20 paths touched including generated mirrors. Branch `feature/v0.8.2-adaptive-skills`, `main` untouched.
**Scenario → test:** @s1 → smoke `@s1 no prefs` ✓ ; @s2 → smoke `@s2 autonomous+detailed`, `gated+balanced`, `gated+terse`, `autonomous+terse` ✓ ; @s3 → smoke `@s3 unrecognized` + `value not leaked` ✓ ; @s4 → smoke `@s4 non-coding` + `empty output` ✓ ; @s5 → inspected `core/.claude/rules/principles.md` L183-206 (all eight `concise` rules, `balanced`/`detailed` = length only) ✓ ; @s6 → same section L199-206 (security, irreversible, explain, ambiguity 2–4 ranked, debugging >3 turns; session phrases never written) ✓ ; @s7 → `core/CLAUDE.md` L24 + `hosts/cursor/principles.mdc` L23-26 read both keys and print the @s1 banner; `grep -rn verbosity template.config.yaml plugin/commands/setup-template.md` empty; `output_style` in both scope tables ✓ ; @s8 → `principles.md` L23 (senior-engineer test) + L55 (`[step] → verify: [check]`); `plugin/skills/principles/SKILL.md` L27/L59 identical; `diff` core vs plugin differs only on frontmatter/placeholder/skill-reference lines ✓ ; @s9 → every smoke case re-runs against `plugin/hooks/coding-reminder.sh` with `CLAUDE_PROJECT_DIR` set and asserts line-1 equality ✓.

### Checks run
- `bash scripts/smoke.sh` → 30/30 PASS, exit 0. Cases cover fallback (@s3), shell-injection payload in the prefs value (`output_style=concise; echo PWNED` → v0.8.1 banner, `PWNED` count 0), binary garbage in the prefs file (→ default banner, exit 0, stderr silent), non-coding prompt (empty output), and plugin parity on every case.
- `bash scripts/build.sh` → 0; `bash scripts/build.sh --check` → "generated trees in sync"; `python3 scripts/validate-packaging.py` → valid @ v0.8.1 (bump is MF7).
- Double build → `git status --porcelain` identical before/after (byte-stable).
- `bash -n` on hook and smoke; no `declare -A`, `[[`, `${x,,}`; `sed -n '…' | head -1` + `case` only — bash 3.2 safe.
- Hook only echoes whitelisted literals: `$STYLE` is reassigned from a fixed `case` before any `echo`; unrecognized → `""` → mode-only arm. Verified by hand: `autonomy_mode=bogus` → no banner (unchanged v0.8.1 behaviour); `autonomy_mode=autonomous` alone → `output: concise`; duplicate key → first wins.
- Scope: `terse` appears only as an accepted `case` value and in the "(including `terse`)" prose clause — no definition (MF8). Karpathy import is exactly the two lines in @s8; nothing else from that source.
- `verbosity` gone everywhere except historical `docs/specs/setup-evolution/*` (correct — those are records).
- CLAUDE.md always-loaded growth: 1 line rewritten, 0 net lines.

### Blockers
- none

### Major
- `core/.claude/rules/principles.md:187` (mirrored to `plugin/skills/principles/SKILL.md:149` and generated copies) — "Absent, empty, or **unrecognized** = `concise`" contradicts spec D3 ("unrecognized = the v0.8.1 mode-only banner") and the hook that implements it. On a host without hooks the model will print `output: concise` for `output_style=verbose`; on Claude the hook prints `mode: gated — say 'just go' for autonomous`. Same prefs file, two different banners across hosts, and the deviation is not justified in writing. One-word fix: "Absent or empty = `concise`; an unrecognized value is ignored (mode-only banner)." Not a blocker — no scenario fails — but it is a Design-notes deviation, so it should land before commit.

### Minor
- `scripts/smoke.sh:65,69` — the two `grep -c` leak assertions read `$OUT` after `hook_case` returns, and the last `run_hook` inside `hook_case` is the *plugin* hook. The core hook's output is never checked for leakage directly; it is covered only transitively (parity asserts line 1, and both banner blocks are textually identical today). Cheap tightening: capture `core_out=$OUT` in `hook_case` and grep that too, or grep both.

### Nits
- `core/.claude/hooks/coding-reminder.sh:46-50` — `output_style=terse\r` (CRLF) or a trailing space degrades silently to the mode-only banner. Same behaviour as the pre-existing `autonomy_mode` read, so consistent; noting only because a user who hand-edits the file on Windows gets no signal. Not worth a `tr -d '\r'` unless it bites.
- `principles.md` Output style: "Answer or action first" / "No preamble, filler, recap of visible output" restate two Conciseness bullets directly above. Duplication is contract-mandated (@s5 lists those items), so accepted; the subsection otherwise extends rather than repeats (normal grammar, ≤5 bullets, one next action, error shape, mandatory-prose list, session overrides).
- `core/CLAUDE.md:24` — the Autonomy bullet now carries the full banner template inline; line budget held, but the bullet is ~270 chars longer. Acceptable given @s7 requires the fallback text there.

### Process
- Micro-PR: 9 hand-authored files / 78 LOC — well inside 12 / 3000. Mirrors regenerated, not hand-edited.
- Design notes honoured: no pattern; one `sed`/`case` extension in the existing hook, one subsection in an existing principle, existing mirrors. No new abstraction, no new file beyond the harness the contract asks for.
- No debug residue, no commented-out code; hook comment block explains *why* (defensive whitelist), not *what*.
- `security-reviewer` is **mandatory** for MF1 per contract (hook reads a local file and injects into the prompt). Not run here — must run before commit.

### Verdict
- [ ] APPROVED   - [x] CHANGES REQUESTED — one Major (rule text vs D3/hook on unrecognized values). Re-approve on sight after the one-line fix + `build.sh`; no re-run of smoke needed for a prose change.
