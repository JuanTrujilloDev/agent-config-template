# SDD Grammar (v0.9.0) — Spec

2026-09-02 | branch: feature/v0.9.0-sdd-grammar | based on v0.8.3 | mode: SDD+TDD, gated

## Problem

The workflow requires an approved contract, but its artifacts are still loose
Markdown and historically inconsistent JSON. Requirements and measurable
success are mixed together, unresolved questions have no machine-checkable
marker, mini-feature dependencies are implicit, old ledgers have no schema
version, and an approved contract has no safe amendment procedure.

This makes brownfield adoption and automated enforcement weaker than the rest
of the template. The README also repeats details while underselling the four
supported hosts and the setup's adaptive behavior.

## Goal

Make the SDD artifacts explicit, traceable, versioned, amendable, and validated
with small standard-library tooling; document the resulting workflow in a
shorter, four-host-first README and a practical brownfield guide.

## Functional requirements

- **FR-001 — Separate requirements from success.** A spec has numbered
  functional requirements (`FR-###`) and technology-agnostic, measurable
  success criteria (`SC-###`) in separate sections.
- **FR-002 — Trace every scenario.** Every Given/When/Then scenario cites at
  least one `FR-###` and one `SC-###`.
- **FR-003 — Block ambiguity.** Unresolved decisions use exactly
  `NEEDS CLARIFICATION: <question>` on its own line; Gate 1 and `/feature`
  remain blocked while any such marker exists in the feature artifacts.
- **FR-004 — Standardize mini-features.** Every mini-feature declares `id`,
  `name`, `scenarios`, `depends_on`, `parallel`, `files_hint`, `max_files`,
  `max_loc`, `status`, and `verified_by_human`.
- **FR-005 — Enforce dependency order.** The orchestrator starts only a
  dependency-ready mini-feature and never treats `parallel` as permission to
  bypass a blocker or approval gate.
- **FR-006 — Version ledgers.** `features.json` uses `schema_version: 2`; a
  one-shot migration upgrades repository ledgers, and unknown versions fail
  with the exact migration command.
- **FR-007 — Amend signed contracts safely.** Post-approval changes are marked,
  affected work is reset, and Gate 1 must be approved again on disk.
- **FR-008 — Check principles twice.** PMO checks decomposition before Gate 1;
  judge checks the implementation against the same recorded deviation table.
- **FR-009 — Support existing projects.** A brownfield guide explains survey,
  merge, contract, and verification behavior without assuming a tracker or
  mandatory external companion.
- **FR-010 — Refresh the README and release.** README leads with Claude,
  Cursor, Grok, and Codex quick starts, explains the v0.9 grammar without
  duplicating deep docs, credits GitHub Spec Kit as inspiration, and release
  manifests move together to `0.9.0`.

## Success criteria

- **SC-001 — Traceability is mechanically complete.** Focused checks reject a
  new-contract scenario missing either an FR or SC reference; every declared
  scenario resolves to its ledger mini-feature.
- **SC-002 — Ambiguity cannot cross Gate 1.** A checked-in fixture containing a
  clarification marker makes validation and `/feature` guidance stop with the
  unresolved question listed.
- **SC-003 — Mini-feature state is deterministic.** Validation rejects missing
  schema fields, bad references, dependency cycles, and invalid statuses; the
  orchestrator selects only work whose dependencies are done.
- **SC-004 — Migration is safe and repeatable.** Migration of copies of every
  historical ledger yields valid schema v2 JSON, preserves IDs/order/status,
  and a second run produces no diff.
- **SC-005 — Amendments invalidate stale approval.** Tests cover the amendment
  marker, status resets, `progress/gate1.md` reapproval, and refusal to continue
  with stale approval.
- **SC-006 — Principles stay traceable.** A fixture with a justified deviation
  passes both PMO and judge checks; a missing deviation record fails.
- **SC-007 — Brownfield users can act from docs alone.** The guide covers
  non-destructive merge, source-of-truth conflicts, host selection, optional
  companions, tracker choice, and rollback.
- **SC-008 — README is faster to scan.** Its first 80 lines contain the value,
  four supported hosts, install paths, and first feature command; it has one
  canonical workflow diagram and one command table and does not grow beyond
  the pre-v0.9.0 253-line baseline.
