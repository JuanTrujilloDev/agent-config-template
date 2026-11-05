# SDD Grammar (v0.9.0) — Contract

Gate 1 status: **approved by the maintainer on 2026-09-02** (“Yep go”).
Workflow: SDD+TDD, gated.

## MF1 — contract-grammar (@s1..@s6)

Design notes: no pattern — direct instruction and smoke-test changes. Leverage:
existing pmo/orchestrator/feature/HELP surfaces and grep-style smoke helpers.

- **@s1 [FR-001, SC-001]** Given PMO writes a spec, When it defines behavior
  and success, Then it creates separate numbered `## Functional requirements`
  (`FR-###`) and `## Success criteria` (`SC-###`) sections.
- **@s2 [FR-002, SC-001]** Given PMO writes a contract, When it creates each
  Given/When/Then scenario, Then that scenario cites at least one defined FR
  and at least one defined SC.
- **@s3 [FR-003, SC-002]** Given an unresolved decision, When PMO records it,
  Then it writes exactly `NEEDS CLARIFICATION: <question>` on its own line and
  lists every marker before requesting Gate 1 approval.
- **@s4 [FR-003, SC-002]** Given any clarification marker remains in the spec
  artifacts, When the orchestrator or `/feature` reaches Gate 1, Then it refuses
  implementation and prints the unresolved questions.
- **@s5 [FR-001, FR-002, SC-001]** Given the usage guide, When a user reads the
  spec template example, Then it shows FR/SC sections and a traced scenario.
- **@s6 [FR-001, FR-002, FR-003, SC-001, SC-002]** Given MF1 changes are
  rendered for every host, Then source/generated parity and focused smoke checks
  pass with no leftover template markers.

## MF2 — mini-feature-grammar (@s7..@s13)

Design notes: no pattern — a single Python stdlib validator with small pure
checks. Leverage: JSON stdlib, current ledgers, existing CI and smoke harness.

- **@s7 [FR-004, SC-003]** Given a schema v2 mini-feature, When validation runs,
  Then it requires `id`, `name`, `scenarios`, `depends_on`, `parallel`,
  `files_hint`, `max_files`, `max_loc`, `status`, and `verified_by_human` with
  the documented types and allowed values.
- **@s8 [FR-004, SC-003]** Given invalid IDs, duplicate names/scenarios,
  undefined scenario references, unknown dependencies, a self-dependency, or a
  dependency cycle, Then validation exits non-zero with the file and reason.
- **@s9 [FR-005, SC-003]** Given a mini-feature whose dependency is not `done`,
  When the orchestrator selects work, Then it skips that mini-feature even if
  `parallel` is true.
- **@s10 [FR-005, SC-003]** Given multiple dependency-ready mini-features, Then
  `parallel: false` preserves one-at-a-time order; `parallel: true` is only a
  scheduling hint and never bypasses gates or `one_at_a_time`.
- **@s11 [FR-004, SC-003]** Given the PMO and workflow docs, Then they define a
  tracer bullet as touching every required layer, independently demoable,
  fitting one context window and one micro-PR, and declaring blockers.
- **@s12 [FR-004, FR-005, SC-003]** Given legacy unversioned ledgers coexist
  before MF3, Then the validator accepts their current minimum shape while
  applying strict validation to schema v2 ledgers.
- **@s13 [FR-004, SC-001, SC-003]** Given CI runs, Then
  `python3 scripts/validate-specs.py` is a required repository check, and
  focused negative fixtures prove failures.

## MF3 — schema-version-and-migration (@s14..@s20)

Design notes: no pattern — one deterministic stdlib JSON transformer. Leverage:
the MF2 validator and the checked-in historical ledgers.

- **@s14 [FR-006, SC-004]** Given a legacy repository `features.json`, When
  `python3 scripts/migrate-specs.py` runs, Then it becomes schema version 2 with
  every required MF field while preserving feature, IDs, array order, scenario
  order, limits, status, and existing human-verification values.
- **@s15 [FR-006, SC-004]** Given legacy `files`, `files_hint`, or `after`
  fields, Then migration follows spec decisions D4 exactly and removes only
  replaced legacy fields.
- **@s16 [FR-006, SC-004]** Given a completed historical item without
  `verified_by_human`, Then migration records `skipped`; absent file hints
  become `[]` and the output remains valid JSON with a trailing newline.
- **@s17 [FR-006, SC-004]** Given copies of every pre-v0.9 ledger, When migrated
  twice, Then the first output validates and the second run is byte-idempotent.
- **@s18 [FR-006, SC-003]** Given migration completes, Then every live ledger
  under `docs/specs/*/features.json` declares `schema_version: 2`, and the
  validator rejects unversioned or unknown versions.
- **@s19 [FR-006, SC-003]** Given `/feature` sees an unversioned or unsupported
  ledger, Then it refuses to continue and names exactly
  `python3 scripts/migrate-specs.py` as recovery.
