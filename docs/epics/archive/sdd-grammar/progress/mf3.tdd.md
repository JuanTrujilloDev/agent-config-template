## TDD: schema-version-and-migration (@s14..@s20)

### Scenario → check

- @s14–@s17 → copies of all four historical ledgers migrate, preserve stable
  fields, validate, and remain byte-identical on a second run.
- @s15/@s16 → focused assertions cover `after`, `files`, dependency, parallel,
  file-hint, and verification defaults.
- @s18/@s19 → unversioned input fails with the migration command; every live
  ledger validates as v2; `/feature` and orchestrator carry recovery guidance.
- @s20 → normal build, packaging, and smoke checks remain required.

### Red

Focused smoke → exit 1 before implementation: the migrator, strict schema-v2
refusal, recovery command, and migration fixtures did not exist.

### Green

The `v090-mf3-schema-migration` slice in `bash scripts/smoke.sh` → exit 0. All
four historical ledgers migrate to schema v2, preserve their
stable fields and file modes, validate, and remain byte-identical on rerun.
All five live ledgers are schema v2; unversioned and unknown schemas fail with
the exact recovery command and do not mutate unsupported input.

### Refactor

Kept migration in one Python stdlib script. Writes are atomic and preserve the
original mode; no dependency, schema framework, or second migration layer.
