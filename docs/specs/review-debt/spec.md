# Review Debt (v0.8.3) — Spec

2026-09-02 | branch: feature/v0.8.3-review-debt | based on v0.8.2 | mode: SDD+TDD, gated

## Problem

The v0.8.0–v0.8.2 reviews left four observable setup/hook bugs and a small set
of documentation, instruction, validation, fixture, and companion-version
debts. None requires a new workflow or abstraction, but leaving them open makes
the generated hosts disagree, produces misleading recovery instructions, and
keeps one real-project check outside the automated suite.

The four behavior bugs are:

1. CRLF or padded values in `.claude/answers.local.env` miss the banner
   whitelist.
2. A merge plan created from stdin prints a non-replayable `--answers -`
   command without explaining that stdin must be supplied again.
3. Multi-host renders count the same skipped target path more than once.
4. Missing generated host trees in an installed plugin tell the user to run a
   repository-only build command.

## Goal

Close the v0.8.x review debt with the smallest compatible fixes: normalize
whitelisted preferences, make setup output accurate and replayable, align
protected-branch variables, update user-facing docs/instructions, strengthen
packaging validation and fixtures, pin the optional UI companion, and release
v0.8.3.

## Success criteria

1. CRLF/padded preference values produce the same fixed banner as clean values;
   arbitrary file content is never echoed.
2. Setup plans are truthful for stdin, count unique skipped paths, and give the
   correct repository-vs-plugin recovery instruction.
3. `AGENT_CONFIG_PROTECTED_BRANCHES` is primary across branch guards, with the
   legacy `CLAUDE_CONFIG_PROTECTED_BRANCHES` fallback preserved.
4. The README, file map, host docs, capability matrix, Cursor guide, and Cursor
   AGENTS pointer describe the v0.8.2 surfaces accurately.
5. Instruction text is chronological and unambiguous about TDD and the three
   meanings of “just go”; UI brand guidance includes mobile/game TODO hints.
6. Packaging validation rejects generated command descriptions containing an
   unescaped inner double quote with and without PyYAML; the stale-render check
   uses only a checked-in fixture.
7. ui-ux-pro-max defaults to the exact `2.15.0` CLI pin, all three manifests
   report `0.8.3`, and the upgrade guide documents the patch.
8. Build/check, packaging validation, smoke tests, double-build determinism,
   and the four-host render sweep pass.

## Decisions

- **D1 — Normalize before the whitelist, never after output selection.** Trim
  carriage returns and surrounding horizontal whitespace from the first
  `autonomy_mode`/`output_style` value, then run the existing `case` over known
  tokens. Output remains selected from fixed strings. This accepts ordinary
  Windows/editor formatting without turning preferences into executable text.
- **D2 — Stdin plans must explain replay.** When answers came from `-`, keep the
  literal `--answers -` and print one short note that the user must pipe the
  same answers again. File-backed plans keep the current copy-paste command.
  This is more honest than inventing a path.
- **D3 — Counts are target-path counts.** Deduplicate staged relative paths
  before reporting `skipped N files`; selected hosts may traverse the same
  source, but the user sees one destination file.
- **D4 — Recovery follows the running layout.** A repository checkout that is
  missing generated host trees says to run `scripts/build.sh`; an installed
  bundle, which has no repository `scripts/`, says to reinstall/update the
  plugin. Detection uses files/directories already resolved by `setup.sh`.
- **D5 — Host-neutral protected-branch key is primary.** Read
  `AGENT_CONFIG_PROTECTED_BRANCHES`, fall back to
  `CLAUDE_CONFIG_PROTECTED_BRANCHES`, then the rendered defaults. Keep parsing,
  symlink containment, and fail-safe behavior unchanged.
- **D6 — Documentation and instruction changes are corrections, not new
  workflows.** SDD+TDD, Gate 1/Gate 2, autonomy, companions, `/integrate`, and
  generated-tree rules remain as ratified in v0.8.0–v0.8.2.
- **D7 — Validate the generated YAML boundary.** The stdlib fallback rejects a
  command `description:` whose outer double quotes contain an unescaped inner
  double quote; the PyYAML path must reach the same verdict. No new dependency
  is added.
- **D8 — Pin reproducibility, document escape hatch.** Companion setup prints
  `npm install -g ui-ux-pro-max-cli@2.15.0` by default and states how to install
  an unpinned/latest version deliberately. It remains optional and `has_ui`
  only.
- **D9 — Preserve the five-MF release plan.** MF3 and MF4 exceed the normal
  12-file review budget because direct plugin components are hand-authored and
  the checked-in stale fixture is four physical files. Their ledgers enumerate
  every source file and record the exception; generated mirrors remain excluded.

## Out of scope

- New hosts, workflows, commands, agents, or setup questions.
- Default-on or mandatory companions; Caveman installation; Plane or another
  tracker requirement; setup-time registry crawling.
- RPI, `/onboard`, `/ship-check`, standards-reviewer, per-task autonomy prompts,
  or changes to the existing confirmation gates.
- v0.9.0+ work: FR/SC grammar, schema versioning, contract amendments, verdict
  axes, convergence caps, managed-file stamps, prune mode, or eval harnesses.
- Editing the portfolio fixture or relying on it in automated tests.

## Design notes

### Pattern ledger

- MF1: no pattern — extend existing parsing, classification, and counting call
  sites; a new parser/Strategy would add indirection without a second behavior.
- MF2: no pattern — static documentation corrections only.
- MF3: no pattern — reorder and clarify existing instruction text only.
- MF4: no pattern — strengthen the existing validator/helpers and replace an
  external manual check with a small checked-in fixture.
- MF5: no pattern — fixed dependency pin, manifest values, and upgrade prose.

### Leverage

- **MF1:** reuse the hooks’ current `sed` + `case` whitelist, setup’s staged
  path set, existing layout detection, and current smoke helpers. New code is
  limited to normalization, deduplication, and one layout-specific hint.
- **MF2:** extend the existing README/file map/install docs and use grep-based
  smoke assertions; no new documentation system.
- **MF3:** move/split/condition existing Markdown and reuse Mustache sections,
  `before`, and `grep_case`; no new instruction layer.
- **MF4:** reuse `parse_frontmatter`, the smoke fixture pattern, Python stdlib,
  and the shared `agent_style` instruction. No YAML dependency or test framework.
- **MF5:** update the existing companion plan, three version manifests, and one
  upgrade-guide section; no lockfile before v1.0 companion hardening.

## Delivery

Implement one mini-feature at a time in `features.json`. Under SDD+TDD, each MF
stops at Gate 2 after its failing tests. After implementation, run judge review
and security review for MF1 and any later change that reads external input.
Stop before every commit in gated mode. Never push, publish, or open a PR
without explicit approval.