- **SC-009 — Release checks are green.** Spec validation, build/check,
  packaging validation, smoke tests, double-build determinism, and the
  four-host render sweep pass; all three manifests report `0.9.0`.

## Decisions

- **D1 — Add grammar, not a generator framework.** Markdown stays human-readable
  and JSON stays hand-editable. A small Python stdlib validator enforces the
  contract; no YAML/schema dependency is added.
- **D2 — Dogfood schema v2 in this ledger.** This v0.9.0 plan uses the target
  shape before the migrator exists. MF2 accepts strict v2 plus legacy ledgers;
  MF3 migrates the legacy files and then makes a version mandatory.
- **D3 — IDs are stable; array order is presentation.** `depends_on` is the only
  execution dependency. `parallel` is a scheduling hint only; the default
  `one_at_a_time` rule and every human gate still win.
- **D4 — Migration does not invent architecture.** Existing `files` becomes
  `files_hint`; absent hints become `[]`; existing `after` becomes
  `depends_on`; otherwise the previous array item is the dependency when the
  ledger already required one-at-a-time execution. Historical completed items
  missing human-verification state become `skipped`.
- **D5 — Amendments are append-only evidence.** Use
  `*(Amended at <ISO date/time> — <reason>)*`. Affected `pending`/`spec_ready`
  items reset to `pending`; `in_progress`/`done` reset to `needs-rework`;
  `blocked` remains blocked until its blocker is reassessed. A new approval is
  appended to `progress/gate1.md`.
- **D6 — One principles record serves both gates.** `spec.md` Design notes hold
  a compact Principle / Decision / Reason / Mitigation table. “None” is an
  explicit valid result. Judge cites the same table rather than creating a
  second policy format.
- **D7 — README becomes a landing page.** Keep quick starts and the mental
  model; link to install/workflow/reference guides for depth and remove repeated
  agent/command prose.
- **D8 — Inspiration, not copying.** GitHub Spec Kit informs the separation of
  specification, planning, tasks, and convergence; this repository keeps its
  own artifacts, gates, wording, and implementation. Credit its MIT-licensed
  project in README.

## Out of scope

- v0.9.1 review convergence/verdict-axis work.
- v0.9.2 managed-file stamps, drift/prune behavior, and parser hardening.
- v1.0 eval harness, companion lifecycle manager, or additional host packages.
- A JSON Schema package, database, daemon, web UI, tracker requirement, or
  mandatory graphify/ponytail installation.
- Rewriting historical specs/contracts beyond the ledger migration needed for
  schema v2.

## Design notes

### Pattern ledger

- MF1: no pattern — extend the existing Markdown instructions and grep-style
  smoke checks.
- MF2: no pattern — one stdlib validator script with small pure checks; a class
  hierarchy or schema dependency has no present force.
- MF3: no pattern — one idempotent migration script over the fixed JSON shape.
- MF4: no pattern — append-only prose plus direct state transitions.
- MF5: no pattern — reuse the existing principles and judge surfaces.
- MF6: no pattern — documentation, version values, and existing release checks.

### Principles deviation table

| Principle | Decision | Reason | Mitigation |
|---|---|---|---|
| Micro-PR discipline | MF3 may touch every historical `features.json` in one migration commit. | Splitting one deterministic schema migration would create mixed live versions and a broken intermediate state. | Hand-authored scripts/docs stay within the normal budget; migrated JSON is mechanical, reviewed by idempotence and validation tests, and generated mirrors remain excluded. |

### Leverage

- **MF1:** reuse pmo, orchestrator, `/feature`, HELP, and smoke helpers; add only
  grammar text and assertions.
- **MF2:** reuse Python's `json`, `pathlib`, and graph traversal primitives;
  add no dependency or generalized schema engine.
- **MF3:** reuse the validator and historical ledgers as migration fixtures;
  write one one-shot transformer.
- **MF4:** reuse `features.json`, Gate 1, and progress artifacts; add no change
  log system.
- **MF5:** reuse the principles deviation table and current judge report.
- **MF6:** reuse existing install/workflow docs, build, packaging validator,
  smoke harness, and manifest skew check.

## Delivery

Implement the six mini-features in dependency order from `features.json`.
SDD+TDD Gate 2 applies per mini-feature. Judge reviews every slice; security
review is required for scripts that consume repository-controlled input. Stop
before each commit in gated mode. Push, publish, merge, and tags require a
separate explicit approval.
