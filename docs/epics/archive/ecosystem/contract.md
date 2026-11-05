# Ecosystem (v0.10.0) — Contract

Gate 1 status: **approved by the maintainer on 2026-09-02**.
Workflow: SDD+TDD, gated.

## MF1 — model-eval-harness (@s1..@s8)

Design notes: table-driven CLI Adapter; no shell execution and no judge model.
Leverage: the five current `MANUAL` scenarios, JSONL, stdlib subprocess/JSON,
render fixtures, and manual GitHub Actions. Security review is required because
the runner starts external programs and may create disposable workspaces.

- **@s1 [FR-001, SC-001]** Given the checked case catalog, Then it contains each
  current manual behavior ID exactly once plus at least one `/spec` to `/feature`
  workflow case, and rejects missing fixtures, invalid modes, duplicate IDs, or
  incomplete rubrics.
- **@s2 [FR-003, SC-003]** Given list, validation, ordinary smoke, or normal CI,
  Then no Claude, Codex, Cursor, or Grok process starts and no paid API is called.
- **@s3 [FR-002, SC-002]** Given fake host executables, Then argv uses the current
  non-interactive entry points—`claude -p`, `codex exec`, `cursor-agent -p`, and
  `grok -p --no-auto-update`—without a shell, and host-specific output is reduced
  to one normalized response record.
- **@s4 [FR-002, FR-004, SC-002, SC-004]** Given fake success, non-zero exit,
  timeout, malformed output, missing binary, or missing authentication, Then the
  runner deterministically reports pass, fail, error, or skip with a concise
  reason and duration.
- **@s5 [FR-003, SC-003]** Given a response-only live case and explicit `--run`,
  Then it may run in a disposable fixture copy; given no `--run`, the runner
  prints the plan and exits without executing the host.
- **@s6 [FR-003, SC-003]** Given a write-capable case, Then it refuses unless
  both `--run` and `--allow-writes` are present, verifies the workspace is a
  disposable copy outside the source repository, and never passes the source
  working tree as the host cwd.
- **@s7 [FR-004, SC-004]** Given captured outputs/workspaces, Then required and
  forbidden patterns, maximum lines, expected files, and expected file content
  produce the same JSON result on repeat runs without another model.
- **@s8 [FR-005, SC-005]** Given the manual live-eval workflow, Then selected
  cases/hosts run only on dispatch, absent credentials skip, secret values and
  inherited environment dumps are absent from logs/results, and sanitized JSON
  is uploaded while all existing regression checks remain green.

## MF2 — brand-tokens-code (@s9..@s15)

Design notes: no pattern — one semantic token source and the existing design
workflow. Leverage: UI capability detection, `MASTER.md`, `/design`, UI designer,
frontend guidance, judge, and SHA-256 from the standard library.

- **@s9 [FR-006, SC-006]** Given a fresh project with `has_ui=true`, Then
  `docs/design-system/tokens.json` renders as valid placeholder-free semantic
  tokens and `MASTER.md` identifies it as the reusable value source.
- **@s10 [FR-006, SC-006]** Given a fresh non-UI project, Then neither the token
  source nor other design-system artifacts are rendered.
- **@s11 [FR-007, SC-007]** Given `/design` in a web, Flutter, Unity, desktop, or
  unknown UI project, Then it reuses the existing theme facility and emits
  exactly one relevant native target, using JSON-only for the unknown fallback.
- **@s12 [FR-007, SC-007]** Given a native target is created or refreshed, Then
  its synchronization record contains the token-source SHA-256, target path,
  target SHA-256, adapter kind, and no absolute machine-specific path.
- **@s13 [FR-008, SC-007]** Given a missing target, mismatched source hash,
  mismatched target hash, or duplicated raw brand value outside a documented
  exception, Then judge reports a blocking design-system violation.
- **@s14 [FR-008, SC-007]** Given a page needs a local visual variation, Then it
  references semantic tokens or records the new semantic token in the shared
  source; it does not create an undocumented parallel palette or typography set.
- **@s15 [FR-006, FR-007, FR-008, SC-006, SC-007]** Given fresh, UI, non-UI,
  merge, and all-host renders, Then focused fixtures, build, packaging, smoke,
  valid JSON, placeholder, and generated-mirror checks pass.

## MF3 — companion-lifecycle (@s16..@s22)

