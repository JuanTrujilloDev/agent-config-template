# Upgrade Fidelity (v0.9.2) — Spec

2026-09-02 | branch: feature/v0.9.2-upgrade-fidelity | based on v0.9.1 | mode: SDD+TDD, gated

## Problem

The renderer cannot prove whether a differing managed file is an untouched old
render or a user customization. It also cannot identify files removed by a new
template, and full-file host overrides can miss new source sections. Finally,
quoted answers and mixed-case host names fail before rendering, while the local
preferences ignore rule still depends on the invoking agent.

## Goal

Make upgrades explainable and safely repeatable: preserve customized files,
identify stale/legacy/obsolete files from recorded evidence, detect structural
override drift, accept common answer syntax, and keep local preferences out of
git without adding dependencies.

## Functional requirements

- **FR-001 — Record managed baselines.** After a successful write, the renderer
  maintains a committed `agent-config.lock.json` containing the template version,
  selected hosts, and SHA-256 baseline for each overwrite-managed regular file.
- **FR-002 — Classify from evidence.** Upgrade plans label existing files as
  `SAME`, `STALE-MANAGED`, `CUSTOMIZED-MANAGED`, or `LEGACY` using current
  render bytes plus the recorded baseline; user-owned and merge-managed files
  keep their existing treatment.
- **FR-003 — Fail safe on missing state.** Missing, invalid, or unsafe lock data
  never authorizes overwrite or deletion. Existing differing paths without a
  usable baseline are `LEGACY` and require an explicit path choice.
- **FR-004 — Detect override drift.** Build check verifies that each whole-file
  override retains every H2 heading from its source unless the override names an
  exact ignored heading next to the override.
- **FR-005 — Prune safely.** `--merge --prune` removes only obsolete paths that
  were recorded as managed and remain byte-identical to their recorded baseline.
  Customized, legacy, user-owned, symlinked, or out-of-target paths are kept.
- **FR-006 — Parse common answers.** The renderer accepts fully single- or
  double-quoted values, keeps compatible unquoted values, and handles host names
  case-insensitively after parsing answers once.
- **FR-007 — Protect local preferences.** After a successful write, if
  `.claude/answers.local.env` exists, the renderer creates or appends `.gitignore`
  with exactly one `.claude/answers.local.env` rule and reports the change.
- **FR-008 — Release consistently.** README and upgrade guidance explain the
  new behavior and all active plugin manifests move to `0.9.2` together.

## Success criteria

- **SC-001 — Drift is distinguishable.** Fixtures prove untouched old managed
  content is stale, edited managed content is customized, and unknown content is
  legacy without relying on file-format comments.
- **SC-002 — State is reproducible.** Fresh, overwrite, and merge writes produce
  deterministic valid lock JSON without recording user-owned, local, symlink, or
  merge-managed paths.
- **SC-003 — Corrupt state is harmless.** Malformed JSON, unsafe paths, and
  unsupported lock schemas produce a concise warning, no prune candidates, and
  no writes in preview mode.
- **SC-004 — Override drift blocks build check.** Every known override pair
  passes; a fixture source with an unhandled H2 fails; an exact local ignore
  marker permits only that heading.
- **SC-005 — Prune cannot eat user work.** Tests cover obsolete-unmodified
  deletion, customized-obsolete preservation, no-flag preservation, path escape,
  symlink, and idempotent repeat runs.
- **SC-006 — Answers remain compatible.** Fixtures cover quoted host lists,
  mixed-case/deduplicated hosts, spaces and `#` in values, empty values, malformed
  quotes, CLI host precedence, and existing unquoted examples.
- **SC-007 — Git ignore changes are narrow.** The rule is added once only after
  a successful write; preview/abort/failure and targets without the local file do
  not touch `.gitignore`.
- **SC-008 — Release checks are green.** Spec/build/packaging/smoke validation,
  deterministic double-build, 24 host renders, shell syntax, JSON parsing, and
  placeholder checks pass with four manifests at `0.9.2`.

