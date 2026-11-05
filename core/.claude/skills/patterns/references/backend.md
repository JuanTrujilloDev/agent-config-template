# Backend patterns — API & persistence

Read this only when `.claude/rules/patterns.md` routed a backend force here.
Every row's *simplest alternative* is tried before the pattern is named.

| Force | Pattern | Simplest alternative |
|---|---|---|
| Two real stores (or a genuine test seam) for the same aggregate | Repository | Call the ORM / query layer directly |
| Several writes must commit or roll back together | Unit of Work | One transaction block around the calls |
| Clients retry a non-idempotent write | Idempotency key | Make the write naturally idempotent (upsert by natural key) |
| Concurrent edits to one row overwrite each other | Optimistic locking | Serialize through one writer; last-write-wins if acceptable and stated |
| Schema change with live traffic | Expand-contract migration | Additive-only change, no migration choreography |
| A downstream call fails transiently | Retry + backoff | Fail fast and let the caller retry (if the caller is a queue) |
| Repeated identical reads dominate latency | Cache-aside | Fix the query / add the index first |

## Simplest default first

1. A plain function on the request path, calling the ORM or client directly.
2. A module of functions before a `*Service` class; a class only when it owns state.
3. A transaction block before a Unit of Work object.
4. An upsert on a natural key before an idempotency table.
5. A database constraint or index before application-side checks and caches.

## When each earns its keep / when it is a smell

**Repository.** Earns its keep with two concrete stores (Postgres + in-memory
for a genuine contract test, or a migration between stores) or when the query
surface must be hidden behind aggregate-shaped methods for many callers. Smell:
a Repository that mirrors the ORM one-to-one (`find_by_id`, `save`) with a
single implementation — you now maintain two persistence APIs.

**Unit of Work.** Earns its keep when several repositories must share one
transaction and the caller should not know the transaction boundary. Smell:
a UoW wrapping one `commit()`; the framework's transaction block already is the
unit of work.

**Idempotency keys.** Earn their keep for client-generated writes that create
money movement, external side effects, or non-unique rows: store
`(key, response)` and replay the stored response on a duplicate. Smell: keys on
reads or on writes that are already upserts.

**Optimistic locking.** Earns its keep when two humans (or workers) edit the same
row and a silent overwrite would lose data: a version column, compare-and-set,
409 on mismatch. Smell: version columns on rows with a single writer; pessimistic
locks held across a network call.

**Expand-contract migrations.** Earn their keep for any column rename, type
change, or split under live traffic: add the new shape, dual-write, backfill,
switch reads, remove the old shape — each step deployable alone. Smell: a
one-shot rename that is "quick" and locks the table.

**Retry + backoff.** Earns its keep for transient failures on idempotent calls:
bounded attempts, exponential backoff with jitter, a retry budget. Smell: retries
on non-idempotent calls (duplicate charges), unbounded retries, retries stacked at
every layer so one failure becomes N² calls.

**Cache-aside.** Earns its keep when the same expensive read is served many times
and staleness is tolerable for a stated TTL: read cache, miss → load → populate.
Smell: caching before the query was profiled; caching writes; no invalidation
story; a cache that hides a missing index.

## Domain anti-patterns

- **Anemic model + fat service.** Data classes with no behavior and a `*Service` holding every rule. Put invariants on the model; keep services thin orchestrators.
- **Repository-over-ORM.** One implementation, method-for-method mirror of the ORM.
- **Generic `BaseRepository<T>`.** Abstraction over aggregates that have nothing in common but CRUD.
- **Transaction per repository call.** Autocommit everywhere; consistency by luck.
- **Retry without idempotency.** The retried request succeeds twice.
- **Cache as the source of truth.** Reads that never hit the database and drift.
