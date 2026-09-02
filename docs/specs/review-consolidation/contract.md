# Review Consolidation (v0.9.1) — Contract

Gate 1 status: **approved by the maintainer on 2026-09-02** (“Yes”).
Workflow: SDD+TDD, gated.

## MF1 — verify-preflight (@s1..@s7)

Design notes: no pattern — direct preflight in the existing command. Leverage:
Git built-ins, current spec ledgers, and shell smoke helpers. Security review is
required because the command resolves user-supplied Git refs and paths.

- **@s1 [FR-001, SC-001]** Given `/verify` has no explicit ref, When preflight
  begins, Then it captures `HEAD` once as an immutable SHA and every later
  tracked-diff/log command uses that SHA while staged and unstaged changes remain
  in scope.
- **@s2 [FR-001, SC-001]** Given a valid explicit ref, When preflight begins,
  Then it captures that ref's merge-base with `HEAD` once and reuses the full SHA
  for the review.
- **@s3 [FR-001, SC-001]** Given an invalid or unresolved explicit ref, When
  preflight runs, Then it refuses before reviewer dispatch with a concise error.
- **@s4 [FR-002, SC-001]** Given no tracked changes after the pinned base and no
  untracked files, When `/verify` runs, Then it refuses with `Nothing to verify.`
- **@s5 [FR-001, FR-002, SC-001]** Given untracked files exist, When scope is
  computed, Then their paths are listed explicitly and they prevent a false
  empty-scope refusal without being interpolated as commands.
- **@s6 [FR-003, SC-002]** Given possible originating specs, When discovery
  runs, Then it chooses the first unique match in this order: changed spec path,
  commit/branch reference, single active ledger; ambiguous tiers are reported.
- **@s7 [FR-003, SC-002, SC-010]** Given no unique spec is found, Then `/verify`
  states that it will use the user request, does not invent a tracker/spec, and
  focused source/generated parity and smoke checks pass.

## MF2 — two-axis-verdicts (@s8..@s16)

Design notes: no pattern — one report contract. Leverage: current judge,
security-reviewer, SDD workflow, and grep-style assertions.

- **@s8 [FR-004, SC-003]** Given judge reports, Then they contain exactly
  `## Spec fidelity` and `## Standards & health`, each with
  `Result: pass|fail|not-applicable`.
- **@s9 [FR-004, FR-005, SC-003, SC-004]** Given a finding, Then it remains on
  its originating axis and is labeled `hard-violation` or `judgment-call`; the
  judge never merges or cross-ranks the axes.
- **@s10 [FR-005, FR-006, SC-003, SC-004]** Given only judgment calls, When the
  judge or security reviewer concludes, Then the exact final verdict is
  `APPROVED`.
- **@s11 [FR-005, FR-006, SC-003, SC-004]** Given at least one hard violation,
  When either reviewer concludes, Then the exact final verdict is
  `CHANGES REQUESTED` and the violation's axis remains failed.
- **@s12 [FR-006, SC-003]** Given a security review, Then it retains severity
  sections but uses the shared finding classification and ends with one exact
  `## Verdict` value.
- **@s13 [FR-007, SC-005]** Given a diff over 200 changed lines, Then judge adds
  adversarial review findings to the appropriate existing axis.
- **@s14 [FR-007, SC-005]** Given auth/security, persistent-data, concurrency,
  or architecture work, Then adversarial review runs regardless of diff size.
- **@s15 [FR-007, SC-005]** Given a small ordinary change that originated from
  a spec, Then spec origin alone does not trigger adversarial review.
- **@s16 [FR-004, FR-005, FR-006, FR-007, SC-003, SC-004, SC-005, SC-010]**
  Given MF2 is rendered, Then Claude/plugin/Cursor/Codex guidance agrees and
  focused smoke checks parse both reviewer verdicts without inference.

## MF3 — bounded-review-convergence (@s17..@s25)

Design notes: no pattern — one bounded counter on the existing state machine.
Leverage: orchestrator/PMO transitions, `progress/`, schema v2 validation, and
current amendment rules.

- **@s17 [FR-008, FR-009, SC-006, SC-007]** Given a new mini-feature ledger,
  Then `review_cycles` starts at `0`; a missing value in an existing schema v2
  ledger is read as 0.
- **@s18 [FR-009, SC-007]** Given validation sees `review_cycles`, Then only an
  integer from 0 through 2 passes; booleans, strings, negatives, and values over
  2 fail without invalidating historical ledgers that omit it.
