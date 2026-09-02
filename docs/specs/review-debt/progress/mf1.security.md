# Security review: MF1 hook-and-setup-bugs

## Scope

Preference-file parsing, protected-branch environment variables, setup source
layout errors, merge-plan output, skipped-path accounting, and regression tests.

## Findings

No security findings.

- Preference values are normalized, then accepted only by the existing literal
  whitelist; file content is never evaluated or interpolated into output.
- The host-neutral protected-branch variable is data-only and retains the
  legacy fallback and exact membership test.
- The stdin note adds no replay/evaluation behavior. Existing plan arguments
  remain shell-quoted with `shlex.quote`.
- Deduplication stores target-relative path strings only. It does not change
  staging, collision detection, write selection, or symlink containment.
- Full smoke coverage confirms external and intermediate symlinks remain
  rejected before writes.

## Verdict

APPROVED.
