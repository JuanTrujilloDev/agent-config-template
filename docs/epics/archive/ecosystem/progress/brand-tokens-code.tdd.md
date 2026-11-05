# TDD: brand-tokens-code (@s9..@s15)

## Public seams

- UI render: `docs/design-system/tokens.json` beside `MASTER.md`.
- `/design`: one native adapter plus `tokens.lock.json` synchronization record.
- Judge: token/hash/raw-value checks are blocking.

## Scenario to test

- @s9–@s10: UI-only, valid semantic JSON and MASTER linkage.
- @s11–@s12: adapter routing and portable SHA-256 record.
- @s13–@s14: stale/native drift and raw brand forks block judge.
- @s15: generated host parity and merge preservation.

## Red

`scripts/smoke/v010-mf2-brand-tokens.sh` exited 1 on 2026-09-02: no rendered
`tokens.json`, adapter/hash instructions, judge checks, or generated host copies
existed. The existing no-UI exclusion and merge preservation already passed.

## Green

Focused smoke passes @s9–@s15: capability-gated JSON, six semantic groups,
MASTER linkage, five adapter routes, portable hash fields, blocking judge rules,
generated host parity, and merge preservation.

## Refactor

Kept generation agent-driven and stack-native. No parser, framework dependency,
or unused adapter files were added.
