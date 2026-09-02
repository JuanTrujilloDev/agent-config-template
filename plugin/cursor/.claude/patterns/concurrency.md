# Concurrency & distributed patterns

Read this only when `.claude/rules/patterns.md` routed a concurrency or
distributed-systems force here. Every row's *simplest alternative* is tried
before the pattern is named.

| Force | Pattern | Simplest alternative |
|---|---|---|
| Many independent tasks; unbounded spawning exhausts memory or connections | Worker pool | Sequential loop; the runtime's built-in executor |
| One slow dependency starves every other request | Bulkhead (isolated pools / limits per dependency) | One global limit |
| A failing dependency keeps being called and timeouts pile up | Circuit breaker | Timeout + bounded retry |
| Producer outruns consumer; queues grow without bound | Backpressure (bounded queue, block/drop/shed) | Smaller batch size or a hard rate limit at the producer |
| Shared mutable state accessed from several threads/tasks | Actor (own the state, message it) vs locks | A single owner thread; immutable data |
| A message may be delivered twice | Idempotent consumer | De-duplicate by message id at the boundary |
| A database write and an event publish must both happen or neither | Transactional outbox | Publish after commit and tolerate the rare miss (if stated acceptable) |

## Simplest default first

1. Sequential code before concurrency; measure first.
2. The runtime's executor / task group with a fixed size before a custom pool.
3. Immutable data and a single owner before locks; a lock before an actor framework.
4. A bounded queue before any explicit backpressure protocol.
5. Timeout + bounded retry with jitter before a circuit breaker.
6. Natural idempotency (upsert by key) before a de-duplication store.

## When each earns its keep / when it is a smell

**Worker pool.** Earns its keep when task count is unbounded and each task holds
a resource (socket, connection, memory): fixed workers pull from a bounded queue.
Smell: a pool of one; a pool per call site; pools nested inside pools.

**Bulkhead.** Earns its keep when one dependency's latency can consume all
workers and take unrelated endpoints down with it: a separate pool or semaphore
per dependency. Smell: bulkheads around a single dependency; limits with no
measurement behind them.

**Circuit breaker.** Earns its keep when a dependency fails for seconds to
minutes and each attempt costs a timeout: open after N failures, fail fast, probe
half-open. Smell: a breaker around an in-process call; breakers with no metrics
or alerting on the open state; a breaker instead of a fix to the dependency.

**Backpressure.** Earns its keep whenever producers and consumers run at
different speeds: bound the queue, then decide per stream — block the producer,
drop oldest, or shed load with an explicit error. Smell: unbounded queues "for
now"; silently dropping without a counter.

**Actor vs locks.** A lock earns its keep for a small critical section on
in-process state. An actor earns its keep when state has a lifecycle and a
protocol (a connection, a session, a game entity) and callers must never see it
mid-update: one owner, a mailbox, no shared references. Smell: locks held across
I/O; actors for a counter; an actor framework for one actor.

**Idempotent consumer.** Earns its keep with at-least-once delivery (every
real queue): key the effect on the message id or a natural key, store processed
ids with a TTL, make the handler safe to re-run. Smell: exactly-once assumptions;
de-dup by wall-clock proximity.

**Transactional outbox.** Earns its keep when a state change and an outgoing
event must agree: write the event to an outbox table in the same transaction; a
relay publishes and marks it sent. Smell: outbox for events nobody consumes;
dual writes with a comment saying "should be atomic".

## Domain anti-patterns

- **Unbounded concurrency.** `spawn` per item with no limit; the first big batch takes the process down.
- **Retry storms.** Every layer retries; one blip becomes an outage.
- **Locks across I/O.** Holding a mutex while awaiting the network.
- **Shared mutable state by default.** Globals touched from many tasks; "it hasn't raced yet".
- **Dual writes.** Database then message broker, no outbox, no reconciliation.
- **Timeouts missing.** Any network call without a deadline is a future hang.
- **Fire-and-forget without observation.** Background tasks whose failures vanish.
