---
name: patterns
description: "Design-pattern restraint: inspect the project's existing patterns first, name the force present today, then choose the simplest default or refuse with a one-line why. Default-reject list and a force-to-reference table for six domains (backend, frontend, mobile, game, desktop, concurrency). Use when a slice or diff adds an abstraction."
---

# Design Patterns — restraint first

A pattern is a named answer to a *force* (a variation, a boundary, a failure
mode) that is present in the code today. Without the force, the pattern is
indirection you pay for on every read. This skill decides, in order, whether a
pattern earns its place; the domain references under `references/` say
which one. Inspired by 00suryavanshi00/code-design-patterns (MIT) — adapted
wording, our rungs.

## Selection protocol (in this order)

1. **Inspect existing project patterns first.** Before naming anything, look at
   how the codebase already solves this shape of problem — the `code-query` skill
   (graph first, grep second) finds the existing repository, event bus, state
   machine, or plain module you should extend instead of duplicate. A pattern the
   project already uses beats a better pattern it does not.
2. **Name the present force before selecting.** State the concrete thing that
   pushes for structure: "three payment providers exist now", "two callers need
   different retry policies", "this write must survive a crash mid-request". If
   the sentence needs "might", "later", or "eventually", there is no force yet.
3. **Choose or refuse, with a one-line why.** Pick the simplest thing that
   answers the force — often a function, a dict, an enum, a constructor
   argument — and only reach for the named pattern when the simplest default
   fails a stated way. Write the why in one line. Refusal is a valid and common
   result: `no pattern — single call site` is the expected answer for most
   slices, and it needs no further justification.

## Default-reject list

These are rejected unless the force is written down and the simplest default
below has been tried and shown insufficient:

| Rejected by default | Why it usually fails | Simplest default instead |
|---|---|---|
| **Strategy** with a single implementation | Interface + class for one behavior; the second strategy never arrives | A plain function; add a second function when the second variant exists. Strategy earns its place only when each variant carries its own state. |
| **Speculative Repository** (Repository over an ORM that already abstracts storage) | Two persistence layers, one of them empty | Call the ORM / query layer directly; introduce a Repository when a second store or a real test seam is present |
| Unnecessary **Factory** (Factory for one product or a one-liner construction) | A class to call a constructor | A dict or literal mapping `key -> constructor`; a plain function |
| **Singleton** | Hidden global state; untestable; breaks under concurrency | Constructor injection — pass the one instance in; the composition root owns lifetime |
| **Service Locator** / DI container | Dependencies become invisible; failures move to runtime | Constructor injection, explicit arguments |
| **State** with ≤3 states and no per-state data | A class hierarchy for a `switch` | An enum or flag plus a small transition function |

Also a smell by default: an anemic domain model (data classes plus a `*Service`
that holds all the logic) and any `*Manager` / `*Helper` wrapping one call site.

## Recording the decision

The slice brief states the outcome in one line, in this shape:

```
pattern / force / rejected alternative
Strategy / three payment providers ship today, each with its own credentials state / dict of functions (rejected: per-provider state leaked into closures)
```

or the refusal: `no pattern — single call site` (or the actual reason: `no pattern — one variant`, `no pattern — ORM already abstracts storage`). A pattern with no stated force is pattern-stuffing.

## Progressive disclosure — force → reference

Read only the reference the force points to — there is never a reason to read
the catalogue end-to-end. Each file opens with a `Force | Pattern | Simplest alternative`
routing table and a "Simplest default first" list.

| Force lives in… | Reference |
|---|---|
| APIs, persistence, migrations, retries, caching (backend) | `references/backend.md` |
| UI composition, client state, derived vs stored state (frontend) | `references/frontend.md` |
| Navigation, offline/sync, view models, platform bridges (mobile) | `references/mobile.md` |
| Unity components, data assets, pooling, update-loop budgets (game) | `references/game.md` |
| MVVM/MVC, undo, document models, background work (desktop) | `references/desktop.md` |
| Worker pools, backpressure, circuit breakers, actors, outbox (concurrency / distributed) | `references/concurrency.md` |

## Who uses this

- **`/slice`** — runs the protocol per slice and writes the decision (or the refusal) in the brief.
- **`implement`, `/fix`** — build what the brief decided; a new abstraction it does not name goes back through steps 1–3 first.
- **`code-review`** — a new abstraction without a stated force, or with a simpler default never tried, is a Blocker.
- **`/verify`** — asks, for each new abstraction in your own diff, whether the simplest default was tried first.
