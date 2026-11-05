## Judge: patterns-rule  (@s10..@s17)

**Stats:** 13 hand-authored files (rule, six refs, plugin SKILL, `build.sh`, `smoke.sh`, `core/CLAUDE.md`, `README.md`, `plugin/README.md`), ~645 LOC (546 new markdown + 99 script/doc lines); generated mirrors (`cursor/`, `codex/`, `plugin/{template,cursor,codex}`) regenerated, not hand-edited. Branch `feature/v0.8.2-adaptive-skills`, `main` untouched.
**Scenario → test:** @s10 → smoke `@s10 …` (≤120 lines, six wording greps, awk order check inspect<force<why<refusal<reject<ledger, six table links, lean-surface ≤1 refs) ✓ ; @s11 → smoke `@s11 …` (exactly six, ≤150, "Simplest default first", force→pattern header, no `{{`) ✓ ; @s12 → smoke `@s12 …` (frontmatter, quoted description, `the \`code-query\` skill`, refusal wording, `${CLAUDE_PLUGIN_ROOT}/template/.claude/patterns/`, `references/`) ✓ ; @s13 → smoke `@s13 …` (cursor/codex byte-equal to core, codex `name: patterns`, `--check` clean, two seeded hand-edits caught) ✓ ; @s14 → smoke `@s14 …` (grok/cursor rule + six refs; codex `.agents/skills/patterns/{SKILL.md,references/*6}`) ✓ ; @s15 → smoke `@s15 …` (validate passes; seeded unquoted `description:` fails, restored) ✓ ; @s16 → smoke `@s16 …` (`**7 skills**`, `` `patterns` `` in both READMEs) ✓ ; @s17 → human; judge dry-run below ✓.

### Checks run
- `bash scripts/smoke.sh` → 142 PASS, 0 FAIL, exit 0 (includes MF1's 30 + MF8's cases).
- `bash scripts/build.sh` twice → `git status --short` hash identical both runs; `build.sh --check` → "generated trees in sync", exit 0.
- `python3 scripts/validate-packaging.py` → valid @ v0.8.1.
- Rule 79/120 lines; refs 58–71/150 lines; SKILL.md 85 lines.
- Wording vs upstream (`00suryavanshi00/code-design-patterns` SKILL.md + refs 03/04/05/06/10 fetched): zero shared 7-grams anywhere; at 6-grams only `concurrency.md` shares three overlapping fragments of "write the event to an outbox table in the same [transaction]" — the canonical one-sentence definition of the pattern, not lifted prose. Upstream's signature phrases ("axis of change", "name the force" as a heading, rubric, tiers) are absent; ours ("earns its keep", "Simplest default first", "no pattern — single call site", "rejected alternative") are absent upstream. Attribution present in rule, skill, and `README.md`; spec adopt-table row (Adapt, our wording, our rungs) honoured; D0 internal-first honoured (no companion, no install).
- Harness fix `{ grep -c '{{' "$f"; true; }` is correct: `grep -c` prints `0` and exits 1 on no match, so the old `grep -c || echo 0` emitted `0\n0`; the new form emits exactly one number. Missing-file branch echoes `missing` → FAIL. `seed_check` restores via backup and asserts `--check` rc=1; confirmed both seeded drifts caught.

### @s17 dry-run (judge, with the rule loaded)
- Brief "add a single CSV export endpoint for orders": step 1 inspect (code-query) finds existing order queries; step 2 the force sentence can only be written with "might later need PDF/XLSX" → no force present; step 3 → Design notes `no pattern — single call site`. No pattern name appears; the default-reject table would have rejected Strategy (one implementation) and a Factory (one product) had they been proposed. Passes.
- Real two-strategy force "CSV and PDF export both ship today; PDF carries page-layout state, CSV carries delimiter/escaping config": step 3 tries a dict of functions first; the Strategy row's own condition ("each variant carries its own state") is met → ledger `Strategy / two exporters ship today, each with its own writer state / dict of functions (rejected: PDF layout state leaked into closures)`. Names one pattern with a rejected alternative. Passes. Note: no reference file owns "variation among N implementations"; the rule's reject table covers it, which is the right place.

### Blockers
- None.

