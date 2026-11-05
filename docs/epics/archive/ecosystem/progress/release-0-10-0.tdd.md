# TDD: release-0-10-0 (@s29..@s33)

## Public seams

- Four plugin manifests report `0.10.0`.
- README/plugin README and upgrade guide describe all four new capabilities.
- Release gates include deterministic build, 24 renders, and inert eval validation.

## Scenario to test

- @s29–@s30: version parity and concise migration documentation.
- @s31: spec/build/package/shell/JSON gates.
- @s32: double-build and 24 placeholder-free renders.
- @s33: no model call during validation and five completed mini-features.

## Red

`scripts/smoke/v010-mf5-release.sh` exited 1 on 2026-09-02. All four manifests
were still `0.9.2`, release documentation was absent, packaging reported v0.9.2,
and MF5 remained in progress. Static gates, deterministic builds, all 24 renders,
and inert catalog validation already passed.

## Green

All four manifests now report `0.10.0`. The README, plugin README, and upgrade
guide cover the release boundaries; the full smoke suite, packaging, specs,
build check, shell/JSON validation, deterministic rebuild, and all 24 renders pass.

## Refactor

Kept the README at 232 lines and made the historical v0.9.2 release smoke assert
a semantic current version instead of freezing later releases at `0.9.2`.
