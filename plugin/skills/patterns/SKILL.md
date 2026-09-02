---
description: "Design-pattern restraint — inspect the project's existing patterns first, name the present force, then choose the simplest default or refuse with a one-line why. Default-reject list (single-implementation Strategy, speculative Repository, unnecessary Factory, Singleton, Service Locator), the pattern / force / rejected alternative ledger, and a force-to-reference routing table for six domains (backend, frontend, mobile, game, desktop, concurrency). Reference when writing Design notes in a spec, adding any new abstraction, or reviewing a diff for pattern-stuffing."
---

# Design Patterns — restraint first

A pattern is a named answer to a *force* (a variation, a boundary, a failure
mode) that is present in the code today. Without the force, the pattern is
indirection you pay for on every read. This skill decides, in order, whether a
pattern earns its place; the domain references say which one. Inspired by
00suryavanshi00/code-design-patterns (MIT) — adapted wording, our rungs.

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
   mini-features, and it needs no further justification.

## Default-reject list

Rejected unless the force is written down and the simplest default below has
been tried and shown insufficient:

| Rejected by default | Why it usually fails | Simplest default instead |
|---|---|---|
| **Strategy** with a single implementation | Interface + class for one behavior; the second strategy never arrives | A plain function; add a second function when the second variant exists. Strategy earns its place only when each variant carries its own state. |
| **Speculative Repository** (over an ORM that already abstracts storage) | Two persistence layers, one of them empty | Call the ORM / query layer directly; a Repository when a second store or a real test seam is present |
| Unnecessary **Factory** (one product, or one-liner construction) | A class to call a constructor | A dict or literal mapping `key -> constructor`; a plain function |
| **Singleton** | Hidden global state; untestable; breaks under concurrency | Constructor injection — pass the one instance in; the composition root owns lifetime |
| **Service Locator** / DI container | Dependencies become invisible; failures move to runtime | Constructor injection, explicit arguments |
| **State** with ≤3 states and no per-state data | A class hierarchy for a `switch` | An enum or flag plus a small transition function |

Also a smell by default: an anemic domain model (data classes plus a `*Service`
holding all the logic) and any `*Manager` / `*Helper` wrapping one call site.

## Ledger

Every pattern that survives the protocol gets one ledger line in the spec's
Design notes:

```
pattern / force / rejected alternative
Strategy / three payment providers ship today, each with its own credentials state / dict of functions (rejected: per-provider state leaked into closures)
```

No pattern in the mini-feature → the single line `no pattern — single call site`
(or the actual reason: `no pattern — one variant`). A pattern without a ledger
line is pattern-stuffing.

## Progressive disclosure — force → reference

Read only the reference the force points to — never the whole catalogue. Each
file opens with a `Force | Pattern | Simplest alternative` routing table and a
"Simplest default first" list. The six domain files ship at
`${CLAUDE_PLUGIN_ROOT}/template/.claude/patterns/<domain>.md` (plugin install)
and next to this skill as `references/<domain>.md` (Codex install); in a project
rendered with `/setup-template` or `setup.sh --host <hosts>` they are `.claude/patterns/<domain>.md`.

| Force lives in… | Domain file |
|---|---|
| APIs, persistence, migrations, retries, caching | `backend.md` |
| UI composition, client state, derived vs stored state | `frontend.md` |
| Navigation, offline/sync, view models, platform bridges | `mobile.md` |
| Unity components, data assets, pooling, update-loop budgets | `game.md` |
| MVVM/MVC, undo, document models, background work | `desktop.md` |
| Worker pools, backpressure, circuit breakers, actors, outbox | `concurrency.md` |

## Who uses this

- **pmo (`/spec`)** — runs the protocol per mini-feature and writes the ledger line (or the refusal) in Design notes.
- **Implementers (`/feature`, `/fix`)** — implement the ledger as written; a new abstraction not in the ledger goes back through steps 1–3 before it is coded.
- **judge** — checks every new abstraction against the ledger; a pattern without a stated force, or a simpler rejected alternative never tried, is a Blocker.
- **`/verify`** — asks, for each new abstraction in your own diff, whether it has a ledger entry and whether the simplest default was tried first.
