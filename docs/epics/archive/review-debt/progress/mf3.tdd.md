# MF3 TDD — instruction-text-debt

## Scenario → test

- @s15–@s16 → pmo ordering and `/fix` paragraph assertions
- @s17 → SDD+TDD and SDD render assertions for `/feature` and CLAUDE.md
- @s18 → three-meaning “just go” assertions in both principles surfaces
- @s19–@s21 → setup-template wording and safety assertions
- @s22 → mobile/game responsive TODO assertions
- @s23 → conditional-source and core/plugin parity assertions

## Gate 2

Approved under the maintainer’s 2026-09-02 instruction: “Go for everything.”

## Red

`v083-mf3-instructions.sh` failed all new @s15–@s23 assertions before the source edits.

## Green

The focused MF3 smoke and full smoke suite pass. Generated-tree drift,
packaging validation, and `git diff --check` also pass.
