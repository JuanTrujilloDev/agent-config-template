---
name: spec
description: Spec-driven: turn an idea, ticket, or SOW into a Given/When/Then contract and PR-sized mini-features before any code is written.
---

# /spec

Turn a raw idea, a tracked ticket, or a SOW request into an approved, executable
contract — via the `pmo` agent. This is the single entry point that **replaces
the old `/idea` and `/sow`**: frame the problem, decide the open questions,
decompose into PR-sized mini-features, and write the contract you sign.

## Usage

```
/spec <idea or description>
```

## What it does

1. Spawns **`pmo`**, which **converses** with you — debating decisions and edge cases, recording the *why*.
2. Writes `docs/specs/<slug>/spec.md` — problem, goal, verifiable success criteria, decisions, out-of-scope, open questions, and **Design notes** (a named design pattern where one genuinely fits).
3. Distills `docs/specs/<slug>/contract.md` — Given/When/Then acceptance scenarios, one block per mini-feature.
4. Writes `docs/specs/<slug>/features.json` — the mini-feature list (each ≤12 files / <3000 LOC), status `pending`.
5. Asks whether to mirror the mini-features into your tracker as subtasks or as a comment on the main task.
6. **Pauses for your approval of the contract (Gate 1).**

## Next

Once you approve the contract, run `/feature` — it picks up the approved spec and
implements the mini-features one at a time. For a small scoped change with an
obvious root cause, skip all of this and use `/fix`.
