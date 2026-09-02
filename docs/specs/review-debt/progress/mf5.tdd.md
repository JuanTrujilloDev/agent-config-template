# MF5 TDD — companion-pin-and-release

## Scenario → test

- @s32–@s34 → exact Claude/Codex pin, plan, source, location, optionality,
  unpinned alternative, detection, and confirmation assertions
- @s35 → three-manifest version and validator-output assertions
- @s36 → upgrade-guide content plus every-example/four-host render, placeholder,
  shell-syntax, and JSON checks

## Gate 2

Approved under the maintainer’s 2026-09-02 instruction: “Go for everything.”

## Red

The focused MF5 smoke failed on the absent exact pins/unpinned guidance, all
three `0.8.3` versions, validator output, and the missing upgrade section. The
every-example/four-host render, shell, JSON, and placeholder sweep was already
green.

## Green

The focused and full smoke suites pass. All 24 example/host renders are clean;
the manifests validate at v0.8.3; double-build, packaging, shell, JSON,
placeholder, and diff checks pass.
