# TDD: companion-lifecycle (@s16..@s22)

## Public seams

- `plugin/companions.lock.json` is the only companion metadata source.
- `/setup-companions <plan|doctor|install|update|uninstall> [list]`.
- Packaging validation rejects invalid pins, digests, or generated drift.

## Scenario to test

- @s16–@s17: lock schema, sorted tools, source/probe/version, generated parity.
- @s18–@s21: offline status, mutation gates, digest-before-replace, narrow removal.
- @s22: packaging mutation test and user guide.

## Red

`scripts/smoke/v010-mf3-companions.sh` exited 1 on 2026-09-02 because the lock,
lifecycle actions, generated lock copy, validation, and guide entry did not
exist. The old install-only plan checks remained green.

## Green

Focused smoke passes @s16–@s22: schema/pins, generated lock parity, five
lifecycle actions, offline status vocabulary, immediate mutation gates,
digest-before-replace, narrow removal, guide text, and a seeded invalid-pin
failure.

## Refactor

Kept execution agent-native. One JSON lock plus packaging validation replaces a
new installer framework; host-specific commands stay in the existing command and
Codex override.
