# Epic → story → slice: design for the v0.11 workflow

ADHOC-16 step 2a, 2026-11-04. Implements decisions 1–17 of `proposal.md` section 5 (final, not reopened here). Step 2b builds from this doc after Juan's yes. Docs only; `core/` is untouched on this branch.

## 1. Grammar

Two generated files per epic. Plane is the source of truth; the repo copy is rendered, never hand-edited. First line of every rendered file:

```
<!-- generated from Plane <ID> at <ISO time>; source=plane; edit the card, then `/epic render <ID>` -->
```

Projects without Plane (`ticket_tracker != Plane`) write the same files from the approved draft with `source=local`; the draft is then the source of truth and the header says so.

| File | Rendered from | Holds | Size guidance (validator warns, never rejects) |
| --- | --- | --- | --- |
| `docs/epics/<ID>/epic.md` | Plane epic card (label `epic`) | Nexus-style body: Request, Description, Capability groups, User Stories, Acceptance Criteria, Test Scenarios, Technical tasks, Estimate | ≤120 lines; one AC and one TS per story; story TS ≤5 Given/When/Then lines |
| `docs/epics/<ID>/slices/<n>.md` | Slice sub-issue `n` (labels `slice` + `backend` or `frontend`) | Layer, capability group, stories covered, expected behaviour, tests | ≤60 lines; ≤5 stories per slice |

Capability groups are an `###` heading inside User Stories and map to a Plane Module when one matches, else to a `cap:<name>` label (decision 9). Story ids `S<n>` are global per epic; the one-case rule (one When per story, literal values) is checked by Juan at draft review, not by the validator (decision 3).

### `docs/epics/<ID>/epic.md` — filled example

```markdown
<!-- generated from Plane EXCH-55 at 2026-11-04T15:02:00Z; source=plane; edit the card, then `/epic render EXCH-55` -->
# EXCH-55 — Company SSO login

## Request
"Let issuer admins log in with their company Google Workspace instead of a password." (Plane, 2026-10-28)

## Description
Issuer admins of a company with a verified domain authenticate through OIDC; passwords stay for everyone else. Revocation at the IdP logs the user out within one sweep.

## Capability groups
| Group | Plane | Stories |
| --- | --- | --- |
| login | Module "Core Functionalities" | S1, S2 |
| revocation | label `cap:revocation` | S3 |

## User Stories
### login
- **S1** As an issuer admin, I want to sign in with my company Google account so that I do not keep a separate password.
- **S2** As an issuer admin with an unverified domain, I want a clear refusal so that I know to contact support.
### revocation
- **S3** As a company IT contact, I want a revoked Google account to lose access so that leavers are locked out.

## Acceptance Criteria
- **S1** A user of a verified domain lands on `/dashboard` after the IdP callback; no password form is shown.
- **S2** A user of an unverified domain sees `Your company is not enabled for SSO (code SSO-02)` and stays logged out.
- **S3** After the IdP reports the account revoked, the next request returns 302 to `/login?reason=revoked`.

## Test Scenarios
- **TS1** Given company `acme.com` is verified and `ana@acme.com` has no session, When the IdP callback returns `sub=ana-1`, Then the response is 302 to `/dashboard` and a session exists for `ana@acme.com`.
- **TS2** Given company `beta.io` is not verified, When `bo@beta.io` completes the callback, Then the response is 403 with body containing `SSO-02` and no session exists.
- **TS3** Given `ana@acme.com` has a session, When the revocation sweep finds `sub=ana-1` revoked, Then her next request is 302 to `/login?reason=revoked`.

## Technical tasks
| # | Layer | Name | Stories | Hours |
| --- | --- | --- | --- | --- |
| 1 | db | SSO company settings and identity link (models, serializers) | S1, S2, S3 | 4 |
| 2 | be | OIDC callback and revocation sweep (views, tasks) | S1, S2, S3 | 8 |
| 3 | fe | SSO button, refusal page, revoked banner | S1, S2, S3 | 5 |

## Estimate
17 h
```

