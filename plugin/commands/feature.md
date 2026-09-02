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
Before Gate 1, scan those artifacts for lines starting `NEEDS CLARIFICATION:`;
if any remain, list the unresolved questions and refuse implementation.
If `features.json` is unversioned or has an unknown/unsupported schema version,
refuse to continue and tell the user to run `python3 scripts/migrate-specs.py`.
**Gate 1 — you approve `contract.md` before any code is written.**

### 2. Per mini-feature (one at a time)
- Set `in_progress`; check out the typed branch (never `the default branch`).
- Read `agent_style` from `.claude/answers.local.env` once per run (absent = `terse`) and put one line — `agent_style: <terse|descriptive> — return per "Report format" in the principles skill` — in every subagent prompt (pmo, dev agents, ui-designer, judge, security-reviewer, mutation-tester).
- **Apply TDD?** If yes, the implementer writes the failing tests first → **Gate 2: you approve the tests** before production code.
- Spawn the dev specialist that matches the project type (`backend-dev` web/API · `frontend-dev` web UI · `mobile-dev` · `game-dev` · `desktop-dev` · `core-dev` library/CLI/data), with `ui-designer` first for new UI; implement to green, honoring the Design-notes pattern and its **Leverage** subsection (reuse before writing — leverage ladder in the `principles` skill). For impact analysis before an edit, the `code-query` skill finds dependents cheaply.
- Spawn `judge` — reviews code **and** tests against the contract scenarios.
- Spawn `security-reviewer` if the mini-feature touches auth, permissions, or data.
- After the Definition of Done passes, offer exactly one optional manual check matched to the project type: web app → browser walk; library/CLI or desktop → run the CLI/app; mobile → simulator; anything else → artifact/screenshot review. This is never a gate and never delays the commit. Record `verified_by_human` in this mini-feature's `features.json` entry: `yes` when verified, `no` when explicitly declined, `skipped` when the user says skip or does not answer.
- Micro-commit on the typed branch; mark `done`.

## Approval gates (never skipped)

1. **Contract** — you approve `contract.md` before any code.
2. **Tests** — under TDD, you approve the failing tests before production code.
3. **PR** — you review and merge.

For a small scoped change with an obvious cause, use `/fix` instead — it skips the
spec/contract/orchestration but keeps the full Definition of Done.

A template upgrade (`setup.sh --merge`) is its own `chore:` commit — never mixed into a feature PR.
