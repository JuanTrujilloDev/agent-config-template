## Judge: mf5 workflow-vocabulary  (@s33..@s39)

**Stats:** 31 files changed (7 hand-written sources + 1 hosts override + 8 smoke files + 15 generated), +139/-411 lines (net -272 from the smoke.sh split).
**Scenario → test:** @s33 → 5 grep/before cases on rendered pmo.md ✓ ; @s34 → 7 cases (read-when-present, lazy create, format, project-only, before Decomposition, no other core ref, not rendered) ✓ ; @s35 → 9 cases on step 1 slice + ordering + no `{{` leftovers ✓ ; @s36 → 6 cases × 3 files (docs, plugin skill, codex override) ✓ ; @s37 → 4 cases (feature.md + upgrade-guide) ✓ ; @s38 → 14 parity cases + `build --check` ✓ ; @s39 → (human) performed below ✓

**Verified:** smoke 294 PASS / 0 FAIL; `build.sh --check` clean; `validate-packaging.py` ok; two consecutive builds byte-identical. Old monolithic `smoke.sh` (HEAD) run from `scripts/`: 236/0, case names identical to the new runner minus the 58 new @s33–@s38 cases — behaviour preserved. Ran under `/bin/bash` 3.2.57; no bash-4isms; `bash -n` clean on all 8 files. Every lib helper has a caller (`run_hook`/`first_line` are internal to `hook_case`/`before`).

**@s39 performed:** `/fix "button does nothing"`, no repro. Step 1 is the first instruction and is decidable — "a failing test or a command that fails for *this* bug and goes green only when fixed" is either producible in one step or not; with no repro the instruction is "stop and switch to `/feature`", which precedes step 2 "State the root cause". Hypotheses are gated to "only when the reproduction does not single out a cause", so with zero reproduction there is nothing to hypothesise from. Result: stop/redirect, no cause proposed. Escape hatch wording matches @s35 verbatim in intent.

**Originality spot-check:** fetched mattpocock `skills/engineering/domain-modeling/CONTEXT-FORMAT.md`. Their rules: "Define what it IS, not what it does", "One or two sentences max", "Only include terms specific to this project's context", "create a root CONTEXT.md lazily when the first term is resolved", `_Avoid_:` label. Ours: entry string is the contract-mandated format; the rule line is "Project terms only — what the term *is*, never how it is implemented" and "coin or disambiguate in conversation, and append later ones". Concepts adapted, no sentence reused. Glossary rules are unambiguous: when to read (CONVERSE, if present), when to create (first coined/disambiguated term), what goes in (project terms), what does not (implementation).

### Blockers
- none

### Major
- Micro-PR budget: hand-written surface is 16 files (core 4, docs 2, hosts/codex 1, scripts 9) vs limit 12. MF5 alone is 8; the `smoke.sh → scripts/smoke/` split adds 8 more and is a refactor unrelated to any @s33–@s39 scenario. Commit the harness split as its own `chore:` first (the diff itself just wrote that rule into feature.md/upgrade-guide), then MF5 on top. Not a code defect — a slicing one.

### Minor
- `scripts/smoke/mf5-vocabulary.sh` uses `$PH` (defined in `mf4-brand.sh:4`) and `$P_PMO` (defined in `mf3-ledger.sh:3`). Under the runner's `set -u`, mf5 only works because of load order. Hoist both into `lib.sh` next to `PMO`/`JUDGE` so each mf file is order-independent, as the runner header promises ("extend by adding lines to an mf file").
- Taxonomy note ("a command … never instructs the model to invoke one") is now contradicted by pre-existing `core/.claude/agents/ui-designer.md:14` ("say so and run `/design`"). Out of MF5 scope; log as a follow-up fix so the invariant is true on day one.

### Nits
- `core/.claude/agents/pmo.md:67` — `## CONVERSE` sits after the three artifact definitions and before `## Decomposition rules`; chronologically it is the first thing pmo does. Reads fine as three bullets (intent → brownfield → glossary), 6 lines, no bloat (117 → 123). Consider moving above `spec.md` in a later pass; not worth a re-render now.
- `fix.md` step 1 is ~60 words in one paragraph; the other steps are one line. Acceptable since it carries the whole gate, but a second sentence break after "before naming the cause." would help scanning.

### Verdict
- [x] APPROVED (content)   - [ ] CHANGES REQUESTED
Approve MF5 content as-is; land the smoke harness split as a separate `chore:` commit before the MF5 commit to respect the 12-file limit. No security surface touched — `security-reviewer` not required.