### `docs/epics/<ID>/slices/<n>.md` — filled example

```markdown
<!-- generated from Plane EXCH-55 sub-issue EXCH-412 at 2026-11-04T16:40:00Z; source=plane; edit the card, then `/epic render EXCH-55` -->
# Slice 2 — be: OIDC callback and revocation sweep

- Layer: backend (views, tasks)
- Capability group: login, revocation
- Stories covered: S1, S2, S3
- Branch: `feature/EXCH-55-login-be` (stacked on `feature/EXCH-55-login-db`)

## Expected behaviour
`GET /auth/sso/callback` exchanges the code, resolves the company by email domain, refuses unverified domains with 403 `SSO-02`, and creates the session. A Celery beat task `sweep_revoked_sso` runs every 15 minutes, asks the IdP for each linked `sub`, and marks revoked identities so the auth middleware redirects them.

## Tests
- `test_S1_verified_domain_callback_creates_session` → TS1
- `test_S2_unverified_domain_callback_refused` → TS2
- `test_S3_revoked_identity_redirects_next_request` → TS3
```

The card body never lists files or MR links (decision 17); the `Branch` line is the only field the renderer adds, derived as `feature/<ID>-<group>-<layer>`.

## 2. Flow

| Stage | Today | New | Who gates |
| --- | --- | --- | --- |
| Epic intake | `/spec` → pmo converses ~800 lines under `docs/specs/<slug>/` | `/epic <ID or text>`: reads the Plane card (or the pasted ask), surveys the code with `code-query`, drafts the full epic body once, numbered stories and slices | Juan replies by number (approve / change n) |
| Cards | pmo asks "mirror to tracker?" | Out of scope for the template: the orchestrator's Haiku executor creates the epic card and, per approved slice brief, the slice sub-issue (decision 16). The template only produces the draft and reads cards back | Juan's yes on the draft |
| Repo copy | spec.md, contract.md, features.json | `/epic render <ID>` writes `epic.md` and `slices/<n>.md` from the cards, runs `validate-epics.py` (warnings only) | nobody; generated |
| Slice brief | pmo mini-feature + features.json state | `/slice <ID> <n>`: picks the next slice in layer order, confirms stories, seams and fixtures in one table, updates the sub-issue body if the brief changed | Juan's yes per slice |
| Tests first | Gate 2 only under TDD, approves "first failing test" | `tests-first`: writes tests through the public seam for every TS the slice covers, names `test_S<n>_<case>`, runs them, pastes the red output. Commits tests on the slice branch | Juan reads the test files and says yes (decision 4) |
| Implement | `/feature` → dev subagent, principles injected 2–3× | `implement`: same thread by default (decision 5); loads `backend-style` or `frontend-style` by slice layer; implements to green; approved test files are locked (section 6, Q2); pastes command and output | none |
| Review | `judge` two axes, up to 2 cycles | `code-review` (Pocock): Standards + Spec subagents against the slice file and its stories; one fix round, then MR | one fix round |
| Council | none | `council`, opt-in: single round, three providers, security or architecture slices only, priced in the launch draft | Juan asks for it |
| MR | `/pr` checks 12 files / 3000 LOC | `/pr`: base = previous layer branch while it is open, else default branch; 200–400 non-test LOC target; 12 files / 3000 LOC hard cap fails the slice instead of exceeding it | Juan reviews the MR |

Stacking per capability group: `feature/<ID>-<group>-db` → `-be` → `-fe`. The FE slice may start on the BE branch when Juan wants both in flight. One slice in progress per group; groups may run in parallel threads.

## 3. Skill set

Decision 10 applied. Keep = unchanged; Adapt = edited in place; Drop = deleted; New = added. Model-invoked skills move to `core/.claude/skills/<name>/SKILL.md`; `rules/` keeps only `principles.md` (the one always-loaded file). User-invoked skills carry `disable-model-invocation: true`, so they port from mattpocock with their frontmatter intact and build.sh copies them instead of transforming them.

