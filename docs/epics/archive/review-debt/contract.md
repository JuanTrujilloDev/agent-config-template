# Review Debt (v0.8.3) — Contract

Gate 1 status: **approved by the maintainer on 2026-09-02** (“Go for
everything”). Workflow: SDD+TDD; autonomous for this session, with no push or
PR without separate approval.

## MF1 — hook-and-setup-bugs (@s1..@s9)

Design notes: no pattern — direct fixes in existing parsers/counting paths.
Leverage: current fixed-string `case` banner, setup staging/classification, and
existing smoke helpers. Security review is required because hooks and setup read
user-controlled files/environment variables.

- **@s1 (smoke)** Given preference values with CRLF and surrounding spaces,
  When the rendered core `coding-reminder.sh` handles a coding prompt, Then it
  selects the same autonomy/output banner as clean whitelisted values, exits 0,
  and writes nothing to stderr.
- **@s2 (smoke)** Given unrecognized or shell-shaped preference content, When
  either the core or plugin hook runs, Then no untrusted value appears in output,
  no command is executed, and core/plugin results are identical.
- **@s3 (smoke)** Given setup answers supplied through stdin, When a differing
  target produces the merge plan, Then the suggested command keeps
  `--answers -` and an adjacent one-line note says the same answers must be piped
  again; file-backed answers keep a directly replayable command.
- **@s4 (smoke)** Given `--host claude,grok` stages overlapping destination
  paths, When `--merge` keeps differing files, Then `skipped N files` counts each
  target-relative path once and equals the unique skipped-path set.
- **@s5 (smoke)** Given a bundle-shaped setup copy with a required host source
  missing and no repository `scripts/`, When setup validates its source trees,
  Then it exits non-zero and tells the user to reinstall/update the plugin, not
  to run `scripts/build.sh`.
- **@s6 (smoke)** Given the same missing tree in a repository checkout that has
  `scripts/build.sh`, Then the error retains the repository build recovery hint.
- **@s7 (smoke)** Given both protected-branch variables are set differently,
  When core and plugin `agent-enforcement.sh` evaluate a mutating edit, Then
  `AGENT_CONFIG_PROTECTED_BRANCHES` wins.
- **@s8 (smoke)** Given only `CLAUDE_CONFIG_PROTECTED_BRANCHES`, or neither key,
  Then the legacy key and rendered default respectively still guard branches;
  the diagnostic names the host-neutral key and its legacy fallback.
- **@s9** Given MF1 complete, Then `bash -n` passes for every touched shell file,
  generated copies are rebuilt, setup symlink-containment tests still pass, and
  `scripts/build.sh --check`, packaging validation, and the full smoke suite are
  green.

## MF2 — docs-catch-up (@s10..@s14)

Design notes: no pattern — documentation-only corrections. Leverage: existing
file map, install guides, capability matrix, README sections, and grep helpers.

- **@s10 (smoke)** Given `docs/what-each-file-does.md`, Then it documents
  `hosts/`, `cursor/`, `codex/`, `scripts/smoke/`, `docs/design-system/`,
  `docs/CONTEXT.md`, `.claude/answers.local.env`, `/integrate`, the patterns rule
  and references, and `--overwrite-files`.
- **@s11 (smoke)** Given `README.md`, Then it names MASTER.md, CONTEXT.md,
  `output_style`, `agent_style`, and `--overwrite-files` in their existing
  workflow/setup sections without claiming any companion is mandatory.
- **@s12 (smoke)** Given the host capability matrix, Then separate rows describe
  the autonomy/output banner and brand MASTER behavior for Claude, Cursor, Grok,
  and Codex without overstating native hook support.
- **@s13 (smoke)** Given `docs/install/cursor.md`, Then slash-command/skill
  availability is described as stack-dependent where `requires:` applies, not
  as “every” command in every render.
- **@s14 (smoke)** Given rendered Cursor `AGENTS.md`, Then it points models to
  project `.claude/skills/` and states Cursor reads those skills natively;
  build/check, packaging validation, and smoke remain green.

## MF3 — instruction-text-debt (@s15..@s23)

Design notes: no pattern — ordering, paragraph boundaries, and conditional
wording in existing instructions. Leverage: existing Mustache flags plus
`grep_case` and `before` smoke helpers.

- **@s15 (smoke)** Given core and plugin pmo instructions, Then `## CONVERSE`
  appears before artifact-definition/distillation sections and content is not
  otherwise reordered semantically.
- **@s16 (smoke)** Given core and plugin `/fix`, Then step 1 ends a paragraph
  after “before naming the cause.” and the reproduction/hypothesis rules remain
  intact.
- **@s17 (smoke)** Given `workflow_tdd=yes`, Then rendered `/feature` and
  CLAUDE.md describe TDD as the default with Gate 2; Given it is false/absent,
  Then they describe TDD as optional/on request. No unconditional “optional TDD”
  wording contradicts either render.
