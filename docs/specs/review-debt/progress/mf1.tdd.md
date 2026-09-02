# MF1 TDD — hook-and-setup-bugs

## Red

`bash scripts/smoke.sh` exited 1 before production changes. New assertions failed
for CRLF/padded preference values, duplicate multi-host skip counts, bundle
recovery guidance, host-neutral protected-branch precedence, and stdin replay
guidance. Legacy protected-branch fallback and repository build guidance already
passed.

## Scenario → test

- @s1 → `scripts/smoke/mf1-output-style.sh` CRLF and padded preference cases
- @s2 → existing injection/parity cases in `mf1-output-style.sh`
- @s3 → stdin plan cases in `scripts/smoke/mf7-merge.sh`
- @s4–@s6 → setup count/layout cases in `scripts/smoke/v083-mf1-bugs.sh`
- @s7–@s8 → protected-variable precedence/fallback cases in the same file
- @s9 → full build, packaging, shell syntax, security regression, and smoke checks

## Gate 2

Approved under the maintainer’s 2026-09-02 instruction: “Go for everything.”
Production implementation may proceed without another pause this session.

## Green

The targeted MF1 harness passed after extending the existing hook pipelines,
setup staging set, layout hint, stdin note, and protected-variable fallback.
No new abstraction or dependency was introduced.

The full `bash scripts/smoke.sh` suite, generated-tree check, packaging
validation, rendered hook syntax checks, and `git diff --check` passed.