### `core/`

| File | Verdict | Reason |
| --- | --- | --- |
| `CLAUDE.md` | Adapt | Agent table shrinks to `security-reviewer`, `ui-designer`; workflow section becomes `/epic` → `/slice` → tests-first → implement → code-review; ≤120 lines |
| `.claude/HELP.md` | Adapt | Decision tree rewritten for the new entry points; ≤80 lines |
| `.claude/settings.json` | Adapt | Remove the `UserPromptSubmit` hook; add `Read(docs/epics/**)`, `Write(docs/epics/**)` |
| `.claude/mcp.json.example` | Keep | Plane entry already present |
| `.claude/agents/pmo.md` | Drop | Replaced by `epic` + `slice` |
| `.claude/agents/orchestrator.md` | Drop | The thread runs the flow; no coordinator role |
| `.claude/agents/judge.md` | Drop | Replaced by `code-review` (decision 6) |
| `.claude/agents/backend-dev.md` | Drop | `implement` + `backend-style` cover it; no dev subagent (Q1) |
| `.claude/agents/frontend-dev.md` | Drop | same |
| `.claude/agents/mobile-dev.md`, `game-dev.md`, `desktop-dev.md`, `core-dev.md` | Drop | same; stack style lives in the style skills |
| `.claude/agents/security-reviewer.md` | Adapt | Output path `docs/epics/<ID>/slices/<n>.security.md`; drop `judge` mentions |
| `.claude/agents/ui-designer.md` | Keep | Unrelated to SDD; used by `/design` |
| `.claude/agents/mutation-tester.md` | Adapt | Retarget to the slice's test files; stays opt-in |
| `.claude/commands/spec.md` | Drop | Replaced by `epic` |
| `.claude/commands/feature.md` | Drop | Replaced by `slice` + `tests-first` + `implement` |
| `.claude/commands/fix.md` | Adapt | `judge` → `code-review`; drop `features.json` bookkeeping |
| `.claude/commands/verify.md` | Adapt | Spec lookup → slice file; drop pattern-ledger check |
| `.claude/commands/audit.md` | Adapt | Phase 2 spawns the `code-review` Standards axis instead of `judge` |
| `.claude/commands/pr.md` | Adapt | Stacked base branch; 200–400 LOC target line; link the slice |
| `.claude/commands/commit.md`, `design.md`, `integrate.md` | Keep | No SDD grammar inside |
| `.claude/hooks/coding-reminder.sh` | Drop | Decision 10 |
| `.claude/hooks/agent-enforcement.sh` | Adapt | Keep the branch hard block; drop the agent advisory; add the approved-tests lock (Q2) |
| `.claude/hooks/auto-format.sh` | Keep | — |
| `.claude/rules/principles.md` | Adapt | ≤80 lines: think, simplicity + ladder, surgical, read-before-write, code health, commits, PR limits, DoD, conciseness, branch discipline, autonomy mode; drop FR/SC, deviation table, double gate, report-format schema |
| `.claude/rules/backend-style.md` | Adapt | Move to `skills/backend-style/SKILL.md`, loaded by `implement` for `db`/`be` slices |
| `.claude/rules/frontend-style.md` | Adapt | Move to `skills/frontend-style/SKILL.md`, loaded for `fe` slices |
| `.claude/rules/code-query.md` | Adapt | Move to `skills/code-query/`; "mini-features" row → "slices" |
| `.claude/rules/patterns.md` + `.claude/patterns/*.md` (7) | Adapt | Move to `skills/patterns/` with references; drop the per-mini-feature ledger wording; on demand only |
| `docs/design-system/MASTER.md`, `tokens.json` | Keep | — |
| `tools/mutate.py` | Keep | — |
| `.claude/skills/epic/SKILL.md` + `validate-epics.py` | New | From `to-spec` |
| `.claude/skills/slice/SKILL.md` | New | From `to-tickets` |
| `.claude/skills/tests-first/SKILL.md` + `tests.md`, `mocking.md` | New | From `tdd` |
| `.claude/skills/implement/SKILL.md` | New | From `implement` |
| `.claude/skills/code-review/SKILL.md` | New | From `code-review` |
| `.claude/skills/council/SKILL.md` | New | From tstack `council`, opt-in |
| `.claude/skills/update-config/SKILL.md` + `migrate.py` | New | Section 4 |

