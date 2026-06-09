# Backend Code Style — {{project_name}}

> Applies to: `{{src_dir}}/**`. {{language}} {{language_version}}, {{backend_framework}}.

## Code Formatting

- **Line length:** {{line_length}} chars
- **Formatter:** {{formatter}}
- **Linter:** {{linter}}
- Run after every change: `{{format_cmd}}` then `{{lint_cmd}}`

## File Organization

- Imports always at the top of the file. Never inside methods or functions.
- One class per file unless they're tightly coupled (e.g., a small private helper class used only by the public one).
- Naming: descriptive, lowercase with underscores (Python) or camelCase (JS/TS). File names match the primary export.

## Functions & Classes

- Single responsibility — if a function does two things, split it.
- Aim for O(1) or O(n). Avoid O(n²) — use dict/set lookups for membership.
- Public functions get a docstring/JSDoc. Simple functions get a one-liner; complex ones get Args/Returns.

## Validation

- Validate at the boundary (request handler, serializer, schema). Don't re-validate downstream.
- Trust internal code and framework guarantees.

## Error Handling

- Raise specific exceptions, not generic `Exception`/`Error`.
- Catch only what you can handle. Let unexpected errors propagate.
- Never silently swallow errors (no bare `except:`).

## Testing

- One assertion per test (when reasonable).
- Naming: `test_when_<condition>_then_<expected>` or `it('should ...')`.
- Use fixtures/factories for test data; never share mutable state across tests.
- Coverage target: ≥{{test_coverage_target}}%.

## Database / Persistence

- Always use the project's ORM/query builder — no raw SQL unless there's a specific reason (and document it).
- Optimize queries: use `select_related`/eager loading for FKs, `prefetch_related` for reverse relations / collections.
- Bulk operations for >10 inserts/updates.

{{#has_celery}}
## Background Tasks (Celery)

- Tasks live under `{{src_dir}}/<app>/tasks/`.
- Tasks should be idempotent: re-running shouldn't cause double-effects.
- Pass IDs/primitive args, not ORM instances.
{{/has_celery}}

## Anti-patterns to avoid

- `*Service` classes that wrap a single function "in case we need more later"
- Premature abstractions — three similar lines beats a Strategy pattern
- Catching exceptions just to re-raise them with a slightly different message
- Wide `try/except` that hides real errors
- Mocking ORM in unit tests when an in-memory DB would do
