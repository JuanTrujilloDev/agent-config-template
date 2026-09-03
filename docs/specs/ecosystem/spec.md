# Ecosystem (v0.10.0) — Spec

2026-09-02 | branch: feature/v0.10.0-ecosystem | based on v0.9.2 | mode: SDD+TDD, gated

## Problem

Five important behavior promises are still manual-only, design guidance stops at
prose instead of reaching platform code, companion metadata is repeated across
host instructions without lifecycle checks, and Cursor's branch guard searches
words rather than parsing commands. Adding more static host copies now would
increase drift without evidence that they are needed.

## Goal

Make behavior measurable, UI branding consumable by code, companion installs
auditable, and the Cursor branch guard precise—while keeping model runs opt-in,
companions optional, output concise, and the existing spec schema stable.

## Functional requirements

- **FR-001 — Catalog model behaviors.** Add a checked JSONL catalog covering the
  five current `MANUAL` smoke scenarios plus one `/spec` to `/feature` workflow
  case, with fixtures, prompts, execution mode, and deterministic rubrics.
- **FR-002 — Support current host CLIs.** The runner detects Claude, Codex,
  Cursor, and Grok Build; constructs argv without a shell; applies timeouts; and
  reports unavailable binaries or authentication as explicit skips.
- **FR-003 — Keep live runs safe and opt-in.** Validation/listing never calls a
  model. Live execution requires `--run`; write-capable cases also require
  `--allow-writes`, run only in a disposable fixture copy, and never target the
  source repository.
- **FR-004 — Grade without another model.** Required/forbidden text, maximum
  response lines, file existence/content, and command status determine results.
  JSON results identify case, host, status, reason, and duration without secrets.
- **FR-005 — Integrate CI without surprise cost.** Ordinary CI validates the
  catalog and fake adapters only. Live evaluation is a manual workflow, accepts
  selected hosts/cases, skips missing credentials, and uploads sanitized results.
- **FR-006 — Add a machine-readable brand source.** UI projects receive
  `docs/design-system/tokens.json` for semantic color, typography, spacing,
  radius, shadow, and motion tokens. `MASTER.md` remains the human rationale and
  component guidance and points to the token source.
- **FR-007 — Generate one native token target.** `/design` selects the project's
  existing theme mechanism—CSS variables for web by default, Flutter theme data,
  Unity `ScriptableObject`, a native desktop theme facility, or JSON-only as a
  fallback—and records source/output SHA-256 values. It does not emit unused
  adapters.
- **FR-008 — Enforce brand-token use.** UI design and judge instructions require
  the native target to match the semantic source; stale hashes, raw duplicated
  brand values, or undocumented page-level token forks block completion.
- **FR-009 — Centralize companion metadata.** One committed lock manifest owns
  companion package/source, exact version, install method, executable checks,
  and a digest for direct-download artifacts. Generated host bundles consume the
  same data instead of duplicating pins.
- **FR-010 — Add companion lifecycle actions.** The companion workflow supports
  offline `plan` and `doctor`, plus confirmed `install`, `update`, and `uninstall`.
  Actions are idempotent, never auto-update, and preserve the optional companion
  policy.
- **FR-011 — Parse branch commands.** Replace the Cursor hook's word scan with a
  Python-stdlib tokenizer that recognizes actual `git commit`/`git push`
  invocations, path-qualified git, and supported shell `-c` wrappers while
  allowing harmless literal mentions.
- **FR-012 — Release consistently.** Documentation and all active manifests move
  to `0.10.0`; spec, build, packaging, smoke, deterministic rebuild, shell/JSON,
  and all 24 example/host renders pass.

## Success criteria

- **SC-001 — Catalog coverage is exact.** Validation proves the five legacy
  manual behaviors and at least one workflow case exist; malformed IDs, fixtures,
  modes, or rubrics fail clearly.
- **SC-002 — Adapters are deterministic.** Fake executables prove each host argv,
  timeout, success, skip, non-zero exit, and malformed-output path without network
  access or paid calls.
- **SC-003 — Default execution is inert.** Listing, validation, ordinary smoke,
  and normal CI invoke no host CLI. Live writes cannot run without both explicit
  flags and a disposable workspace.
- **SC-004 — Rubrics are reproducible.** The same captured response/workspace
  produces the same pass/fail result, including terse-output and prose-artifact
  checks, without an LLM judge.
- **SC-005 — CI is credential-safe.** Manual live jobs skip absent credentials,
  do not print secret values or inherited environment dumps, and publish only
  sanitized machine-readable results.
- **SC-006 — Tokens render only for UI.** Fresh UI renders include valid semantic
  token JSON with no placeholders; non-UI renders do not receive the design-system
  surface.
- **SC-007 — Native branding stays synchronized.** Fixtures prove `/design`
  selects one relevant target, hashes its source/output, and the judge detects a
  missing, stale, or raw-value-divergent target.
- **SC-008 — Companion state is explainable.** Plan/doctor work offline; fixture
  installs prove pin/digest use, idempotence, update reporting, and confirmation
  immediately before install/update/uninstall mutations.
- **SC-009 — Branch blocking is precise.** Protected branches block direct,
  path-qualified, and supported wrapped commit/push commands while allowing
  quoted prose, `echo`, grep patterns, and ordinary git reads.
