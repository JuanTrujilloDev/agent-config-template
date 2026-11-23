# Architecture map — {{project_name}}

> Always loaded. Where each kind of code goes, so no prompt repeats it. This file is yours: `/setup-template` drafts the rows from the code and a re-render never overwrites it. Every piece in a slice's `## Placement` names a row here; a piece with no row adds one in the same slice and says so in the PR.

## Map

| Kind | Lives in | Per module | File name | Check |
| --- | --- | --- | --- | --- |
| Test | `{{tests_glob}}` | one module under test | `test_<module>` | — |

## Columns

- **Lives in**: a glob from the repo root (`apps/*/models/*.py`).
- **Per module**: what one file holds (one model; every serializer of one domain; functions only).
- **Check**: what `tools/verify_changed.py` enforces on the lines a change adds, for Python modules: `max <N> classes`, `max <N> classes based on <Base>` (top-level classes whose base name ends the dotted path, e.g. `Model` for `models.Model`), `no classes`, or `—`. Add a check only where the code already follows the row; `code-review` checks the other columns against the slice's Placement.