Design notes: manifest pattern — one lock owns companion metadata across host
surfaces. Leverage: current `/setup-companions`, installed-version probes,
confirmation language, build mirroring, and packaging validation. Security review
is required because actions may download, update, or remove executable content.

- **@s16 [FR-009, SC-008]** Given the companion lock, Then every supported tool
  has one package/source, exact version, install method, executable probe, and—
  for direct downloads—valid SHA-256 digest, with deterministic key ordering.
- **@s17 [FR-009, SC-008]** Given Claude, Cursor, Grok, and Codex companion
  instructions, Then they resolve metadata from the lock or a generated exact
  copy; packaging validation fails any version/source/digest drift.
- **@s18 [FR-010, SC-008]** Given `plan`, Then it reports intended versions and
  commands without network or mutation; given `doctor`, Then it inspects only
  local state and reports missing, healthy, outdated, or unverifiable.
- **@s19 [FR-010, SC-008]** Given `install` or `update`, Then the workflow shows
  the exact source/version/action, asks immediately before mutation, verifies the
  installed result, and a repeat at the pinned version changes nothing.
- **@s20 [FR-009, FR-010, SC-008]** Given a direct-download artifact, Then its
  bytes are checked against the lock before installation; mismatch aborts without
  replacing an existing install.
- **@s21 [FR-010, SC-008]** Given `uninstall`, Then only named companion-owned
  files/packages are listed, confirmation occurs immediately before removal, a
  refusal changes nothing, and unrelated user configuration is preserved.
- **@s22 [FR-009, FR-010, SC-008]** Given fake package/download commands and all
  generated bundles, Then offline, mutation, failure, idempotence, digest, and
  confirmation fixtures pass with no real network or home-directory changes.

## MF4 — branch-guard-tokenizer (@s23..@s28)

Design notes: no pattern — replace one heuristic at its existing boundary.
Leverage: Cursor hook payload extraction, protected-branch discovery, Python
stdlib `shlex`, and hook smoke fixtures. Security review is required because the
hook interprets untrusted shell text.

- **@s23 [FR-011, SC-009]** Given a protected branch and direct `git commit` or
  `git push`, including whitespace/options and a path-qualified git executable,
  Then the hook blocks and names the protected branch.
- **@s24 [FR-011, SC-009]** Given a protected branch and a supported
  `sh|bash|zsh -c` wrapper whose payload executes commit/push, Then the nested
  command is tokenized and blocked.
- **@s25 [FR-011, SC-009]** Given multiple shell command segments and any segment
  executes git commit/push, Then the hook blocks; quoted separators remain part
  of their literal argument.
- **@s26 [FR-011, SC-009]** Given `echo "git push"`, prose, grep/search patterns,
  `git log --grep=push`, or other read-only git commands, Then the hook allows.
- **@s27 [FR-011, SC-009]** Given malformed/unparseable input, a non-git command,
  or a non-protected branch, Then the hook fails open and emits no false block.
- **@s28 [FR-011, SC-009]** Given Bash 3.2, JSON payload variants, fresh Cursor
  render, build, packaging, and full smoke, Then focused tokenizer fixtures pass
  and docs still describe the hook as a partial guardrail, not a security boundary.

## MF5 — release-0-10-0 (@s29..@s33)

Design notes: no pattern — synchronize current release metadata and docs.
Leverage: manifest parity validation, README, upgrade guide, deterministic build,
and the 24-render release matrix.

- **@s29 [FR-012, SC-010]** Given active plugin metadata, Then the Claude plugin,
  Claude marketplace, Cursor plugin, and Codex plugin versions all equal `0.10.0`
  and their existing identity/install paths remain valid.
- **@s30 [FR-012, SC-010]** Given README and upgrade guidance, Then they concisely
  explain model-eval opt-in gates, token artifacts, companion lifecycle, branch
  parser limits, preserved local files, and the `0.9.2` to `0.10.0` path.
- **@s31 [FR-012, SC-010]** Given the release candidate, Then spec validation,
  build check, packaging validation, full smoke, shell syntax, JSON parsing, and
  placeholder checks all pass.
- **@s32 [FR-012, SC-010]** Given two clean builds, Then their bytes are identical;
  given all six examples across Claude, Cursor, Grok, and Codex, Then all 24
  renders succeed without unresolved template placeholders.
- **@s33 [FR-005, FR-012, SC-003, SC-005, SC-010]** Given final release checks,
  Then catalog/fake-adapter validation runs but no paid model process starts, all
  five mini-features are done, and generated mirrors match their sources.
