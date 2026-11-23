---
name: lang-javascript
description: "JavaScript written well anywhere: modules, equality, async, DOM, collections. Loaded when reading or editing a .js, .mjs, .cjs or .jsx file, next to the project's frontend-style skill; it never repeats the project's formatting or layout rules."
paths: ["**/*.js", "**/*.mjs", "**/*.cjs", "**/*.jsx"]
---

# lang-javascript

How JavaScript is written well in any project. Formatting, component layout and state rules are the project's (`frontend-style`, `.claude/rules/architecture-map.md`); Deslop is in the principles. Where the project's code already does it differently, the project wins.

| Rule | Do |
| --- | --- |
| Modules | ES modules, named exports; one default export only where the framework asks for it |
| Bindings | `const` by default, `let` when reassigned, never `var` |
| Equality | `===` and `!==`; `??` for absence, not `\|\|` when `0` or `''` are valid |
| Optional access | `a?.b` once, at the boundary where the value may be missing; not chained through code that already knows it exists |
| Async | `async`/`await`; `Promise.all` for independent work; never a floating promise |
| Collections | `map` / `filter` / `find` / `some`; a `for...of` loop when the body needs more than one statement; never `forEach` with an `await` inside |
| Objects | spread to copy (`{ ...a, b }`); never mutate an argument |
| Lookups | an object or `Map` keyed by the case, not an `if` / `switch` chain on the same value |
| DOM | `textContent` for text; `innerHTML` only with markup you wrote, never with user input |
| Events | delegate from a stable parent; remove listeners you add to `window` or `document` |
| Numbers | `Number.parseInt(x, 10)`; `Number.isNaN`; money as integer minor units or a decimal library |
| Dates | ISO strings across the wire; `Intl.DateTimeFormat` for display |
| Errors | throw `Error` subclasses with a message; never throw a string |
