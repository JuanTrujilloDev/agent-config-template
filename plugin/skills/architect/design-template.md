# <ID> — design

- Scope: `<scope markdown>`, approved <date>
- Author: <provider and model> (each per-model design) or "consolidated from designs/*.md" (`design.md`)
- Code read at: <branch> <sha>

## Interrogation
Consolidated design only (architect step 3): checked, failed and fixed, could not check, dropped.

## Consolidation
| Section | Base | Grafted |
| --- | --- | --- |

## Disagreements
| Element | What each said | Pick | Reason |
| --- | --- | --- | --- |

## Screens
Per flow step: what the user sees, the template or component, its states (empty, loading, error, success) and the design tokens it uses.

## Backend
Per piece: its file and map row, signature, what it reads and writes, migrations. Two shapes considered, one kept, one line why.

## Security
Per endpoint and field: who may read, who may write, validation at the boundary, what must never leak.

## Complexity
One row per piece that reads the database, loops over a collection, calls an outside service or runs in a task. Plain helpers have no row.

| Piece | n is | Time | DB queries | Memory | Outside calls | Checked by |
| --- | --- | --- | --- | --- | --- | --- |
| `ProjectedFundService.totals` | portfolios of the issuer | O(n + m), m = holdings | 3, constant in n | one page of rows | none | slice test: same query count at 1 and 40 portfolios |

- Say what n is: "O(n)" without "n of what" is a finding.
- Queries are constant or grow with n; growing needs a reason in the row.
- Memory says whether the whole set is loaded or iterated (iterator, streaming, pagination).
- "Checked by" becomes an approved test in the slice (`tests-first`).

## Last-resort error handling
`None.`, or one row per try the design cannot avoid (principles, Deslop):

| File | Function | Why no handler covers it |
| --- | --- | --- |

## Slices
Per flow, in `db → be → fe` order per capability group. Each slice keeps one layer.

| # | Layer | Name | Flow steps it builds | Placement rows | Hours |
| --- | --- | --- | --- | --- | --- |

## Open questions
Each with who decides, why it matters and a default.