### Major
- Micro-PR budget. Counting as MF1's judge counted (smoke.sh included), this is 13 hand-authored files vs `max_files: 12` — over by one. The overage decomposes into (a) `smoke.sh`, which `features.json` never listed although the contract requires every scenario to map to a test, and (b) `core/CLAUDE.md`, the one-line pointer the lean-surface check explicitly permits (≤1 reference). No scope creep, no unrequested code, LOC 645/3000. Ruling: accept; not a discipline breach in substance, but `docs/specs/adaptive-skills/features.json` MF2 `files` is stale on two counts — it omits `scripts/smoke.sh` and `core/CLAUDE.md`, and names the refs `backend-api-persistence.md`, `frontend-ui-state.md`, `game-unity.md`, `concurrency-distributed.md` while the shipped files are `backend.md`, `frontend.md`, `game.md`, `concurrency.md` (the contract's `<domain>.md` reading; the short names are the better choice and match the rule's table). Fix the list when flipping status; bump `max_files` to 13 with the one-line reason, or accept the recorded overage in the PR body.

### Minor
- `core/.claude/patterns/concurrency.md` Backpressure row: "Simplest alternative: Bounded buffer that blocks the producer" is itself backpressure — the row's alternative restates the pattern. Suggest "Slow the producer (batch/poll interval) or measure first; a bounded queue is already the pattern."
- `plugin/skills/patterns/SKILL.md` "in a project rendered with `/setup-template`" — Codex/Cursor users render via `setup.sh --host …`, not the plugin command. Say "rendered by `setup.sh` / `/setup-template`".

### Nits
- Rule "## Who uses this" promises pmo/judge/`/verify` behaviour that lands in MF3 (@s18–@s24). Acceptable as a forward pointer inside one release train; if MF3 slips, this section is a promise the agents do not yet keep.
- Rule adds a sixth default-reject row (State with ≤3 states) beyond the contract's five. In-spirit, fits the budget, no objection — recording that it is extra.
- `plugin/skills/patterns/SKILL.md` duplicates ~70 lines of the rule by hand (code-query precedent, D5). No drift check exists between the two; same exposure as code-query today, so not new debt.
- `desktop.md` anti-pattern "Global application state singleton" and `game.md` "Singleton managers everywhere" overlap the rule's Singleton row — mild repetition across three files; each is domain-phrased, so rule-of-three not triggered.

### Content review (per-reference)
- backend: Repository/UoW/idempotency/optimistic-lock/expand-contract/retry/cache-aside — every entry has earns-its-keep + smell; simplest alternatives are real (ORM direct, one transaction block, upsert, index first). Stack-agnostic.
- frontend: container/presentational, hooks, state machine, derived state, query cache, render props — "two booleans before a state machine; a state machine before the third boolean" is the right rung. Framework-agnostic wording (hook/composable, memo).
- mobile: coordinator, view model, offline-first + sync queue with idempotency keys, conflict policy per record type, platform channel, lifecycle composables — offline-first present as required; server-authoritative default before device merge.
- game: composition, ScriptableObject data, pooling after profiling, enum+switch before state machine, event bus vs direct ref, update-loop budgeting — Unity-appropriate as contracted; anti-patterns (mutable SO as runtime state, allocation in Update, physics outside FixedUpdate) are the ones that bite.
- desktop: MVVM/MVC, Command for undo, document model, background work, shared actions — "never a blocking call on the UI thread" correctly exempted from the simplest-default rung.
- concurrency: worker pool, bulkhead, breaker, backpressure, actor vs lock, idempotent consumer, outbox — backpressure/outbox present as required; "timeout + bounded retry before a circuit breaker" is the correct rung.
- No cargo-cult catalogue in the rule: the rule is protocol + reject table + ledger + routing; every named pattern in it appears only as something to reject or as a routing keyword.
- principles.md YAGNI: no contradiction found. The rule's step 1 (reuse the project's existing pattern) is the leverage ladder's rung 2; "refusal is the expected answer for most mini-features" is YAGNI stated positively. Adversarial content lens therefore not escalated.

### Verdict
- [x] APPROVED   - [ ] CHANGES REQUESTED

Approved with the `features.json` reconciliation (files list + count) as a must-do at status flip, and the two Minor wording fixes recommended before commit (prose-only; no smoke re-run needed, `build.sh` required after editing `concurrency.md`).
