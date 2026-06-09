---
description: "Full spec-driven flow for a feature: approved contract, optional TDD, implement, judge review, micro-commit — one mini-feature at a time."
argument-hint: "<ticket or description>"
---

# /feature

Full **spec-driven** flow for a feature — from signed contract to merged
mini-features — coordinated by the `orchestrator` agent. It pauses at every gate
and never skips ahead.

## Usage

```
/feature <description>             # freeform, e.g. /feature "add CSV export"
```

## What it does

**You (the main conversation) are the orchestrator.** Claude Code subagents
cannot spawn other subagents, so never delegate the coordination itself —
read the `orchestrator` agent file (the playbook) and the `sdd-workflow` skill,
then run the pipeline from this conversation, chaining one subagent at a time:

### 1. Spec + contract
If there's no approved contract for this work, spawn `pmo`
(or run `/spec` first). Output: `docs/specs/<slug>/{spec.md, contract.md, features.json}`.
**Gate 1 — you approve `contract.md` before any code is written.**

### 2. Per mini-feature (one at a time)
- Set `in_progress`; check out the typed branch (never `the default branch`).
- **Apply TDD?** If yes, the implementer writes the failing tests first → **Gate 2: you approve the tests** before production code.
- Spawn `backend-dev` / `frontend-dev` / `ui-designer` to implement to green, honoring the Design-notes pattern.
- Spawn `judge` — reviews code **and** tests against the contract scenarios.
- Spawn `security-reviewer` if the mini-feature touches auth, permissions, or data.
- Micro-commit on the typed branch; mark `done`.

## Approval gates (never skipped)

1. **Contract** — you approve `contract.md` before any code.
2. **Tests** — under TDD, you approve the failing tests before production code.
3. **PR** — you review and merge.

For a small scoped change with an obvious cause, use `/fix` instead — it skips the
spec/contract/orchestration but keeps the full Definition of Done.
