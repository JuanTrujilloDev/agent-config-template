# Review Consolidation (v0.9.1) — Spec

2026-09-02 | branch: feature/v0.9.1-review-convergence | based on v0.9.0 | mode: SDD+TDD, gated

## Problem

The current review flow can inspect an empty or changing diff, blends objective
violations with reviewer preferences, and has no limit on fix/re-review loops.
Its TDD guidance also lacks explicit public seams, independently derived
expectations, and mock boundaries. These gaps make reviews less reproducible and
can turn judgment calls into blockers.

The existing `agent_style` handoff is centralized, but v0.9.1 must verify that
every review/development route actually carries it before adding repetitive
per-agent instructions.

## Goal

Make verification reproducible, verdicts unambiguous, review loops bounded, and
TDD harder to game while keeping the workflow short, host-portable, and free of
new runtime dependencies.

## Functional requirements

- **FR-001 — Pin verification scope.** `/verify` captures one immutable base
  SHA, validates it, and reuses it for the entire review.
- **FR-002 — Refuse empty reviews.** `/verify` stops before dispatch when its
  tracked and untracked scope is empty.
- **FR-003 — Locate the originating spec deterministically.** `/verify` checks
  changed spec paths, commit/branch references, then a single active ledger; if
  none is unambiguous, it says so and verifies against the request.
- **FR-004 — Separate verdict axes.** Judge reports `Spec fidelity` separately
  from `Standards & health`; findings never move between or get re-ranked across
  those axes.
- **FR-005 — Separate violations from preferences.** Every review finding is a
  `hard-violation` or `judgment-call`; judgment calls alone cannot block.
- **FR-006 — Use one machine-readable verdict.** Judge and security reviewer
  end with exactly one `APPROVED` or `CHANGES REQUESTED` verdict using the same
  blocking rule.
- **FR-007 — Reserve adversarial review for real risk.** It runs only for a
  diff over 200 changed lines or work involving auth/security, persistent data,
  concurrency, or architecture—not merely because a spec exists.
- **FR-008 — Bound review convergence.** Each mini-feature gets at most two
  completed fix/re-review cycles; unresolved required-review disagreement then
  becomes a human decision with both positions preserved.
- **FR-009 — Track cycles compatibly.** New ledgers initialize
  `review_cycles: 0`; schema v2 accepts an optional integer from 0 through 2 and
  treats an absent value in existing ledgers as 0.
- **FR-010 — Tighten TDD evidence.** Gate 2 names approved public seams and one
  failing vertical-slice test; expected values are independent, and mocks stop
  at external boundaries.
- **FR-011 — Preserve concise agent style.** Verify centralized `agent_style`
  propagation across all current subagent routes. Add a per-agent pointer only
  if a focused check proves the centralized handoff is insufficient.
- **FR-012 — Release consistently.** Credit conceptual inspiration without
  copying wording, document the upgrade, and move every active manifest to
  `0.9.1` together.

## Success criteria

- **SC-001 — Scope is reproducible.** Focused fixtures prove every diff/log
  command uses the captured SHA, bad refs fail, and empty scopes refuse review.
- **SC-002 — Spec discovery is predictable.** Fixtures cover each discovery
  tier, ambiguity, and the honest no-spec fallback.
- **SC-003 — Verdicts parse without interpretation.** Both reviewers expose the
  required headings, classifications, axis results, and one exact final verdict.
- **SC-004 — Preferences do not block delivery.** A judgment-call-only fixture
  approves; a hard violation requests changes on its own axis.
- **SC-005 — Adversarial review is proportional.** Threshold and risk-domain
  cases trigger it; an ordinary spec-backed small change does not.
- **SC-006 — Review loops terminate.** Tests cover cycle 0, two re-reviews,
  approval, cap exhaustion, escalation evidence, blocking, and reset behavior.
- **SC-007 — Old ledgers stay valid.** All repository schema v2 ledgers validate
  unchanged while new/out-of-range `review_cycles` cases behave as specified.
- **SC-008 — TDD evidence is behavioral.** Focused checks require named public
  seams, one red-to-green slice at a time, independent expectations, and only
  external-boundary mocks.
- **SC-009 — Output remains concise.** All review/development routes carry the
  selected `agent_style`, with no duplicated rule block added without evidence.