- **SC-010 — Release checks are green.** All validators and smoke tests pass,
  two builds are byte-identical, 24 renders are placeholder-free, and four
  manifests report `0.10.0`.

## Decisions

- **D1 — Deterministic rubrics, not a judge model.** The first harness measures
  explicit contract outcomes. A second model would add cost and nondeterminism
  before the cases themselves are trustworthy.
- **D2 — Table-driven CLI adapters.** Four real command/output protocols justify
  one small adapter table and narrow parsers; reject class hierarchies and every
  use of `shell=True`.
- **D3 — Live and write are separate gates.** `--run` authorizes paid/read-only
  evaluation; `--allow-writes` separately authorizes a disposable workspace.
  Original repositories and working trees remain out of scope.
- **D4 — Keep `verified_by_human`.** Automated model results live in separate
  result JSON. Renaming the ledger field would force a schema migration while
  making its human meaning less accurate.
- **D5 — Semantic JSON is the value source.** `MASTER.md` explains intent and
  usage; `tokens.json` owns reusable values. Native output records both hashes
  so synchronization is checkable without a design compiler.
- **D6 — Emit only the native adapter in use.** Prefer the project's current
  theme facility and CSS variables for ordinary web projects. Do not install a
  Tailwind version or generate Flutter/Unity files in unrelated projects.
- **D7 — Companions stay optional.** The lock improves repeatability but does not
  make Ponytail, graphify, or UI UX Pro Max mandatory. Network and destructive
  lifecycle actions retain explicit confirmation gates.
- **D8 — Checksums fit the distribution method.** Exact package versions protect
  package-manager installs; SHA-256 is additionally required for direct-download
  files. Do not invent unverifiable checksums for registries.
- **D9 — No new static host packages.** OpenCode, Gemini, Windsurf, and future
  hosts continue through `port-config` until observed demand justifies permanent
  generated trees and tests.
- **D10 — The branch hook is a guardrail.** Parse known command forms and fail
  open on malformed/non-git text. Protected-branch policy and server-side checks
  remain the security boundary.

## Out of scope

- Leaderboards, statistical model comparisons, an LLM-as-judge, or automatic
  paid evaluation on pushes and pull requests.
- Running write-capable evals against a user's real repository or silently
  enabling approval-bypass flags.
- Renaming `verified_by_human`, migrating historical ledgers, or adding another
  specification schema version.
- A general design compiler, arbitrary prose parsing, every CSS framework, or
  generating every platform adapter into each project.
- Mandatory companions, silent installs/updates, telemetry, or embedding Caveman
  as another runtime dependency.
- Permanent packages for additional hosts without usage evidence.
- Treating the local Cursor hook as a substitute for protected branches or
  remote repository policy.

## Design notes

### Pattern ledger

- MF1: table-driven Adapter — four existing CLIs expose different argv and output
  shapes; rejected subprocess shell strings and a class hierarchy.
- MF2: no pattern — one semantic JSON contract plus the existing design/judge
  workflow is sufficient.
- MF3: manifest pattern — three host surfaces need one source of companion pins;
  rejected repeated versions inside Markdown instructions.
- MF4: no pattern — tokenize at the existing hook boundary with stdlib `shlex`.
- MF5: no pattern — synchronize current release metadata and documentation.

### Principles deviation table

| Principle | Decision | Reason | Mitigation |
|---|---|---|---|
| None | No deviation. | Each slice replaces a known manual or duplicated seam. | Stdlib-first implementation, explicit mutation gates, focused fixtures, and no extra host trees. |

### Leverage

- **MF1:** existing `MANUAL` scenario IDs, JSONL/stdlib tooling, host render
  fixtures, and GitHub Actions manual dispatch.
- **MF2:** current `MASTER.md`, `/design`, UI designer, frontend guidance, judge,
  `requires: has_ui`, and SHA-256 tooling already used by setup.
- **MF3:** current `/setup-companions`, package/version probes, plugin build,
  confirmation language, and packaging validation.
- **MF4:** current Cursor hook, JSON payload extraction, protected-branch lookup,
  Python stdlib, and focused hook smoke fixtures.
- **MF5:** current manifest parity validator, README, upgrade guide, deterministic
  build, and 24-render release matrix.

### Current CLI evidence

- Cursor documents headless `cursor-agent -p`, JSON output, model selection, and
  API-key authentication: <https://docs.cursor.com/en/cli/headless> and
  <https://docs.cursor.com/en/cli/reference/parameters>.
- xAI documents Grok Build headless `grok -p`, JSON output, `--no-auto-update`,
  sandboxing, and API-key authentication: <https://docs.x.ai/build/cli/headless-scripting>
  and <https://docs.x.ai/build/cli/reference>.
- Installed Claude and Codex CLI help confirms `claude -p` and `codex exec` on
  the development machine. Model identifiers stay configurable because they are
  not a stable template contract.

## Delivery

Implement the five mini-features in dependency order. SDD+TDD Gate 2 applies to
each slice. Judge reviews every slice; security review is also required for MF1,
MF3, and MF4 because they execute external processes, install/remove tools, or
interpret shell input. Stop before every commit. Push, release, merge, tag, and
marketplace actions require separate explicit approval.
