## TDD: contract-amendments (@s21..@s27)

### Scenario → check

- @s21–@s23 → PMO assertions cover the exact marker and direct/transitive state
  transitions while preserving unrelated work.
- @s24/@s25 → `/feature` and orchestrator assertions cover stale approval
  refusal plus append-only reapproval in `progress/gate1.md`.
- @s26 → direct validator fixtures accept `needs-rework` and reject unknown
  status values while dependency checks remain active.
- @s27 → workflow surfaces carry equivalent amendment rules.

### Red

`bash scripts/smoke.sh` → exit 1 before implementation: `needs-rework` was
rejected and amendment, reset, stale-approval, and reapproval assertions failed.

### Green

The `v090-mf4-contract-amendments` slice → exit 0. Direct fixtures accept
`needs-rework`, reject unknown statuses, and every source workflow carries the
exact marker, scoped reset, stale Gate 1 refusal, and append-only reapproval.

### Refactor

Kept the change declarative: one validator value plus the existing PMO,
orchestrator, command, and workflow surfaces. No amendment engine or new schema.
