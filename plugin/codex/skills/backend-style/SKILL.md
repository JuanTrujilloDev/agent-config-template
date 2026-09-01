---
name: backend-style
description: Backend code style conventions — imports at top of file, single responsibility, validation at boundaries, descriptive error handling, query optimization. Reference when writing or reviewing backend code (models, serializers, views, services, tasks).
---

# Backend Code Style — this project

> Applies to: `src/**`. your language , your backend framework.

## Code Formatting

- **Line length:** 100 chars
- **Formatter:** your formatter
- **Linter:** your linter
- Run after every change: `your project's format command` then `your project's lint command`

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
- Coverage target: ≥80%.

## Database / Persistence

- Always use the project's ORM/query builder — no raw SQL unless there's a specific reason (and document it).
- Optimize queries: use `select_related`/eager loading for FKs, `prefetch_related` for reverse relations / collections.
- Bulk operations for >10 inserts/updates.


## Anti-patterns to avoid

- `*Service` classes that wrap a single function "in case we need more later"
- Premature abstractions — three similar lines beats a Strategy pattern
- Catching exceptions just to re-raise them with a slightly different message
- Wide `try/except` that hides real errors
- Mocking ORM in unit tests when an in-memory DB would do
