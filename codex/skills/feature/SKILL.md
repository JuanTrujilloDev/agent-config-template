---
name: feature
description: "Full spec-driven flow for a feature: approved contract, optional TDD, implement, judge review, micro-commit — one mini-feature at a time."
---

# /feature

> **On Codex (no subagents):** you play every role yourself, switching hats
> explicitly and in sequence — `pmo` (spec/contract), the dev specialist
> (implement), `judge` (review), `security-reviewer` (when auth/permissions/
> data are touched). Same artifacts under `docs/specs/<slug>/`, same human
> gates (contract approval; failing tests under TDD), same Definition of Done.
> Announce each hat switch in one line.


Full **spec-driven** flow for a feature — from signed contract to merged
mini-features — coordinated by the `orchestrator` agent. It pauses at every gate
and never skips ahead.

## Usage

```
/feature <description>             # freeform, e.g. /feature "add CSV export"
```

## What it does

**You are the orchestrator — and every other role.** Codex has no subagents:
read the `sdd-workflow` skill, then run the pipeline yourself, switching hats
one role at a time (pmo → dev → judge → security-reviewer) and announcing each
switch in one line:

### 1. Spec + contract
If there's no approved contract for this work, spawn `pmo`
(or run `/spec` first). Output: `docs/specs/<slug>/{spec.md, contract.md, features.json}`.
**Gate 1 — you approve `contract.md` before any code is written.**

### 2. Per mini-feature (one at a time)
- Set `in_progress`; check out the typed branch (never `the default branch`).
- **Apply TDD?** If yes, the implementer writes the failing tests first → **Gate 2: you approve the tests** before production code.
- Spawn the dev specialist that matches the project type (`backend-dev` web/API · `frontend-dev` web UI · `mobile-dev` · `game-dev` · `desktop-dev` · `core-dev` library/CLI/data), with `ui-designer` first for new UI; implement to green, honoring the Design-notes pattern and its **Leverage** subsection (reuse before writing — leverage ladder in the `principles` skill). For impact analysis before an edit, the `code-query` skill finds dependents cheaply.
- Spawn `judge` — reviews code **and** tests against the contract scenarios.
- Spawn `security-reviewer` if the mini-feature touches auth, permissions, or data.
- Micro-commit on the typed branch; mark `done`.

## Approval gates (never skipped)

1. **Contract** — you approve `contract.md` before any code.
2. **Tests** — under TDD, you approve the failing tests before production code.
3. **PR** — you review and merge.

For a small scoped change with an obvious cause, use `/fix` instead — it skips the
spec/contract/orchestration but keeps the full Definition of Done.
