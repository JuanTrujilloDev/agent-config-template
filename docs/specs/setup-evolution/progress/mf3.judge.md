# Judge: zero-question-setup  (@s13..@s18)

**Stats:** 2 files, +51/−21 (`plugin/commands/setup-template.md` 154 lines total; `features.json` status flip). Limit 4 files / 500 LOC — well inside. Branch `feature/setup-evolution`, main untouched. `bash scripts/build.sh --check` → "generated trees in sync"; `python3 scripts/validate-packaging.py` → green @ v0.8.0. The command file has **no mirrors** (`find . -name 'setup-template*'` → only `plugin/commands/setup-template.md`; it is not under `core/`, so no cursor/codex transform touches it) — confirmed.

**Scenario → lines (verification is "wording states the behaviour", per the file being agent instructions):**

| Scenario | Where it is stated | Status |
|---|---|---|
| @s13 full inferred profile, cited source, no fact questions | L15–19 (every `when:`-satisfied placeholder, tiers), L23–31 (table with Value/Confidence/Source), L16 "Never asked", L35 + L96 "facts never in the round" | ✓ explicit |
| @s14 ONE numbered round, recommended default each, single reply resolves, second round only on `when:` unlock | L35 ("all … numbered, each with a recommended answer"), L43 (reply grammar, "Unanswered numbers take the recommendation"), L45 (second round condition + "lists only those") | ✓ explicit |
| @s15 round includes workflow_mode, autonomy_mode, hosts, companion question verbatim; no facts | L37–40 (items 1–4; companion wording `[Yes / Not now / Never]` byte-matches contract), L35 | ✓ explicit (see Major 1 for a re-run ambiguity) |
| @s16 policy → answers.env; autonomy/companions → answers.local.env; Yes → /setup-companions after render; Never suppresses mention | L47–49 (both scopes, "never write these two keys to answers.env"), L78–81 (step 8 routing) , L98 hard rule | ✓ explicit (see Major 2 for the "both installed" hole) |
| @s17 non-destructive machinery unchanged; tiers + just-go/--auto still work | L51–63 unchanged RENDER block (plan → exit 1 → `--merge`/`--overwrite`/`--abort`), L100 hard rule unchanged, L116 just-go variant (now also pins `--merge`) | ✓ explicit |
| @s18 no invented values (UNKNOWN + one targeted q), explicit approval before setup.sh, `when:` honored | L95 (UNKNOWN + one targeted question inside the round), L97 + L43 (approval = round reply, "do not run setup.sh before it arrives"), L102–112 (`when:` section, "doesn't exist" rule) | ✓ explicit |

Nothing implied-only at scenario level. The two ambiguities below are about *edge paths* (re-run, both-installed) the scenarios don't name but the file itself opens.

## MF1 / v0.8.0 residue check (nothing lost)

- Config scopes table L83–91: byte-identical to HEAD, relocated after step 8 (previously interleaved between step 5 and the old step 6 — relocation is an improvement).
- Gitignore block L65–74: identical content (`settings.local.json`, `mcp.json`, `answers.local.env`; "`answers.env` is committed — never gitignore it"). Only the step number changed (5 → 6) — see Minor 3.
- Host question (v0.8.0): signals L21 identical (`claude` always, `.cursor/` → cursor, `.codex/`|`.agents/` → codex); multi-select + grok note L38; `TARGET_HOSTS=` recording + "renderer defaults to claude / `--host` overrides" L48. Folded into the round exactly as @s15 asked. No loss.
- RENDER block L51–63 and the `--merge`-default sentence: unchanged. `--auto`/"setup, just go" path L116: present, strengthened.
- The mf2 Major 2 carry-over (standalone autonomy question moved into mf3): done — autonomy is item 3 of the round, not a separate step.

## Rulings on the implementer's 5 decisions

