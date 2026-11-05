## TDD: contract-grammar (@s1..@s6)

### Scenario → check

- @s1 → PMO source/plugin require separate `Functional requirements` (`FR-###`)
  and `Success criteria` (`SC-###`) sections.
- @s2 → PMO source/plugin require every scenario to cite FR + SC.
- @s3 → PMO source/plugin define the exact clarification marker and list it
  before Gate 1.
- @s4 → orchestrator and `/feature`, source/plugin, scan markers, print the
  unresolved questions, and refuse implementation.
- @s5 → HELP contains a minimal FR/SC spec and traced scenario example.
- @s6 → workflow docs carry equivalent grammar; source/plugin parity and build
  drift checks pass.

### Red

`bash scripts/smoke.sh` → exit 1 on 2026-09-02.

All pre-v0.9.0 checks passed. The new MF1 assertions failed because the current
PMO, orchestrator, `/feature`, HELP, and SDD workflow surfaces do not yet contain
FR/SC traceability or clarification-blocking instructions. The pre-change
`scripts/build.sh --check` assertion stayed green.

### Green

`bash scripts/smoke.sh` → exit 0. All @s1–@s6 assertions pass; build drift and
existing smoke coverage stay green.

### Refactor

Kept the change to instruction text plus one 41-line smoke file. Reused the
existing build and smoke helpers; no runtime, dependency, or abstraction added.