### `scripts/`, `plugin/` hand-authored, `hosts/`

| File | Verdict | Reason |
| --- | --- | --- |
| `scripts/validate-specs.py` | Drop | Ledger grammar gone; `validate-epics.py` ships inside the `epic` skill and CI runs it on this repo's `docs/epics/` |
| `scripts/migrate-specs.py` | Drop | v2 ledger migration superseded by `update-config/migrate.py` |
| `scripts/build.sh` | Adapt | Section 5 |
| `scripts/check-override-headings.py`, `validate-packaging.py` | Adapt | Packaging check learns `core/.claude/skills/`; heading check keeps principles only |
| `scripts/smoke.sh` + `scripts/smoke/*.sh` (33) | Adapt | Drop v090/v091 grammar cases and their fixtures; add `v011-*` cases (one per 2b chunk) |
| `scripts/evals/cases.jsonl`, `run.py` | Adapt | Three cases name `/spec`/`/feature`; rewrite to `/epic`/`implement` |
| `plugin/agents/*` (11) | Adapt | Same drop list; keep `security-reviewer`, `ui-designer` |
| `plugin/commands/*` (11) | Adapt | Drop `spec`, `feature`; adapt `fix`, `verify`, `audit`, `pr`; `setup-template` points to `update-config` for existing renders |
| `plugin/skills/sdd-workflow` | Drop | Replaced by `docs/epic-story-slice.md` (short) and the skills themselves |
| `plugin/skills/{principles,backend-style,frontend-style,code-query,patterns}` | Adapt | Become build-generated copies of `core/.claude/skills/*` once the files are placeholder-free (section 5) |
| `plugin/hooks/hooks.json`, `coding-reminder.sh` | Adapt / Drop | Remove the prompt hook |
| `hosts/codex/skills/{sdd-workflow,feature}` | Drop | Overrides of dropped files; `code-review` on Codex runs both axes sequentially in one thread (note already exists) |
| `hosts/cursor/AGENTS.md`, `principles.mdc` | Adapt | Mirror the ≤80-line principles and new entry points |
| `docs/sdd-workflow.md`, `README.md`, `docs/upgrade-guide.md`, `docs/what-each-file-does.md` | Adapt | v0.11 section; workflow diagram; file map |
| `docs/specs/*` (8 epics, ~150 files) | Adapt | Migrated by `update-config/migrate.py` as the dogfood run (Q4) |

Totals for `core/` + `scripts/`, counted per file (pattern references individually, `scripts/smoke/*` as one): Keep 9 · Adapt 26 · Drop 14 · New 7 skills (11 files). Agents go from 12 to 3 files (`security-reviewer`, `ui-designer`, `mutation-tester`).

### Adapted skills: diff intent and size