## Decisions

- **D1 — One lock file, not comments in every output.** Use committed
  `agent-config.lock.json` instead of injecting version comments into Markdown,
  shell, Python, MDC, and strict JSON formats. One state file is format-safe,
  smaller, and gives prune the previous path set and exact hashes it needs.
- **D2 — Record only overwrite-managed regular files.** Exclude root
  `CLAUDE.md`, `docs/CONTEXT.md`, `docs/design-system/`, local settings,
  `.claude/settings.json`, and `.claude/CLAUDE.md`. Their existing user-owned,
  merge, or symlink rules remain authoritative.
- **D3 — Preserve per-file history.** A kept stale/customized entry retains its
  old baseline. Added, overwritten, or identical-to-current entries advance to
  the current template version. A missing/invalid entry remains legacy.
- **D4 — Preview before deletion.** Plans show `OBSOLETE` and
  `CUSTOMIZED-OBSOLETE`; ordinary `--merge` keeps both. Only explicit
  `--merge --prune` deletes `OBSOLETE`, after the existing realpath safety check.
- **D5 — Heading drift is intentionally heuristic.** Compare exact `## `
  headings, with exact `override-ignore-h2` comments for deliberate omissions.
  Reject source hashes and patch-style overrides: they add maintenance for
  wording changes that do not affect structure.
- **D6 — Parse once in Python.** Move recorded-host selection after the existing
  Python answer parser. Strip only a matching outer quote pair via stdlib
  `shlex`; reject malformed quoted values instead of guessing.
- **D7 — Gitignore is a post-success side effect.** It runs only after fresh,
  merge, or overwrite completes, preserves existing bytes/lines, and refuses an
  escaping symlink through the same target-boundary guard.
- **D8 — No migration command.** v0.9.1 projects begin as `LEGACY`; users review
  and explicitly overwrite chosen managed paths once. That successful upgrade
  establishes the baseline for future exact classification and prune.

## Out of scope

- Inline stamps inside every rendered file or rewriting strict JSON formats.
- Automatically overwriting `LEGACY`, `CUSTOMIZED-MANAGED`, or user-owned files.
- Pruning directories with content, unrecorded paths, or old files before a
  v0.9.2 baseline exists.
- A general shell parser, dotenv interpolation, command substitution, or
  sourcing `answers.env`.
- v0.10.0 evaluation harness, brand-token generation, companion lifecycle manager,
  extra host packages, or branch-tokenizer work.

## Design notes

### Pattern ledger

- MF1: manifest/lock-file pattern — exact previous baselines are required across
  independent setup runs; rejected inline markers because output formats differ.
- MF2: no pattern — one small stdlib checker called by the existing build gate.
- MF3: no pattern — extend the current plan/apply loop with one explicit flag.
- MF4: no pattern — tighten the existing parser and post-success housekeeping.

### Principles deviation table

| Principle | Decision | Reason | Mitigation |
|---|---|---|---|
| None | No deviation. | The lock file replaces per-file markers and every behavior extends an existing boundary. | Stdlib only, explicit destructive flag, focused fixtures, and current path guards. |

### Leverage

- **MF1:** current staging tree, `classify`, managed/user-owned boundaries,
  `hashlib`, manifest version discovery, and JSON validation.
- **MF2:** current `build.sh --check`, exact H2 headings, and stdlib parsing.
- **MF3:** current no-write plan, `--merge`, overwrite allowlist, and realpath
  checks; the lock supplies the only deletion allowlist.
- **MF4:** current answers loop, `shlex`, host collision checks, `.gitignore`,
  packaging validator, and release matrix.

## Delivery

Implement the four mini-features in dependency order. SDD+TDD Gate 2 applies to
each slice. Judge reviews every slice; security review is required for MF1, MF3,
and MF4 because they read user-controlled files or change write/delete behavior.
Stop before every commit. Push, publish, merge, tags, and marketplace submissions
require separate explicit approval.
