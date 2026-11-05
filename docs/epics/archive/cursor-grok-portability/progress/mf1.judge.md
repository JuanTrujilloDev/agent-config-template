# Judge: codex-drift-elimination  (@s1..@s4)

**Stats:** 7 hand-authored files (SYNC_NOTE.md, build.sh, 5 new under `hosts/codex/`), ~346 hand-written LOC. Within limits (≤8 files, ≤600 LOC per D2; `features.json` status flip is the orchestrator's). Generated `codex/skills/` excluded per D2 — and it is byte-identical to HEAD, so it doesn't even appear in the diff.

**Scenario → verification** (re-run by judge, not taken from the implementer's report):

- @s1 → `bash scripts/build.sh` run twice; `git status --porcelain` identical before/after; `git diff HEAD -- codex/skills` empty (deterministic, byte-identical regeneration) ✓
- @s2 → seeded drift in all three directions — hand edit to `codex/skills/verify/SKILL.md`, edit to `plugin/skills/principles/SKILL.md` without rebuild, edit to `hosts/codex/skills/port-config/SKILL.md` without rebuild — each time `--check` exits 1 and prints `DRIFT: codex/skills != generated (plugin/ + hosts/codex/)` ✓
- @s3 → proven constructively: regeneration uses only `plugin/` + `hosts/codex/` as inputs and reproduces HEAD's `codex/skills/` byte-for-byte, so no codex content lacks a source. Spot-checked: `codex plugin`/`--platform codex` strings exist only in `codex/skills/setup-companions` + its `hosts/codex/` source; hat-switching text traces to `hosts/codex/note-role-adaptation.md` and the sdd-workflow/feature overrides ✓
- @s4 → `.github/workflows/ci.yml` `plugin-mirror` job runs `bash scripts/build.sh --check` unchanged; verified locally `test $? -eq 1` on seeded drift ✓

Also: `python3 scripts/validate-packaging.py` passes; SYNC_NOTE rewritten to "generated — edit plugin/ or hosts/codex/" per the design note.

**Design/leverage fidelity:** generation function sits beside the existing copy block in `build.sh`; `--check` extends the existing `DRIFT:`/`diff -r` idiom (same message shape, same drift accumulator, same "Run scripts/build.sh to regenerate" tail); overrides are plain files; no templating engine; bash-3.2-safe constructs throughout. Matches contract design notes and D1.

**Scope:** `codex/assets/`, `codex/.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`, `core/` all untouched ✓. No debug residue, no drive-by refactors. No auth/permissions/external-input surface touched — security-reviewer not required (build tooling over repo-local files).

**Implementer's 3 recorded decisions:**
1. *Whole-file overrides for all 4 delta files (incl. one-line-delta port-config)* — sound. One override mechanism instead of two (a sed patch just for port-config would be a second idiom for a one-line win). Documented in SYNC_NOTE, which names all four overridden files and their deltas. Verified port-config's delta really is one line (description reword — the plugin text "Port this Claude Code configuration ... (Codex, ...)" would be nonsense on Codex).
2. *Append-note only for spec/fix/audit/design* — as recorded, this does not match the code: `CODEX_NOTE_COMMANDS=" spec feature fix audit design "` includes `feature`, whose auto-derived output is then superseded by the whole-file override (which itself contains the note). Net output identical; the code's uniform rule is actually the better shape (matches SYNC_NOTE and contract @s1's "subagent-spawning workflow skills"). Finding is against the decision record's wording, not the code — Nit.
3. *Hardcoded setup-template exclusion* — sound and documented in both SYNC_NOTE ("Not ported: ... setup-template") and the build.sh comment block. A config list for one excluded name would be YAGNI.

### Blockers

None.

### Major

None.

### Minor

- `scripts/build.sh:57,63` — `awk 'seen==2{print} /^---$/{seen++}'` stops printing after a third `---`: a future literal `---` horizontal rule in a command body silently truncates the generated codex skill from that line on, and `--check` cannot catch it (generation is the source of truth on both sides of the diff). No current input triggers it (verified: no command body contains `---`). One-character hardening: `seen>=2{print}`. Fix now or accept knowingly.
- Whole-file overrides create a silent-staleness shadow: future edits to `plugin/skills/port-config/SKILL.md` or the `setup-companions`/`feature` command bodies will not propagate to codex and will not trip `--check`. Contract-blessed trade-off (design note: "overrides are plain files"), and SYNC_NOTE names the shadowed files — flagged so the risk is on record, not as a demand for a mechanism.

### Nits

- Decision record #2 wording vs code (see above) — align the record, not the code.
- `scripts/build.sh:55` — an embedded `"` in a future command `description:` would emit invalid YAML in the generated frontmatter (none exist today; MF7's @s19 validator will catch it when it lands).
- `scripts/build.sh:39-71` — `build_codex_skills` uses non-`local` variables (`out`, `name`, `desc`); harmless at the single call site, but `local` is bash-3.2-safe.

### Verdict

- [x] APPROVED (with nits)   - [ ] CHANGES REQUESTED
