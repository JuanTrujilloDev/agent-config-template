# Frontend patterns — UI & state

Read this only when `.claude/rules/patterns.md` routed a UI/state force here.
Every row's *simplest alternative* is tried before the pattern is named.

| Force | Pattern | Simplest alternative |
|---|---|---|
| The same data-fetching logic is needed by two visually different views | Container / presentational split | One component; pass props |
| Stateful behavior (form, fetch, subscription) reused across components | Hook / composable | Inline the state in the one component that has it |
| A UI has ≥4 states with illegal transitions (idle/loading/success/error/retrying) | State machine | Two booleans, if the states are truly independent |
| A value can be computed from other state | Derived state | Compute it in render; never store it |
| Server data is cached, refetched, and shared across screens | Server-state library (query cache) | `fetch` in the component with local loading/error state |
| A component must render caller-provided content in a fixed frame | Render props / slots / children | A `children` prop |

## Simplest default first

1. One component with local state and plain props.
2. A `children` prop before render props or a slot system.
3. Computed-in-render before stored derived state; a memo only after a measured re-render cost.
4. Two booleans before a state machine; a state machine before the third boolean.
5. Component-local fetch before a global store; a query cache before hand-rolled caching.

## When each earns its keep / when it is a smell

**Container / presentational.** Earns its keep when the same fetched data drives
two distinct presentations, or the presentational half needs to be tested or
storybooked without the data layer. Smell: every component split in two by
policy, with a container that does nothing but pass props through.

**Hooks / composables.** Earn their keep when the *same* stateful behavior
(debounced input, pagination, subscription lifecycle) appears in two components.
Smell: a `useX` extracted from a single call site; hooks that return twelve values.

**State machines.** Earn their keep when there are illegal state combinations
(`loading && error`) that booleans permit, or when transitions carry rules.
Smell: a machine for a two-state toggle; a machine library for one screen.

**Derived state vs stored.** Derived earns its keep always: `total` is
`items.reduce(...)`, `isValid` is `errors.length === 0`. Stored copies of derivable
values are the smell — they drift and need synchronization effects.

**Server-state libraries.** Earn their keep when several screens read the same
server data and need caching, deduplication, background refetch, or optimistic
updates. Smell: a query cache for one endpoint on one screen; server data copied
into a global client store as well.

**Render props / slots.** Earn their keep when the frame component must not know
what it renders but must control *where* and *how often*. Smell: render props
where `children` already works; three nested render-prop callbacks.

## Domain anti-patterns

- **Stored derived state.** `setTotal(sum(items))` in an effect — compute it instead.
- **Global store as default.** Every field in a global store; local state would do.
- **Prop drilling fixed with context everywhere.** Context for values that change on every keystroke; re-renders the whole tree.
- **Effects as data flow.** Chains of effects syncing state to state; the real dependency graph is invisible.
- **Premature memoization.** `memo`/`useMemo`/`useCallback` sprinkled without a measured cost.
- **Component-per-CSS-variant.** A component tree that mirrors the design tokens; use a `variant` prop.
