<!-- requires: has_frontend -->
# Frontend Code Style — {{project_name}}

> Applies to: `{{frontend_dir}}**`. {{frontend_framework}}.

## Code Formatting

- **Line length:** {{line_length}} chars (120 for HTML/JSX)
- **Formatter:** prettier
- **Linter:** eslint
- **Quotes:** single
- **Semicolons:** yes
- **Trailing commas:** ES5 style
- **Indent:** 2 spaces

## File Organization

```
{{frontend_dir}}
├── components/    # Reusable UI components
├── pages/         # Page-level components / routes
├── lib/           # Helpers, hooks, utilities
├── styles/        # Global styles
└── __tests__/     # Tests (or co-located *.test.*)
```

## Components

- One component per file. File name matches the component name.
- Props typed (TypeScript) or PropTypes/JSDoc'd (JS).
- Keep components small (<200 lines). Extract sub-components or hooks when they grow.
- No prop drilling more than 2 levels — lift to context or composition.

## State

- Local state for local concerns. Lift only when shared.
- Server state via your data-fetching library (React Query, SWR, etc.) — don't reimplement caching/loading.

## Event Handling

- Use event delegation for lists / dynamic content.
- Debounce input handlers for search/filter.
- Always handle the "loading" and "error" states, not just the happy path.

## API Integration

- Centralize API calls in one place (a `lib/api/` or `services/` module). No `fetch` calls scattered in components.
- Handle 4xx/5xx with a shared error handler.
- Show optimistic UI when safe; reconcile on server response.

## Accessibility

- Every interactive element has an accessible name (`aria-label`, label, or visible text).
- Focus order matches visual order.
- Color contrast meets WCAG AA.
- Keyboard navigation works without a mouse.

## Testing

- Unit-test pure functions and hooks.
- Component-test interactions (click, type, submit), not implementation details.
- Mock at the network boundary, not at the framework level.

## Anti-patterns to avoid

- Inline styles instead of using design tokens
- `useEffect` for derived state — use `useMemo` or compute on render
- Direct DOM manipulation (`document.querySelector`) — use refs/framework idioms
- Massive prop interfaces — split components instead
