# Mobile patterns — navigation, state, offline, platform

Read this only when `.claude/rules/patterns.md` routed a mobile force here.
Every row's *simplest alternative* is tried before the pattern is named.

| Force | Pattern | Simplest alternative |
|---|---|---|
| Deep links, auth-gated screens, or back-stack rules beyond push/pop | Navigation coordinator / typed routes | The framework's navigator with string routes |
| Screen logic must survive rotation / recreation and be unit-tested without UI | View model | State in the screen; a plain function for the logic |
| Users act while offline and expect it to stick | Offline-first store + sync queue | Show an offline banner and block writes |
| Two devices edit the same record | Sync with conflict policy (last-write-wins, CRDT, or server-authoritative) | Server-authoritative; refetch on reconnect |
| A feature needs a native API the framework does not expose | Platform channel / bridge | Use the framework's plugin for it |
| Repeated screen-lifecycle boilerplate (permissions, connectivity) | Composable / hook / lifecycle-aware component | Inline it in the one screen that needs it |

## Simplest default first

1. The framework navigator with plain routes before a coordinator layer.
2. Screen-local state before a view model; a view model before a global store.
3. Online-only with a clear offline banner before any sync engine.
4. Server-authoritative conflict handling before merging on the device.
5. An existing plugin before a hand-written platform channel.

## When each earns its keep / when it is a smell

**Navigation coordinator / typed routes.** Earns its keep when deep links,
auth redirects, or multi-step flows (onboarding, checkout) make the back stack a
business rule. Smell: a coordinator that wraps `push`/`pop` one-to-one; string
routes hidden behind an enum with no behavior.

**View models.** Earn their keep when screen state must outlive the view
(rotation, tab switch) or the logic has branches worth unit-testing without the
UI. Smell: a view model per trivial screen holding one string; view models that
reach into the view.

**Offline-first + sync queue.** Earns its keep when the product promise is "it
works on the train": local store is the source of truth, writes append to a queue,
a sync worker replays them with idempotency keys. Smell: "offline support" that is
just a cached last response; a sync queue with no idempotency, so replays duplicate.

**Conflict policy.** Earns its keep only once two writers exist. Pick one policy
per record type and name it: last-write-wins (acceptable for preferences),
server-authoritative (payments, inventory), field-level merge or CRDT (notes,
lists). Smell: "merge" with no stated policy; CRDTs for data one user edits.

**Platform channels / bridges.** Earn their keep for a native capability with no
maintained plugin (a vendor SDK, a sensor). Keep the boundary thin and typed;
one channel per capability. Smell: a bridge to reimplement what a plugin already
does; business logic living on the native side.

**Lifecycle composables.** Earn their keep when permission flows, connectivity
listeners, or analytics screen events repeat across screens. Smell: extracted
from one screen; composables that own navigation.

## Domain anti-patterns

- **God screen.** Fetching, formatting, validation, and navigation in one file.
- **State in the navigator.** Business state passed as route params and mutated there.
- **Fake offline.** Cached reads shown as if fresh; writes silently dropped.
- **Sync without idempotency.** The queue replays and creates duplicates.
- **Global store for screen-local state.** Every field global; nothing is disposable.
- **Blocking the main thread.** Parsing, image decoding, or crypto on the UI thread; move it to a background isolate/thread/queue.