| Skill | From | Diff intent (≤5 bullets) | Est. tokens |
| --- | --- | --- | --- |
| `epic` | `to-spec` (≈760) | Output is the Nexus card body (section 1), not Pocock's spec template · stories are one-case with literal AC/TS, grouped by capability · reads the Plane card by readable id when `ticket_tracker=Plane`, else the pasted ask · adds `render <ID>` subcommand that writes the repo copy and runs the validator · drops the `setup-matt-pocock-skills` tracker dependency and the "LONG list" instruction | ≈900 + validator ≈120 lines |
| `slice` | `to-tickets` (≈1,450) | Rewrite vertical tracer bullets to layer slices in `db → be → fe` order per capability group · one brief = stories, seams, fixtures, expected behaviour, tests table · no file lists or MR links in the card body · quiz the user only on granularity and story coverage · no publishing step; the executor creates the sub-issue | ≈1,100 |
| `tests-first` | `tdd` (≈910 + refs 920) | Keep seams, mocking and anti-pattern text and the two reference files verbatim · replace the "no horizontal slicing" ban with "all tests for this slice's stories, then red run" · add the gate: commit tests, paste red output, stop for Juan · test naming `test_S<n>_<case>`, expected values are the TS literals · after yes, record approved test paths in the slice file | ≈1,000 + refs 920 |
| `implement` | `implement` (≈155) | Input is a slice file plus approved tests · load `backend-style` or `frontend-style` by layer · never edit approved tests; stop and ask if one must change · run format, lint, single test file, then full suite; paste outputs · end with `code-review`, then commit; push stays gated | ≈400 |
| `code-review` | `code-review` (≈1,680) | Spec source = the slice file and its stories (step 2 fixed, no tracker lookup) · Standards sources = `principles` + the layer style skill · Spec axis also checks `git diff` of approved test files is empty · keep the Fowler smell baseline and the no-rerank rule · one fix round, then stop | ≈1,500 |
| `council` | tstack `council` (≈540) | Single round, no loop · providers fixed to Opus 5.5, Astra or Sol, Grok 4.7 via T3 `delegate_task`; report, never substitute · only when the launch draft names it · results go in the final reply, PR edit only on confirmation | ≈500 |

## 4. `update-config` skill outline (decision 13)

Step 2b implements; this is the contract.

| Step | What happens | Output |
| --- | --- | --- |
| 1 Detect | Read `agent-config.lock.json` (hosts, per-file SHA) and `answers.env`; refuse without both and point to `/setup-template` | version line |
| 2 Plan | Run `setup.sh --target . --answers answers.env` in plan mode; collect `STALE-MANAGED`, `CUSTOMIZED-MANAGED`, `LEGACY`, `OBSOLETE`, `CUSTOMIZED-OBSOLETE` | config plan table |
| 3 Spec scan | For each `docs/specs/<slug>/`: read `features.json` status; classify `done` (all mini-features done) or `open` | migration plan table |
| 4 Confirm | One numbered list: config paths to overwrite, obsolete paths to prune, specs to archive, specs to migrate. Juan answers by number; unanswered = skip. Never a silent overwrite; `CUSTOMIZED-*` is never touched | approval |
| 5 Apply | `setup.sh --merge --overwrite-files <approved> [--prune]`, then `migrate.py --apply <approved slugs>` | files, lock updated |
| 6 Commit | `chore(config): update agent-config-template to v0.11.0` on a `chore/` branch; push gated | commit |

`migrate.py` mapping, one run per slug, idempotent (second run is a no-op):

| Old (`docs/specs/<slug>/`) | New | Notes |
| --- | --- | --- |
| whole directory, status `done` | `docs/epics/archive/<slug>/` | moved verbatim; header line added to `spec.md` |
| `spec.md` Problem + Goal | `docs/epics/<slug>/epic.md` Request + Description | header `source=migrated` |
| `contract.md` mini-feature block | `## Capability groups` row + `### <mini-feature>` story heading | group name = mini-feature name |
| `@sN` scenario | `TSN` line, literal text kept | story line is `- **SN** TODO: write the story for TSN` (actors are not derivable) |
| `features.json` item | `slices/<id>.md` with layer `mixed`, stories = its scenarios, status | FR/SC tags dropped |
| `progress/*` | `docs/epics/archive/<slug>/progress/` | never rendered |
| `docs/CONTEXT.md` | untouched | glossary is still useful |

Epic ids for migrated specs are the slug; a later `/epic` run can rename once a Plane card exists.

## 5. Host mirroring and size

`build.sh` changes:

