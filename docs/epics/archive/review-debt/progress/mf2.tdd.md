# MF2 TDD — docs-catch-up

## Scenario → test

- @s10 → file-map term assertions in `scripts/smoke/mf-docs.sh`
- @s11 → README surface and optional-companion assertions
- @s12 → capability-matrix row assertions
- @s13 → Cursor stack-dependent skill wording assertions
- @s14 → Cursor AGENTS native-skill pointer assertions

## Gate 2

Approved under the maintainer’s 2026-09-02 instruction: “Go for everything.”

## Red

The focused docs smoke exited 1: every new file-map/README term, both capability
rows, the Cursor stack-dependent wording, and the AGENTS skill pointer were
absent. The existing README already passed the optional-companion assertion.

## Green

The focused docs smoke passes after updating only the existing reference,
README, capability matrix, Cursor guide, and Cursor AGENTS source.

The full smoke suite, generated-tree check, packaging validation, and
`git diff --check` pass.
