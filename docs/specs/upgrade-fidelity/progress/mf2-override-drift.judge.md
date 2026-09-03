## Judge: override-drift (@s10..@s15)

**Stats:** 5 authored source/test files, 168 additions / 1 removal; two generated mirrors verified.
**Scenario → test:** @s10 → known override map ✓; @s11 → matching H2 quiet ✓; @s12 → missing H2 diagnostic ✓; @s13 → exact marker ✓; @s14 → malformed, broad, unmatched, and stale markers ✓; @s15 → no-write fixture plus normal/check build gate ✓.
**Principles table:** `None — No deviation`; the implementation is one stdlib checker at the existing build boundary.

## Spec fidelity
Result: pass

- No findings.

## Standards & health
Result: pass

- No findings. Focused and full smoke suites, syntax checks, generated-tree check, spec validation, packaging validation, and `git diff --check` pass.

## Verdict
APPROVED
