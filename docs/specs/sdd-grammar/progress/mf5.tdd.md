## TDD: principles-double-gate (@s28..@s33)

### Scenario → check

- @s28–@s30 → PMO assertions require the shared four-column table before Gate
  1, including explicit `None` and a complete justified example.
- @s31/@s32 → judge assertions require the same row, reject missing/unrecorded
  or unused deviations, and cite the justified example.
- @s33 → principles and workflow sources carry equivalent two-gate language.

### Red

Focused smoke → exit 1 before implementation: the shared table, explicit
`None`, second judge check, and missing/unrecorded/unused blockers were absent.

### Green

The `v090-mf5-principles-gates` slice → exit 0. PMO, judge, principles, Cursor,
and workflow surfaces all carry the same table and two-gate behavior.

### Refactor

Reused one four-column Markdown table at both gates. No policy parser, second
ledger, plugin dependency, or new abstraction.