- **(a) Companion default `Not now` → just-go never installs: UPHELD.** Matches ratified D6 / out-of-scope "no default-on install". Step 8 `yes` additionally preserves `/setup-companions`' own STOP gate even in just-go (verified: `plugin/commands/setup-companions.md:24`), so there is no path to an unconfirmed install.
- **(b) Frontier reply doubles as approval — satisfies @s18: UPHELD.** @s18 asks for *explicit* approval before `setup.sh`, not a *separate* one. The reply is explicit (`all defaults`/`go`/numbered), informed (the user has seen the full profile table and every recommended answer), and the file binds it in two places (L43, L97). Spec success criterion 1 literally requires "a single 'accept defaults' reply completes the interview", so a second gate would contradict the spec. Existing-config targets still get the plan → choose gate (L56–63, L100). Condition: Minor 4 (round-1 reply when a round 2 follows).
- **(c) Recorded local prefs not re-asked, except `companions=not_now`: UPHELD, with condition.** Consistent with D2 (user edits the file to change). `not_now` re-asked with `Not now` still recommended means `all defaults` passes through silently — not pushy. Condition: the same recorded→skipped logic must be resolved for `answers.env`-sourced *policy* decisions (Major 1) — right now the file says both "HIGH from answers.env → never asked" and "item 1 workflow_mode / item 2 hosts are in the round".
- **(d) Just-go on existing config → `--merge`, never `--overwrite`: UPHELD.** Consistent with L63 and hard rule L100; `--overwrite` stays gated on a seen plan plus an explicit ask.
- **(e) `use_gherkin` in consequential defaults: UPHELD.** It gates `{{#use_gherkin}}`/`{{^use_gherkin}}` blocks in `core/.claude/agents/pmo.md:40–50`, so it changes what renders. The listed set is complete for content-gating flags: `has_frontend` (requires: markers), `ticket_tracker` (Plane flag), `has_background_jobs` (backend-dev.md:43), `enforce_mutation_testing` (CLAUDE.md, HELP.md, orchestrator.md, mutation-tester.md, mutate.py), `use_gherkin` (pmo.md) — all verified by grep over `core/`.

## Readability

Linear and followable: steps 1–8 in execution order, each step's output feeds the next, the scopes table is referenced from step 4 as "table below" and sits right after the steps. Tiers are defined once (step 1) and reused by name. Two spots would make two agents diverge — both are Majors below; both are one-clause fixes.

### Blockers

- None.

### Major

1. **`setup-template.md:15` vs `:37–38` — re-run behaviour for policy decisions is contradictory.** Step 1 says a prior `answers.env` makes its values HIGH and HIGH is "Never asked"; step 3 lists `workflow_mode` (item 1) and target hosts (item 2) unconditionally. On a project with an existing `answers.env`, agent A skips both, agent B asks both. Fix (one clause, either policy is acceptable — pick one): e.g. append to L35 or L37 "Items 1–2 are asked only when no prior `answers.env` supplies them; otherwise they appear in the table as HIGH (source `answers.env`) and follow the HIGH rule." (Or the inverse: "policy decisions are re-asked on every run with the recorded value as the recommendation.")
2. **`setup-template.md:40` + `:47–49` + `:78–81` — "both installed → skip question 4" leaves `companions` unrecorded and step 8 unrouted.** Step 4 records `companions=yes|not_now|never` from the answer; when the question is skipped there is no answer, and step 8 switches on "the recorded value". Agent A writes nothing and skips step 8; agent B writes `not_now` and mentions `/setup-companions` for tools already installed; a *previously recorded* `yes` re-enters step 8 and re-runs the companions flow on every later run. Fix (one clause on L40): "When both are installed, skip question 4 **and step 8**; leave any existing `companions` key untouched."

### Minor