- **@s19 [FR-008, SC-006]** Given a required reviewer requests changes at cycle
  0 or 1, Then the orchestrator routes the findings to the implementer,
  increments immediately before re-review, and records the new value.
- **@s20 [FR-006, FR-008, SC-003, SC-006]** Given judge is required and
  security review is conditionally required, Then the mini-feature advances only
  when every required reviewer returns exact `APPROVED`.
- **@s21 [FR-008, SC-006]** Given a required reviewer still returns
  `CHANGES REQUESTED` after cycle 2, Then no third fix/re-review cycle starts.
- **@s22 [FR-008, SC-006]** Given the cap is exhausted, Then the mini-feature is
  marked `blocked` and `progress/<mf>.review-escalation.md` records the finding,
  reviewer position, implementer position/evidence, and minimal human choices.
- **@s23 [FR-008, SC-006]** Given an escalation exists, Then the workflow asks
  for a human decision and does not silently select either position.
- **@s24 [FR-008, FR-009, SC-006, SC-007]** Given a new mini-feature starts or
  an amended contract is reapproved, Then its applicable counter is reset to 0.
- **@s25 [FR-008, FR-009, SC-006, SC-007, SC-010]** Given MF3 is rendered,
  Then state/counter/escalation fixtures, schema validation, host parity, and
  focused smoke checks pass.

## MF4 — tdd-quality-guardrails (@s26..@s33)

Design notes: no pattern — shared workflow guidance passed through existing
feature/orchestrator prompts. Leverage: Gate 2 and current implementer dispatch.

- **@s26 [FR-010, SC-008]** Given TDD applies, When Gate 2 evidence is prepared,
  Then it names the public behavior seams before writing tests.
- **@s27 [FR-010, SC-008]** Given a proposed first test, Then Gate 2 approves
  both its public seam and its observed failing output before implementation.
- **@s28 [FR-010, SC-008]** Given a seam was not agreed, Then tests do not bind
  to it merely because an internal function is convenient.
- **@s29 [FR-010, SC-008]** Given an expected value, Then it comes from the
  contract, a literal/worked example, or an independent oracle—not the same
  algorithm as production code.
- **@s30 [FR-010, SC-008]** Given test doubles are needed, Then only external
  boundaries are mocked; project-owned implementation modules stay real.
- **@s31 [FR-010, SC-008]** Given multiple contract behaviors, Then development
  repeats one test → failing evidence → minimal green implementation before
  starting the next test; it does not batch all tests before all code.
- **@s32 [FR-010, FR-011, SC-008, SC-009]** Given an implementer is dispatched
  from any feature route, Then the prompt carries the guardrails and selected
  `agent_style` without duplicating the full policy in every stack agent.
- **@s33 [FR-010, SC-008, SC-010]** Given MF4 is rendered for every host, Then
  shared-workflow, feature-prompt, Gate 2, and focused smoke assertions pass.

## MF5 — agent-style-and-release (@s34..@s40)

Design notes: no pattern — evidence, docs, and release metadata. Leverage:
existing prompt routes, README credits, upgrade guide, manifest validation, and
release checks.

- **@s34 [FR-011, SC-009]** Given every current command that dispatches a
  subagent, Then a focused check proves it reads `agent_style` with terse
  fallback and passes the standard report-format instruction.
- **@s35 [FR-011, SC-009]** Given centralized propagation passes @s34, Then no
  repetitive per-agent `agent_style` pointer is added and the evidence is noted
  in the v0.9.1 upgrade guide.
- **@s36 [FR-011, SC-009]** Given centralized propagation fails for a route,
  Then only the proven gap receives the smallest local pointer and focused test.
- **@s37 [FR-012, SC-010]** Given README credits, Then they acknowledge Matt
  Pocock's MIT-licensed review/TDD concepts, state that wording and artifacts
  are original, and do not imply affiliation.
- **@s38 [FR-012, SC-010]** Given active plugin manifests, Then Claude plugin,
  Claude marketplace, Cursor plugin, and Codex plugin versions all equal
  `0.9.1` and packaging validation reports no skew.
- **@s39 [FR-012, SC-010]** Given `docs/upgrade-guide.md`, Then its v0.9.1
  section concisely explains pinned review scope, verdict axes, the two-cycle
  cap, TDD guardrails, compatibility, and the upgrade path.
- **@s40 [FR-012, SC-010]** Given the release candidate, Then spec validation,
  build/check, packaging validation, smoke, double-build determinism, four-host
  render sweep, shell syntax, JSON parse, and zero-placeholder checks all pass.