| Output | Today | New |
| --- | --- | --- |
| `plugin/template/` | copy of `core/` | unchanged rule |
| `plugin/skills/` | hand-authored | generated from `core/.claude/skills/*` for every skill whose file has no `{{placeholder}}`; the two style skills keep their hand-authored generic copies until their placeholders are replaced by "read CLAUDE.md Commands" |
| `codex/skills/` | from `plugin/skills` + `plugin/commands` + overrides | same; `CODEX_NOTE_COMMANDS` becomes ` epic slice implement code-review fix audit design ` |
| `cursor/` | copies `rules/`, `agents/`, converts `commands/` | also copies `.claude/skills/`; `.cursor/rules/` holds `principles.mdc` only (style rules are skills now) |
| `--check` | diffs all trees | unchanged |

Estimated line delta (hand-authored, before generated mirrors):

| Area | Lines removed | Lines added | Net |
| --- | --- | --- | --- |
| `core/` agents, commands, hook, rules trimmed | ≈1,150 | ≈0 | −1,150 |
| `core/.claude/skills/` new + moved | ≈0 | ≈520 new (+ ≈280 moved) | +520 |
| `plugin/` hand-authored, `hosts/` | ≈900 | ≈120 | −780 |
| `scripts/` (validators, smoke, evals) | ≈450 | ≈300 | −150 |
| docs | ≈250 | ≈200 | −50 |
| Generated mirrors (×3 trees) | | | ≈ −4,800 |

Always-loaded text per coding turn in a rendered Claude project (≈11 tokens per line):

| Item | Before | After |
| --- | --- | --- |
| `CLAUDE.md` | 204 lines ≈ 2.2k | ≈110 lines ≈ 1.2k |
| `.claude/rules/*` auto-loaded | 538 lines ≈ 5.9k | 80 lines ≈ 0.9k |
| `coding-reminder.sh` injection | ≈25 lines ≈ 0.3k per prompt | 0 |
| Plugin roster (agent + skill descriptions) | 11 agents + 8 skills ≈ 1.1k | 3 agents + 13 skills ≈ 0.9k |
| **Total** | **≈9.5k** | **≈3.0k** |

Per-slice on-demand load: slice file ≤60 lines + epic ≤120 + `implement` 0.4k + one style skill ≈0.7k + `tests-first` ≈1.9k ≈ 5k, against ≈11k for spec + contract + ledger today.

## 6. Open questions for Juan

Each one is a gap the 17 decisions leave open. Answer by number, for example `1a, 2a, 3a, 4a, 5a, 6a`; the recommended option is always (a).

**Q1. Should the template ship a `dev` subagent at all?**
Why it is open: decision 10 says "at most one generic `dev` agent" but does not say whether to keep one.
- (a) **No dev agent** (recommended). `implement` runs in the slice thread itself. The thread already has the slice file, the tests and the rules, so a subagent would only hide the diff from the thread and cost a second context window.
- (b) One `dev` agent with a `layer` argument, for plugin users who want to delegate implementation to a subagent. Costs one more agent file to maintain across hosts.

**Q2. How are approved tests protected while the code is written?**
Why it is open: decision 4 says Juan reads the test files and says yes; decision 5 says tests and code are written in the same thread by default. Nothing says what stops that thread from editing a test to go green.
- (a) **Hook lock** (recommended). After Juan's yes, `tests-first` lists the approved test paths in the slice file. `agent-enforcement.sh` blocks Edit and Write on those paths (override: `AGENT_CONFIG_UNLOCK_TESTS=1`), and the `code-review` Spec axis fails when their diff is not empty. Costs ≈15 lines in an existing hook.
- (b) Instruction only: `implement` says "never edit approved tests; stop and ask". Nothing enforces it on hosts with hooks, and nothing at all on Codex.

**Q3. Does `/epic` work without Plane?**
Why it is open: decision 2 makes Plane the source of truth, but the template is public and most users have no Plane.
- (a) **Yes, with `source=local`** (recommended). When `ticket_tracker` is not Plane, the approved draft is written straight to `docs/epics/<ID>/` and the header says `source=local`; those files are then the source of truth. One `if` in the skill.
- (b) Plane required. `/epic` refuses on other trackers and the README says so. Simpler skill, smaller audience.

