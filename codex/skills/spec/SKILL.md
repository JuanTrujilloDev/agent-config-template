---
name: spec
description: "Turn an idea, ticket, or SOW into a conversed spec, a Given/When/Then contract, and PR-sized mini-features (pmo). Gate 1: you approve the contract."
---

# /spec

> **On Codex (no subagents):** you play every role yourself, switching hats
> explicitly and in sequence — `pmo` (spec/contract), the dev specialist
> (implement), `judge` (review), `security-reviewer` (when auth/permissions/
> data are touched). Same artifacts under `docs/specs/<slug>/`, same human
> gates (contract approval; failing tests under TDD), same Definition of Done.
> Announce each hat switch in one line.


Turn a raw idea, a tracked ticket, or a SOW request into an approved, executable
contract — via the `pmo` agent. This is the **single entry point for framing
work**: frame the problem, decide the open questions, decompose into PR-sized
mini-features, and write the contract you sign.

## Usage

```
/spec <idea or description>
```

## What it does

1. Spawns **`pmo`**, which **converses** with you — stating the intent (the user-observable change) before any implementation talk, then debating decisions and edge cases, recording the *why*. Where the questions are structural (what exists, what depends on what), it grounds them with the `code-query` skill — graph first, grep second — instead of guessing.
2. Writes `docs/specs/<slug>/spec.md` — problem, goal, verifiable success criteria, decisions, out-of-scope, open questions, and **Design notes**: a named design pattern where one genuinely fits, plus a **Leverage** subsection — for each mini-feature, walk the leverage ladder (`principles` skill): what existing code, standard library, native platform feature, or already-installed dependency covers it, and what genuinely must be written new. Code nobody writes is the cheapest to review.
3. Distills `docs/specs/<slug>/contract.md` — Given/When/Then acceptance scenarios, one block per mini-feature.
4. Writes `docs/specs/<slug>/features.json` — the mini-feature list (each ≤12 files / <3000 LOC), status `pending`.
5. Asks whether to mirror the mini-features into your tracker as subtasks or as a comment on the main task.
6. **Pauses for your approval of the contract (Gate 1).**

## Next

Once you approve the contract, run `/feature` — it picks up the approved spec and
implements the mini-features one at a time. For a small scoped change with an
obvious root cause, skip all of this and use `/fix`.
