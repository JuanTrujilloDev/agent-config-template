---
name: lang-css
description: "CSS written well anywhere: tokens, layout, specificity, responsive, accessibility. Loaded when reading or editing a .css, .scss or .html file, next to the project's frontend-style skill and design system; it never repeats them."
paths: ["**/*.css", "**/*.scss", "**/*.html"]
---

# lang-css

How CSS is written well in any project. Values come from the project's design system (`docs/design-system/`), never from here; Deslop is in the principles. Where the project's code already does it differently, the project wins.

| Rule | Do |
| --- | --- |
| Values | design tokens (`var(--…)`) for color, spacing, radius, type and shadow; a raw value only where no token exists, and then add the token |
| Layout | flexbox for one axis, grid for two; no floats or absolute positioning for layout |
| Spacing | `gap` between children; margin on one side only (block-end) when gap does not apply |
| Specificity | single classes; no IDs and no `!important` in component styles; no selector deeper than two levels |
| Responsive | mobile first with `min-width` queries; `minmax(0, 1fr)` so grid cells can shrink; no horizontal page scroll at 320 px |
| Units | `rem` for type, tokens for spacing; `px` only for borders and hairlines |
| States | style `:hover`, `:focus-visible`, `:disabled` and `[aria-*]` together; never remove a focus outline without a visible replacement |
| Motion | transitions on `opacity` and `transform`; respect `prefers-reduced-motion` |
| Color | meaning never by color alone; text contrast at least 4.5:1 |
| Theming | dark mode by redefining tokens, not by overriding components |
| Names | class names say what a thing is (`.fund-card`), not how it looks (`.blue-box`) |