**Q4. What happens to this repo's eight old `docs/specs/` folders (≈150 files, 6.4k lines)?**
Why it is open: decision 13 defines the migration script but not whether the template repo runs it on itself.
- (a) **Migrate them in chunk 6** (recommended). Done specs move to `docs/epics/archive/<slug>/` verbatim; this is the dogfood test of `migrate.py` (file count preserved, second run is a no-op).
- (b) Delete them and rely on git history. Smaller repo, but `migrate.py` then has no real input to be tested on.

**Q5. Do `workflow_mode`, `use_gherkin` and `enforce_layer_split` survive in `template.config.yaml`?**
Why it is open: under the new flow tests are always first, slices are always layered and Gherkin is gone, so the three placeholders change nothing. Existing `answers.env` files still contain them.
- (a) **Remove them** (recommended). `setup.sh` warns once and ignores the keys in an old `answers.env`; `update-config` prints the warning in its plan.
- (b) Keep them as no-ops for one release and remove in the next. Avoids the warning but leaves three dead knobs in the setup round.

**Q6. Which version number?**
Why it is open: this release removes commands (`/spec`, `/feature`) and agents, which is a breaking change for anyone scripting them.
- (a) **`0.11.0`** (recommended) with a "breaking" section at the top of the upgrade guide, matching every release so far.
- (b) `1.0.0`, signalling the workflow is settled. Honest only if no further grammar changes are expected after the pilot.

## 7. Step 2b work plan

Each chunk is one MR, ≤12 core files, with its smoke test in `scripts/smoke/v011-<n>-*.sh`.

| # | Chunk | Core files | Test |
| --- | --- | --- | --- |
| 1 | Principles ≤80 lines, `CLAUDE.md`, `HELP.md`, `settings.json`, drop `coding-reminder.sh`, adapt `agent-enforcement.sh` | 6 | Render `examples/python-django`; rendered tree has no `pmo`, `judge`, `coding-reminder` strings; `bash -n` on hooks; principles ≤80 lines |
| 2 | Drop 9 agents, `spec.md`, `feature.md`; adapt `security-reviewer`, `mutation-tester` | 13 deletions + 2 edits (deletions do not count toward the cap) | `validate-packaging.py` and `build.sh --check` pass; grep finds zero references to dropped names in `core/` |
| 3 | `epic` skill + `validate-epics.py` + `slice` skill + `docs/epics/EXAMPLE/` fixture | 5 | Validator warns on a 130-line fixture epic and a 7-story slice, exits 0; passes clean on the example; a slice naming an unknown story exits 1 |
| 4 | `tests-first`, `implement`, `code-review`, `council` skills; adapt `fix`, `verify`, `audit`, `pr` | 10 | Grep cases: fixed point pinned, two axes present, no `@s` grammar, `pr.md` mentions the stacked base; `code-review` has no tracker-setup dependency |
| 5 | Move style, `code-query`, `patterns` to `skills/`; `build.sh` copies skills to cursor and plugin; `check-override-headings.py` | 12 | `build.sh --check` green; cursor render has one `.cursor/rules/*.mdc` and the skills dir; codex tree has `epic`, `slice`, `implement`, `code-review` |
| 6 | `update-config` skill + `migrate.py`; migrate this repo's `docs/specs/` | 2 + moves | Migrate a tmp copy of all 8 specs: file count preserved, second run no diff, `validate-epics.py` clean on the result |
| 7 | Plugin hand-authored side: agents, commands, `hooks.json`, `plugin.json`, `plugin/README.md`; `hosts/` overrides | ≤12 (plugin, not core) | `validate-packaging.py` green; `plugin/skills` equals generated copies for placeholder-free skills |
| 8 | Smoke prune, evals rewrite, `README`, `upgrade-guide` v0.11 section, `what-each-file-does`, `sdd-workflow.md` → `epic-story-slice.md`; version bump | ≤12 | CI green end to end; `scripts/evals/run.py validate` green |

Order is fixed: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8; chunks 3 and 4 may run in parallel threads after 2.
