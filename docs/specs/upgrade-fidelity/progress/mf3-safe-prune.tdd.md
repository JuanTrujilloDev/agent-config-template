# MF3 safe-prune — TDD

## Public seams

- Preview classifies lock-only managed paths as `OBSOLETE` or
  `CUSTOMIZED-OBSOLETE`.
- `--prune` is accepted only with `--merge`.
- `--merge --prune` deletes only proven-safe `OBSOLETE` files, reports each
  deletion, removes empty managed directories, and updates the lock.
- Repeating the same prune is a no-op; ordinary merge never deletes.

## Red

- Scenario: `@s16` labels an unchanged lock-only managed file `OBSOLETE`.
- Test: `scripts/smoke/v092-mf3-prune.sh`.
- Observed: preview exits 1 as expected, but prints no `OBSOLETE` line for the
  lock-only `.claude/rules/retired.md` path.

## Green

- Extended the existing lock classifier and merge loop; no dependency or new
  subsystem was added.
- Focused source/bundle fixtures and the full smoke suite pass.

## Refactor

- Reused the existing managed-path, realpath, SHA-256, atomic lock, and merge
  boundaries. One fixture helper owns repeated lock setup.

## Scenario map

- @s16 → unchanged lock-only preview.
- @s17 → edited file, leaf symlink, and escaping parent symlink.
- @s18 → ordinary merge retention and reporting for both labels.
- @s19 → explicit prune deletion and per-path output.
- @s20 → missing/invalid state, unrecorded, user-owned, traversal, and absolute paths.
- @s21 → prune-without-merge refusal before writes.
- @s22 → directory cleanup, state cleanup, and repeat no-op.
- @s23 → source/bundle parity, help/docs, and full regression suite.
