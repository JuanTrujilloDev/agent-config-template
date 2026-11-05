## TDD: bounded-review-convergence (@s17..@s25)

### Public behavior seams

- Optional schema-v2 `review_cycles` validation.
- PMO's new-ledger default.
- Shared workflow transition from review through approval or escalation.

### Scenario → check

- @s17–@s18 → absent/0/2 pass; negative/3/boolean/string fail.
- @s19–@s21 → cycle zero, increment-before-re-review, required approvals, and
  two-cycle maximum are explicit.
- @s22–@s23 → cap exhaustion writes both positions and blocks for a human.
- @s24 → new mini-features and reapproved amendments reset to zero.
- @s25 → PMO/orchestrator parity and all three workflow surfaces agree.

### Red

Focused MF3 smoke → exit 1 on 2026-09-02. Historical ledgers without the field
still passed, but invalid cycle values also passed and no PMO/orchestrator/
workflow surface defined the bounded transition.

### Green

`bash scripts/smoke.sh` → exit 0. The validator now accepts absent/0/2 and
rejects negative/3/boolean/string values; PMO, orchestrator, and all workflow
surfaces pass @s17–@s25.

### Refactor

Added one optional integer check to the existing validator and one shared
transition block per host. No migration, schema bump, or workflow engine.
