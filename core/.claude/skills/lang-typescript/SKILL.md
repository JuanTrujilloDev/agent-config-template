---
name: lang-typescript
description: "TypeScript written well anywhere: types at the boundary, unions over flags, narrowing, no any. Loaded when reading or editing a .ts or .tsx file, together with lang-javascript; it never repeats the project's formatting or layout rules."
paths: ["**/*.ts", "**/*.tsx"]
---

# lang-typescript

Read `lang-javascript` too: everything there holds. This adds what the type system changes. Where the project's code already does it differently, the project wins.

| Rule | Do |
| --- | --- |
| `any` | never; `unknown` at the boundary, then narrow |
| Boundaries | parse input once where it enters (a schema validator or a type guard); trust the type inside |
| States | a discriminated union (`{ kind: 'loading' } \| { kind: 'ready', data: T }`), not several booleans |
| Narrowing | `switch` on the discriminant with a `never` check in `default`; no `as` to silence the compiler |
| Assertions | no non-null `!`; handle the `undefined` where it can happen |
| Types vs interfaces | `type` for unions and shapes; `interface` only for something meant to be extended |
| Enums | a union of string literals or an `as const` object, not `enum` |
| Inference | let return types infer inside a module; annotate exported functions |
| Utility types | `Pick`, `Omit`, `Partial`, `Record` over copied shapes |
| Readonly | `readonly` arrays and properties for data you pass along and do not change |
| Generics | only when two places share the type; one letter only for a truly generic slot |
| Config | `strict: true` stays on; no `// @ts-ignore` (use `@ts-expect-error` with the reason, as a tool directive) |