3. **Step renumbering orphaned "step 5" cross-references.** Gitignore is now step 6, but `contract.md:12` (@s4 "step 5"), `spec.md:9`, `spec.md:41` (D1), `spec.md:47` (D7) all point at step 5. The contract is the signed artifact; either amend those four references to "step 6" (mechanical, same commit) or leave the number and accept the drift. Recommend amending — the mf1 verdict also cites "step 5", so future readers will grep for it.
4. **`setup-template.md:43–45` — round-1 reply when a round 2 follows.** L43 makes "that reply" the approval; L45 says round 2's reply "is the approval". The intent (round-1 reply is *not* authorization when it unlocks round 2) is inferable but not stated. One clause on L45: "…in that case the first reply is not yet the approval; nothing renders until the second round's reply."
5. **Sibling docs now describe the old interview** (not in this diff; pre-existing, and `plugin/README.md:61` still lists `answers.env` in the gitignore block — an MF1 miss that contradicts @s4/D1). `plugin/README.md:58–61` ("Draft an answers.env… wait for approval or edits"), `docs/install/cursor.md:19` ("interview asks one multi-select host question"), `README.md:67`. Root README is still loosely true; plugin README step 5 is actively wrong. Either a 3-line touch now (files_hint allows 4 files) or a named item for MF6's docs pass — flagging so it doesn't fall through.

### Nits

- `setup-template.md:116` "passes `--auto`" — `--auto` is not a `setup.sh` flag (grep confirms); it is an argument to this command. Pre-existing wording; "passes `--auto` to this command" removes the ambiguity.
- `setup-template.md:100` hard rule "then let them choose" has no carve-out for just-go, which L116 overrides. Variant sections conventionally override, so acceptable; a parenthetical "(just-go: `--merge`, see variant)" would close it.
- "just go" now carries three meanings in the template (RBW narration bypass, session autonomy switch per mf2, and this skip-round variant). The setup one requires the "setup, just go" prefix, so it is disambiguated; the file is also (correctly) silent that a recorded `autonomy_mode=autonomous` does *not* imply just-go for setup — worth one clause if it ever confuses.
- `setup-template.md:41` list item "5. …" reads oddly as an elision; "5+." or "then:" would be clearer. Cosmetic.
- `verbosity` sits in the scopes table (L90) with no question and no consumer — pre-existing MF1 text, not this diff; noted for the record.

### Process

- Micro-PR: 2/4 files, ~72 LOC churn / 500. Surgical — every hunk traces to @s13–@s18; no drive-by edits outside the interview shape (the companions paragraph at L142 was rewritten only to point at step 8).
- `features.json` `pending → in_progress` is correct at this stage; flip to `done` after the two Majors land.
- No security surface: instruction-only markdown, no hooks/permissions/external input touched. `security-reviewer` not required.
- Adversarial mode not triggered (70-line diff, no code, no auth/data); skeptic pass done inline — the two Majors are its output.

### Initial verdict

- [ ] APPROVED   - [x] CHANGES REQUESTED

Two one-clause wording fixes (Majors 1–2) and the contract/spec step-number amendment (Minor 3). No scenario is unmet; re-review can be a read of the amended lines only.

## Re-review after requested changes

**Stats:** 4 implementation/doc files, +55/−25, plus the one-line `features.json` state change. This is the contracted 4-file implementation cap; workflow state and this verdict are artifacts. Branch `feature/setup-evolution`, main untouched.

- Major 1 resolved: prior `workflow_mode` / `TARGET_HOSTS` values are shown as `recorded` and items 1–2 are asked only when absent.
- Major 2 resolved: when both companions exist, question 4 and step 8 are skipped; prior state is preserved, and step 8 only acts on a value recorded this run.
- Minor 3 resolved: all four stale step-5 references now say step 6.
- Minor 4 resolved: when round 2 exists, round 1 is explicitly not approval; rendering waits for the final reply.
- Minor 5 resolved: `plugin/README.md` now gitignores `.claude/answers.local.env` and calls `answers.env` committed policy.
- Requested nits remain untouched.

`bash scripts/build.sh --check` → generated trees in sync. `python3 scripts/validate-packaging.py` → packaging valid @ v0.8.0. `git diff --check` → clean. No security surface; security review not required.

### Final verdict

- [x] APPROVED   - [ ] CHANGES REQUESTED
