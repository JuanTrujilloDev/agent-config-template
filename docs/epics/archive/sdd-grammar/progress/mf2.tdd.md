## TDD: mini-feature-grammar (@s7..@s13)

### Scenario → check

- @s7/@s8 → strict v2 fixtures cover required fields, types, values, scenario
  references, names, IDs, dependencies, cycles, and limits.
- @s9/@s10 → orchestrator source/plugin require dependency readiness and define
  `parallel` as a non-gating hint.
- @s11 → PMO source/plugin define the four tracer-bullet properties.
- @s12 → an unversioned historical-shape fixture remains valid during MF2.
- @s13 → default validation covers repository ledgers and CI runs it.

### Red

Focused smoke → exit 1 before implementation: `validate-specs.py` was absent and
the PMO/orchestrator/CI surfaces lacked the new grammar.

### Green

`bash scripts/smoke.sh` → exit 0. Strict v2, legacy compatibility, malformed
types, dependency errors, instruction parity, repository validation, and CI
registration all pass.

### Refactor

Kept validation in one 226-line Python stdlib script. Review added one malformed
type fixture and hardened list/set membership; no package or schema framework.
