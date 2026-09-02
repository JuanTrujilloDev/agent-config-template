# MF4 TDD — build-test-hygiene

## Scenario → test

- @s24 → scoped-local and Bash syntax assertions
- @s25–@s26 → valid/invalid description checks with PyYAML and `python3 -S`
- @s27 → `first_line` implementation and `before` behavior assertions
- @s28 → exact fixture inventory, plan labels, and no portfolio dependency
- @s29 → adaptive-skills MF8 ledger parse/assertion
- @s30 → six command-surface `agent_style` assertions
- @s31 → standard and determinism checks after implementation

## Gate 2

Approved under the maintainer’s 2026-09-02 instruction: “Go for everything.”

## Red

The focused MF4 smoke failed on missing scoped locals, stdlib inner-quote
validation, the dead `first_line` pipe, the absent fixture/ledger entry, and all
six command handoff instructions. PyYAML already rejected the seed but its
generic parse error did not identify `description`.

## Green

The focused and full smoke suites pass. Packaging passes with PyYAML and with
`python3 -S`; double-build output is byte-identical; build drift, JSON, and diff
checks pass.
