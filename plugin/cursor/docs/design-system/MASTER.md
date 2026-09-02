<!-- requires: has_ui -->
# {{project_name}} — Design System (MASTER)

Single source of truth for every visual decision in {{project_name}}.
{{#has_frontend}}
Stack: {{frontend_framework}}.
{{/has_frontend}}

Rules of use:

- Implementers (`ui-designer`, dev agents, humans) **cite tokens, not raw values**. `var(--color-primary)` / `$space-4` / `theme.radius.md` — never `#3B82F6`, `17px`, or `rounded-[6px]`.
- Page-specific overrides live in `docs/design-system/pages/<page>.md`, **only when a page must genuinely deviate** from this file. An override uses the same section names as below and wins over MASTER for that page only. No override file means MASTER applies unchanged.
- `TODO:` marks a value not yet decided. Resolve it here (once) rather than inventing a value at the call site.
- Change a token here first; then propagate. A value that appears in code but not in this file is a defect (see Anti-patterns).

## Colors & semantic tokens

Palette values are named once; everything else references a semantic token.

| Token | Role | Light | Dark |
|---|---|---|---|
| `--color-primary` | Primary actions, links, focus | `TODO: hex` | `TODO: hex` |
| `--color-primary-hover` | Hover/active state of primary | `TODO: hex` | `TODO: hex` |
| `--color-secondary` | Secondary actions, accents | `TODO: hex` | `TODO: hex` |
| `--color-bg` | Page background | `TODO: hex` | `TODO: hex` |
| `--color-surface` | Cards, panels, sheets | `TODO: hex` | `TODO: hex` |
| `--color-surface-raised` | Modals, popovers, menus | `TODO: hex` | `TODO: hex` |
| `--color-border` | Dividers, input borders | `TODO: hex` | `TODO: hex` |
| `--color-text` | Body text | `TODO: hex` | `TODO: hex` |
| `--color-text-muted` | Secondary text, captions | `TODO: hex` | `TODO: hex` |
| `--color-text-inverse` | Text on primary/dark fills | `TODO: hex` | `TODO: hex` |
| `--color-success` | Success states | `TODO: hex` | `TODO: hex` |
| `--color-warning` | Warnings, caution | `TODO: hex` | `TODO: hex` |
| `--color-danger` | Errors, destructive actions | `TODO: hex` | `TODO: hex` |
| `--color-info` | Informational notices | `TODO: hex` | `TODO: hex` |
| `--color-focus-ring` | Keyboard focus outline | `TODO: hex` | `TODO: hex` |

Conventions:

- Semantic tokens only in components. Raw palette scales (`--blue-500`) exist solely to feed this table.
- Every color pair used together (text on surface, text on primary) must meet the contrast minimums in *Accessibility & contrast*.
- Dark mode is a token swap, not a second stylesheet.

## Typography

| Token | Family / size / line-height / weight | Use |
|---|---|---|
| `--font-sans` | `TODO: family`, system fallback stack | Default UI text |
| `--font-mono` | `TODO: family`, monospace fallback | Code, tabular numbers |
| `--text-xs` | 12px / 16px / 400 | Captions, legal |
| `--text-sm` | 14px / 20px / 400 | Secondary text, labels |
| `--text-base` | 16px / 24px / 400 | Body |
| `--text-lg` | 18px / 28px / 500 | Lead paragraphs |
| `--text-xl` | 20px / 28px / 600 | Section headings (H3) |
| `--text-2xl` | 24px / 32px / 600 | Page section headings (H2) |
| `--text-3xl` | 30px / 36px / 700 | Page titles (H1) |

- Type scale is the only source of font sizes. No ad-hoc sizes.
- Weights: 400 body, 500 emphasis, 600–700 headings. Nothing else.
- Max line length for prose: ~65–75 characters (`--measure`).

## Spacing & layout

Base unit: **4px**. Every spacing value is a multiple of the base.

| Token | Value | Typical use |
|---|---|---|
| `--space-1` | 4px | Icon-to-label gap |
| `--space-2` | 8px | Inline gaps, tight padding |
| `--space-3` | 12px | Input padding |
| `--space-4` | 16px | Default component padding |
| `--space-6` | 24px | Card padding, stack gaps |
| `--space-8` | 32px | Section gaps |
| `--space-12` | 48px | Page section separation |
| `--space-16` | 64px | Hero / landing spacing |

Layout:

- Content max width: `--container-max` = `TODO: px` (default 1200px). Gutter: `--space-4` mobile, `--space-6` desktop.
- Grid: 12 columns desktop, 4 columns mobile. Gap `--space-6` / `--space-4`.
- Vertical rhythm: stack children with `--space-4` inside components, `--space-8` between components.

## Radius, shadows & motion

| Token | Value | Use |
|---|---|---|
| `--radius-sm` | 4px | Chips, tags, inputs |
| `--radius-md` | 8px | Buttons, cards |
| `--radius-lg` | 12px | Modals, sheets |
| `--radius-full` | 9999px | Avatars, pills |
| `--shadow-sm` | `TODO: value` | Raised buttons, hover cards |
| `--shadow-md` | `TODO: value` | Cards, dropdowns |
| `--shadow-lg` | `TODO: value` | Modals, popovers |
| `--motion-fast` | 120ms ease-out | Hover, focus, toggles |
| `--motion-base` | 200ms ease-in-out | Expand/collapse, tabs |
| `--motion-slow` | 320ms ease-in-out | Page/route transitions, sheets |

- Honor `prefers-reduced-motion`: non-essential animation collapses to 0ms.
- Motion communicates state change; nothing animates for decoration alone.

## Component conventions

- **Buttons**: variants `primary` / `secondary` / `ghost` / `danger`; sizes `sm` / `md` / `lg`; states default, hover, active, focus-visible, disabled, loading. One primary button per view.
- **Inputs**: label always visible (no placeholder-as-label); helper text below; error text replaces helper text and uses `--color-danger`; height `TODO: px` per size.
- **Cards**: `--color-surface`, `--radius-md`, `--space-6` padding, `--shadow-sm` only if interactive.
- **Modals / sheets**: `--color-surface-raised`, `--radius-lg`, trap focus, close on Escape, return focus on close.
- **Feedback**: toasts for transient success/info; inline messages for errors the user must act on; never both for the same event.
- **Empty / loading / error states**: every data view defines all three. Skeletons over spinners for content areas.
- **Naming**: component files and design specs use the same name (`DataTable` ↔ `data-table.md`).

## Icon & image style

- Icon set: `TODO: set` (one set only; single stroke weight, `TODO: px` stroke). Sizes `--icon-sm` 16px, `--icon-md` 20px, `--icon-lg` 24px.
- Icons inherit `currentColor`; never hardcode an icon color.
- Decorative icons are `aria-hidden`; functional icons carry an accessible label.
- Images: aspect ratios fixed per slot (`16:9` media, `1:1` avatars, `4:3` thumbnails); always `alt` text; lazy-load below the fold.
- Illustration style: `TODO: describe` (flat / outline / photo). One style per product.

## Voice & tone

- Tone: `TODO: pick` (e.g. plain, direct, calm). Sentence case everywhere, including buttons and headings.
- Buttons are verbs that name the outcome: "Save changes", not "OK"; "Delete project", not "Confirm".
- Errors say what happened and what to do next, in one or two short sentences. No blame, no jargon, no error codes as the only message.
- Empty states explain what belongs here and offer the first action.
- Avoid exclamation marks, filler ("Please note that…"), and humor in error or destructive flows.

## Responsive rules

| Breakpoint token | Min width | Layout |
|---|---|---|
| `--bp-sm` | 640px | Single column → two columns for lists |
| `--bp-md` | 768px | Sidebar navigation appears |
| `--bp-lg` | 1024px | Full 12-column grid |
| `--bp-xl` | 1280px | Container reaches `--container-max` |

- Mobile-first: base styles target the smallest viewport; breakpoints add, never subtract.
- Touch targets ≥ 44×44px on every pointer-coarse viewport.
- No horizontal scroll at any breakpoint; wide content (tables, code) scrolls inside its own container.
- Test at 320px, 768px, 1024px, and 1440px before handoff.

## Accessibility & contrast

- **WCAG 2.1 AA is the floor.** Body text ≥ 4.5:1 contrast; large text (≥ 24px, or ≥ 19px bold) ≥ 3:1; UI components and graphical objects ≥ 3:1 against adjacent colors.
- Every color token pair listed in *Colors & semantic tokens* is verified against these ratios in both light and dark themes.
- Focus is always visible: `--color-focus-ring`, 2px outline, 2px offset. Never `outline: none` without a replacement.
- Full keyboard operability: logical tab order, Escape closes overlays, arrow keys within composite widgets (menus, tabs, lists).
- Color is never the only signal (pair with icon, text, or pattern).
- Semantic HTML / platform-native controls first; ARIA only to fill genuine gaps.
- Respect `prefers-reduced-motion` and `prefers-color-scheme`.

## Anti-patterns

Any of these in a diff is a review finding (judge cites `file:line`):

- Hardcoded colors, spacing, radii, shadows, or font sizes not traceable to a token in this file (`#1a1a1a`, `margin: 13px`, `rounded-[5px]`, `text-[15px]`).
- Off-palette values "just this once" — add the token here or use an existing one.
- Inline style objects or arbitrary utility values standing in for tokens.
- A page override in `docs/design-system/pages/<page>.md` that restates MASTER instead of describing a real deviation.
- Introducing a second icon set, font family, or breakpoint scale.
- Placeholder text used as the only label; `outline: none` without a visible focus replacement.
- New component variants when an existing one covers the need.