- **@s18 (smoke)** Given the principles rule, Then one cross-reference separates
  “just go” as Read-Before-You-Write narration bypass, a session autonomy switch,
  and setup’s skip-frontier-round phrase; it explicitly states stored
  `autonomy_mode=autonomous` does not activate setup just-go.
- **@s19 (smoke)** Given `/setup-template`, Then the frontier-round sequence
  spells out item 5 instead of an ellipsis and preserves the existing single
  numbered batch.
- **@s20 (smoke)** Given `/setup-template` hard rules and just-go mode, Then the
  non-destructive plan rule explicitly allows automatic `--merge` only for the
  user-requested just-go path and never allows automatic `--overwrite`.
- **@s21 (smoke)** Given `/setup-template` just-go wording, Then it says explicit
  phrasing or `--auto` is passed “to this command”; it does not imply setup.sh
  accepts `--auto`.
- **@s22 (smoke)** Given the brand MASTER responsive table, Then mobile rows
  contain a `TODO:` for device classes and game rows contain a `TODO:` for canvas
  scaler behavior.
- **@s23** Given MF3 complete, Then source/plugin parity checks pass, generated
  trees are rebuilt, both workflow-mode renders satisfy @s17, and the standard
  build/check/packaging/smoke sequence is green.

## MF4 — build-test-hygiene (@s24..@s31)

Design notes: no pattern — strengthen current functions and fixtures. Leverage:
`parse_frontmatter`, Python stdlib, checked-in smoke fixtures, and the existing
Report format. The physical-file budget exception is recorded in
`features.json`; no generated mirror counts toward it.

- **@s24 (smoke)** Given `scripts/build.sh`, Then function-scoped `out`, `name`,
  and `desc` variables are declared `local`, Bash 3.2 syntax remains valid, and
  generated output is byte-identical.
- **@s25 (smoke)** Given a command frontmatter description with an unescaped
  inner double quote, When packaging validation runs with PyYAML available,
  Then it exits non-zero and identifies that description.
- **@s26 (smoke)** Given the same seeded file while imports of `yaml` are made
  unavailable, Then the stdlib fallback also exits non-zero; a valid quoted
  description still passes in both modes.
- **@s27 (smoke)** Given `scripts/smoke/lib.sh`, Then `first_line` no longer uses
  the dead empty-string-to-zero `sed`, while `before` retains the same missing
  and ordering behavior.
- **@s28 (smoke)** Given the checked-in
  `scripts/smoke/fixtures/stale-render/`, Then it contains exactly two stale
  agents, one rule, and a regular `.claude/CLAUDE.md`; the merge test copies it
  into a temp target and asserts the expected labels without reading or editing
  the portfolio repository. The old portfolio `# MANUAL` check is removed.
- **@s29 (smoke)** Given the v0.8.2 adaptive-skills ledger, Then MF8’s `files`
  includes `scripts/smoke.sh` and the JSON remains valid without reformatting
  unrelated entries.
- **@s30 (smoke)** Given core and plugin `/audit`, `/design`, and `/fix`, Then
  each reads `agent_style` once with `terse` fallback and passes the standard
  `agent_style: <terse|descriptive> — return per "Report format" ...` line to
  every subagent it spawns; persisted artifacts remain prose.
- **@s31** Given MF4 complete, Then the stale fixture is self-contained, the
  no-PyYAML seed is reverted, double build is clean, and the standard
  build/check/packaging/smoke sequence is green.

## MF5 — companion-pin-and-release (@s32..@s36)

Design notes: no pattern — fixed install/version values and release prose.
Leverage: existing gated companion plan, three manifests, validator skew check,
and upgrade-guide structure.

- **@s32 (smoke)** Given Claude companion setup requests ui-ux-pro-max, Then its
  plan prints exactly `npm install -g ui-ux-pro-max-cli@2.15.0`, source, and
  written locations before the existing confirmation gate.
- **@s33 (smoke)** Given the same command, Then it explains the explicit
  unpinned/latest alternative without making it the default; ui-ux-pro-max stays
  optional and UI-only.
- **@s34 (smoke)** Given the Codex setup-companions skill, Then it carries the
  same pin, unpin guidance, detection, plan, and confirmation semantics.
- **@s35 (smoke)** Given the plugin, marketplace, and Codex manifests, Then all
  versions are `0.8.3` and packaging validation reports v0.8.3 with no skew.
- **@s36** Given `docs/upgrade-guide.md`, Then its v0.8.3 section summarizes the
  four setup/hook fixes, the host-neutral protected-branch variable with legacy
  fallback, the companion pin, and the upgrade command; final build/check,
  packaging, smoke, double-build, four-host render, shell syntax, JSON parse,
  and zero-placeholder checks all pass.
