# Upgrade Fidelity (v0.9.2) — Contract

Gate 1 status: **approved by the maintainer on 2026-09-02**.
Workflow: SDD+TDD, gated.

## MF1 — managed-baseline (@s1..@s9)

Design notes: committed lock-file pattern; no inline file markers. Leverage:
current staging/classification paths, `hashlib`, JSON, and managed-file rules.
Security review is required because target-controlled state affects overwrite
classification.

- **@s1 [FR-001, SC-002]** Given a fresh successful render, Then
  `agent-config.lock.json` is valid deterministic JSON containing schema version,
  template version, selected hosts, and sorted per-file SHA-256 baselines.
- **@s2 [FR-001, FR-002, SC-001]** Given a recorded managed file is unchanged
  from its baseline but differs from the new render, Then the plan labels it
  `STALE-MANAGED` and may offer it for explicit overwrite.
- **@s3 [FR-002, SC-001]** Given a recorded managed file differs from both its
  baseline and the new render, Then it is `CUSTOMIZED-MANAGED`, is kept by merge,
  and is absent from the generated overwrite list.
- **@s4 [FR-002, FR-003, SC-001]** Given a differing managed path has no usable
  baseline, Then it is `LEGACY`, stays untouched, and requires the user to name
  it explicitly before overwrite.
- **@s5 [FR-001, SC-002]** Given user-owned, local, symlink, or merge-managed
  surfaces, Then the lock file does not record them as overwrite-managed paths.
- **@s6 [FR-001, SC-002]** Given merge keeps a stale or customized file, Then
  its prior baseline remains unchanged; added, overwritten, and current-identical
  entries advance to the current baseline.
- **@s7 [FR-003, SC-003]** Given missing lock state, Then upgrade preview treats
  differing managed paths as legacy and does not invent prior ownership.
- **@s8 [FR-003, SC-003]** Given malformed JSON, unsupported schema, absolute or
  parent-traversing paths, or invalid hashes, Then state is ignored with one
  concise warning and cannot authorize overwrite or deletion.
- **@s9 [FR-001, FR-002, FR-003, SC-001, SC-002, SC-003]** Given source,
  bundled setup, and four host renders, Then lock/classification behavior and
  focused smoke checks agree with no dependency or placeholder regression.

## MF2 — override-drift (@s10..@s15)

Design notes: no pattern — one checker at the build boundary. Leverage:
`build.sh --check`, exact Markdown headings, and checked-in override files.

- **@s10 [FR-004, SC-004]** Given the current source/override mapping, Then the
  checker verifies all four Codex whole-file overrides and the patterns and
  principles plugin adaptations.
- **@s11 [FR-004, SC-004]** Given every source H2 exists in its override, Then
  the checker exits zero and stays quiet.
- **@s12 [FR-004, SC-004]** Given a source gains an H2 missing from the override,
  Then the checker exits non-zero and names the source, override, and heading.
- **@s13 [FR-004, SC-004]** Given an override contains an exact
  `override-ignore-h2` marker for a deliberately omitted heading, Then only that
  heading is exempt and the checker passes.
- **@s14 [FR-004, SC-004]** Given a broad, malformed, stale, or unmatched ignore
  marker, Then it does not hide another heading and the checker fails clearly.
- **@s15 [FR-004, SC-004, SC-008]** Given normal and `--check` builds, Then the
  structural drift gate runs before generated-tree approval and focused fixtures
  pass without changing generated output bytes.

## MF3 — safe-prune (@s16..@s23)

Design notes: no pattern — one explicit mode on the existing merge planner.
Leverage: recorded managed paths, current plan labels, and target path guards.
Security review is required because the feature deletes target files.

- **@s16 [FR-005, SC-005]** Given the prior lock records a path the new render
  no longer emits and the target bytes still equal the recorded baseline, Then
  preview labels it `OBSOLETE`.
- **@s17 [FR-005, SC-005]** Given an obsolete recorded path was edited, replaced
  by a symlink, or cannot be proven safe, Then preview labels it
  `CUSTOMIZED-OBSOLETE` and never authorizes deletion.
- **@s18 [FR-005, SC-005]** Given ordinary `--merge`, Then every obsolete path
  is retained and reported; no delete occurs.
- **@s19 [FR-005, SC-005]** Given `--merge --prune`, Then only `OBSOLETE` regular
  files inside the target are deleted and each deletion is printed.
- **@s20 [FR-003, FR-005, SC-003, SC-005]** Given missing or invalid state, an
  unrecorded path, a user-owned path, or a traversal/absolute entry, Then prune
  deletes nothing from that case.
- **@s21 [FR-005, SC-005]** Given `--prune` without `--merge`, Then setup exits
  non-zero with one concise error before any target write.
- **@s22 [FR-005, SC-005]** Given prune succeeds, Then empty managed directories
  may be removed bottom-up, non-empty directories remain, state drops deleted
  entries, and a second identical run changes nothing.
- **@s23 [FR-005, SC-005, SC-008]** Given source and bundled setup plus existing
  merge tests, Then focused deletion/security fixtures and the full regression
  suite pass on Bash 3.2 with Python stdlib only.

## MF4 — answers-and-release (@s24..@s33)

Design notes: no pattern — parse once at the current boundary and apply one
post-success ignore rule. Leverage: `shlex`, existing examples, host deduplication,
packaging validation, README, and upgrade guide. Security review is required
because answers and `.gitignore` are user-controlled inputs.

- **@s24 [FR-006, SC-006]** Given `TARGET_HOSTS="Cursor,GROK"` or a quoted value
  supplied to another key, Then matching outer quotes are removed and the value
  renders literally.
- **@s25 [FR-006, SC-006]** Given mixed-case or repeated host names, Then hosts
  are normalized case-insensitively, deduplicated, and rendered in canonical
  order.
- **@s26 [FR-006, SC-006]** Given an explicit `--host`, Then it overrides the
  parsed recorded value and receives the same normalization/validation.
- **@s27 [FR-006, SC-006]** Given unquoted values containing spaces or `#`, empty
  values, or all checked-in examples, Then existing rendering remains compatible.
- **@s28 [FR-006, SC-006]** Given a value starts with an unmatched quote or has
  trailing material after a closing outer quote, Then setup refuses with a
  concise line-numbered parse error and writes nothing.
- **@s29 [FR-007, SC-007]** Given a successful write and an existing
  `.claude/answers.local.env`, Then `.gitignore` is created or appended with one
  exact `.claude/answers.local.env` rule and the change is reported.
- **@s30 [FR-007, SC-007]** Given the rule already exists, Then setup does not
  duplicate or rewrite it; given no local answers file, it does not touch
  `.gitignore`.
- **@s31 [FR-003, FR-007, SC-003, SC-007]** Given preview, abort, parse failure,
  or an escaping `.gitignore` symlink, Then the renderer does not modify it.
- **@s32 [FR-008, SC-008]** Given release docs and manifests, Then README and the
  v0.9.2 upgrade section explain the lock, classifications, prune gate, answers
  compatibility, first-upgrade legacy behavior, and all four manifests equal
  `0.9.2` without packaging skew.
- **@s33 [FR-006, FR-007, FR-008, SC-006, SC-007, SC-008]** Given the release
  candidate, Then spec/build/packaging/full smoke, double-build determinism,
  shell/JSON checks, and all 24 example/host renders pass with zero placeholders.