- **@s20 [FR-006, SC-004]** Given MF3 is complete, Then migrated-file budget
  exception evidence, validator tests, build/check, and smoke checks pass.

## MF4 — contract-amendments (@s21..@s27)

Design notes: no pattern — append-only amendment evidence and direct state
transitions. Leverage: current contract, ledger, and progress directory.

- **@s21 [FR-007, SC-005]** Given Gate 1 was approved and contract behavior
  changes, Then the affected section appends
  `*(Amended at <ISO date/time> — <reason>)*` without rewriting prior approval
  evidence.
- **@s22 [FR-007, SC-005]** Given affected items are `pending` or `spec_ready`,
  Then amendment resets them to `pending`; `in_progress` or `done` becomes
  `needs-rework`; `blocked` remains blocked pending reassessment.
- **@s23 [FR-007, SC-005]** Given an amendment affects one mini-feature, Then
  only it and transitive dependents are reset; unrelated work keeps its status.
- **@s24 [FR-007, SC-005]** Given any amendment lacks a later approval entry in
  `progress/gate1.md`, When `/feature` runs, Then it refuses implementation as a
  stale Gate 1.
- **@s25 [FR-007, SC-005]** Given the maintainer reapproves, Then
  `progress/gate1.md` appends timestamp, approver text, and current amendment
  reference; work may resume from the first ready item.
- **@s26 [FR-004, FR-007, SC-003, SC-005]** Given validation sees
  `needs-rework`, Then it accepts the status and applies the normal dependency
  rules before work can restart.
- **@s27 [FR-007, SC-005]** Given direct amendment/status fixtures, Then all
  transition, transitive-reset, stale-approval, and reapproval checks pass.

## MF5 — principles-double-gate (@s28..@s33)

Design notes: no pattern — reuse one deviation record at planning and review.
Leverage: existing principles, pmo Design notes, and judge verdict.

- **@s28 [FR-008, SC-006]** Given PMO finishes decomposition, Then before Gate 1
  it checks every mini-feature against the project principles and records a
  `### Principles deviation table` under Design notes.
- **@s29 [FR-008, SC-006]** Given no deviation exists, Then a table containing
  one explicit `None` row is valid; omission of the table is invalid.
- **@s30 [FR-008, SC-006]** Given a deviation exists, Then its row names the
  principle, decision, present reason, and mitigation; speculative convenience
  is not an acceptable reason.
- **@s31 [FR-008, SC-006]** Given judge reviews an implementation, Then it
  rechecks the diff against the same table, cites the applicable row, and treats
  an unrecorded violation as a blocker.
- **@s32 [FR-008, SC-006]** Given a justified deviation fixture, Then both the
  pre-Gate and judge assertions pass; a missing/unused deviation fixture fails.
- **@s33 [FR-008, SC-006]** Given MF5 is rendered across Claude, Cursor, Grok,
  and Codex, Then the two checks and shared-table language remain equivalent.

## MF6 — brownfield-readme-release (@s34..@s41)

Design notes: no pattern — concise docs, fixed manifest values, existing checks.
Leverage: current install/workflow docs, README, build, packaging, and smoke
harness.

- **@s34 [FR-009, SC-007]** Given an existing project, Then
  `docs/guides/existing-projects.md` gives a minimal sequence for survey,
  preview, non-destructive merge, source-of-truth conflicts, host selection,
  contract approval, checks, and rollback.
- **@s35 [FR-009, SC-007]** Given the guide discusses trackers and companions,
  Then it asks what the user already uses, keeps every tracker optional, and
  presents graphify, ponytail, and UI tooling as opt-in companions.
- **@s36 [FR-010, SC-008]** Given a new reader opens README, Then within its
  first 80 lines they can identify the value, Claude/Cursor/Grok/Codex support,
  each install path, and the first `/spec` or `/feature` command.
- **@s37 [FR-010, SC-008]** Given README's workflow/reference content, Then it
  explains FR/SC traceability, clarification blocking, versioned mini-features,
  amendments, and double principles review with one workflow diagram and one
  command table, linking to deeper docs instead of repeating them.
- **@s38 [FR-010, SC-008]** Given README is refreshed, Then it is at most 253
  lines and retains upgrade, examples, companion, credits, support, and license
  paths needed by current users.
- **@s39 [FR-010, SC-008]** Given README credits, Then it links GitHub Spec Kit,
  states MIT-licensed inspiration, and does not imply copied artifacts or
  affiliation.
- **@s40 [FR-010, SC-009]** Given release metadata, Then plugin, marketplace,
  and Codex manifests all report `0.9.0`, the upgrade guide summarizes the
  release, and packaging validation reports no skew.
- **@s41 [FR-010, SC-009]** Given final verification, Then spec validation,
  build/check, packaging, full smoke, double-build determinism, four-host
  rendering, JSON parsing, shell syntax, and zero-placeholder checks all pass.