- **SC-010 — Release checks are green.** Spec validation, build/check,
  packaging validation, smoke, double-build determinism, four-host renders,
  shell syntax, JSON parsing, and placeholder checks pass; four manifests report
  `0.9.1`.

## Decisions

- **D1 — Pin data, not the worktree.** With no argument, `/verify` captures
  `HEAD` once and reviews changes after it, including staged, unstaged, and
  untracked files. With a ref, it validates the ref and captures its merge-base
  with `HEAD`. Later commands reuse that SHA while the worktree may still change.
- **D2 — Discovery is ordered and non-magical.** Prefer a changed
  `docs/specs/<slug>/` path, then a unique commit/branch reference, then exactly
  one active ledger. Ambiguity is reported; no tracker or guessed spec is added.
- **D3 — Axis results are explicit.** Each verdict axis reports
  `pass`, `fail`, or `not-applicable`. `CHANGES REQUESTED` requires at least one
  `hard-violation`; a judgment call is advice and remains on its originating
  axis. Security keeps severity labels but follows the same classification and
  final-verdict rule.
- **D4 — Initial review is cycle zero.** `review_cycles` counts completed
  fix-to-re-review loops. Increment immediately before a re-review. If a required
  reviewer still requests changes after cycle 2, mark the mini-feature blocked
  and write `progress/<mf>.review-escalation.md` with the unresolved finding,
  reviewer position, implementer position/evidence, and minimal human choices.
  Reset to 0 for a new mini-feature or a reapproved contract amendment.
- **D5 — Keep schema v2 compatible.** `review_cycles` is additive operational
  metadata. The validator checks it only when present; no migration, schema bump,
  or historical ledger rewrite is needed.
- **D6 — Put TDD policy in shared workflow surfaces.** Feature/orchestrator
  prompts pass the four guardrails to implementers. Do not duplicate the full
  rule block across twelve stack agents unless a focused propagation test fails.
- **D7 — Evidence controls per-agent style pointers.** Existing centralized
  `agent_style` propagation remains the default. v0.9.1 records the focused test
  result and adds local pointers only for proven gaps.
- **D8 — Borrow concepts, not artifacts.** Matt Pocock's public code-review and
  TDD material informs fixed-point review, two-axis reporting, public seams, and
  independent expectations. This project keeps original wording and behavior and
  credits the MIT-licensed source without implying affiliation.

## Out of scope

- A new review framework, daemon, dependency, `/code-review` command, or
  mandatory second model/CLI.
- Parallel reviewer orchestration or automatic code changes by review agents.
- Schema v3, migration of old ledgers, managed-file stamps, prune mode, or the
  v1.0 evaluation harness.
- Changes to optional companion policy or installation behavior.
- Replacing security severity levels; v0.9.1 only aligns classification and the
  final verdict.

## Design notes

### Pattern ledger

- MF1: no pattern — direct preflight and fixed Git arguments in the existing
  command; a review-session abstraction has no second consumer.
- MF2: no pattern — tighten the existing Markdown report contract.
- MF3: no pattern — extend the current mini-feature state machine with one
  bounded integer; do not add a workflow engine.
- MF4: no pattern — one shared instruction block distributed through existing
  feature/orchestrator prompts; do not create another TDD skill.
- MF5: no pattern — evidence, documentation, and synchronized metadata only.

### Principles deviation table

| Principle | Decision | Reason | Mitigation |
|---|---|---|---|
| None | No deviation. | Each mini-feature stays within the normal file and LOC budgets and reuses existing surfaces. | Build-generated mirrors remain excluded and every slice gets focused smoke coverage. |

### Leverage

- **MF1:** existing `/verify`, Git built-ins, spec ledgers, and shell smoke
  helpers.
- **MF2:** current judge/security agents and shared SDD report guidance.
- **MF3:** current orchestrator/PMO state transitions, `progress/`, and the
  schema v2 validator.
- **MF4:** current Gate 2, feature/orchestrator prompts, and shared SDD workflow
  surfaces.
- **MF5:** current `agent_style` handoffs, README credits, upgrade guide,
  manifest-skew validator, and release checks.

## Delivery

Implement the five mini-features in `features.json` dependency order. SDD+TDD
Gate 2 applies to every mini-feature. Judge reviews every slice; security review
is required when the changed surface executes shell/Git input or changes the
security-reviewer contract. Stop before each commit in gated mode. Push,
publish, merge, and tags require separate explicit approval.
