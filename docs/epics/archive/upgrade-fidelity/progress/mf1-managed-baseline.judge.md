## Judge: managed-baseline (@s1..@s9)

**Stats:** 5 authored source/test files, 291 additions / 8 removals; one generated setup mirror verified.
**Scenario → test:** @s1 → fresh schema/determinism ✓; @s2 → stale baseline ✓;
@s3 → customized baseline/suggestion exclusion ✓; @s4 → legacy classification ✓;
@s5 → managed exclusions/symlink refusal ✓; @s6 → preserve/advance baseline ✓;
@s7 → missing state ✓; @s8 → malformed/schema/path/hash/namespace state ✓;
@s9 → four hosts/bundled setup/full smoke ✓.

## Spec fidelity

Result: pass

- No findings. The lock-file pattern matches the approved force and every MF1
  behavior traces to `@s1`–`@s9`.

## Standards & health

Result: pass

- No findings. The `None` principles-deviation row remains accurate: stdlib
  only, no speculative abstraction, five authored implementation/test files,
  typed branch, deterministic build, and full regression suite green.

## Verdict

APPROVED

## Security review

**Stack:** Bash 3.2 + Python stdlib · **Found:** 0 critical · 0 serious ·
0 moderate · 0 dependency CVEs

Validated malformed JSON, unsupported schemas, absolute/traversing/unmanaged
paths, invalid hashes, state-file symlinks, target containment, and preview
no-write behavior. Lock replacement is atomic.

APPROVED
