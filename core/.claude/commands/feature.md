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
{{#branch_prefix}}/feature {{branch_prefix}}-<#>     # tracked, e.g. /feature {{branch_prefix}}-87
{{/branch_prefix}}/feature <description>             # freeform, e.g. /feature "add CSV export"
```

## What it does

**You (the main conversation) are the orchestrator.** Claude Code subagents
cannot spawn other subagents, so never delegate the coordination itself —
read `.claude/agents/orchestrator.md` (the playbook) and `docs/sdd-workflow.md`,
then run the pipeline from this conversation, chaining one subagent at a time:

### 1. Spec + contract
If there's no approved contract for this work, spawn `pmo`
(or run `/spec` first). Output: `docs/specs/<slug>/{spec.md, contract.md, features.json}`.
**Gate 1 — you approve `contract.md` before any code is written.**

### 2. Per mini-feature (one at a time)
- Set `in_progress`; check out the typed branch (never `{{default_branch}}`).
{{#workflow_tdd}}
- **TDD is on by default** (project policy: `workflow_mode=SDD+TDD`): the implementer writes the failing tests first → **Gate 2: you approve the tests** before production code — applied per mini-feature, skippable per mini-feature on request ("skip TDD").
{{/workflow_tdd}}
{{^workflow_tdd}}
- **TDD is off by default** and available on request ("with TDD"): if opted in for this mini-feature, the implementer writes the failing tests first → **Gate 2: you approve the tests** before production code.
{{/workflow_tdd}}
- Spawn `{{primary_dev_agent}}`{{#has_frontend}} / `frontend-dev`{{/has_frontend}}{{#has_ui}} (with `ui-designer` first for new UI){{/has_ui}} to implement to green, honoring the Design-notes pattern and its **Leverage** subsection (reuse before writing — leverage ladder in `.claude/rules/principles.md`). For impact analysis before an edit, `.claude/rules/code-query.md` finds dependents cheaply.
- Spawn `judge` — reviews code **and** tests against the contract scenarios.
- Spawn `security-reviewer` if the mini-feature touches auth, permissions, or data.{{#enforce_mutation_testing}}
- Spawn `mutation-tester`; only a passing mutation score closes the mini-feature.{{/enforce_mutation_testing}}
- Micro-commit on the typed branch; mark `done`.
{{#enforce_layer_split}}

### 3. Layer order
BE mini-features ship (and merge) before their FE counterparts.
{{/enforce_layer_split}}

## Approval gates (never skipped)

1. **Contract** — you approve `contract.md` before any code.
2. **Tests** — under TDD, you approve the failing tests before production code.
3. **PR** — you review and merge.

For a small scoped change with an obvious cause, use `/fix` instead — it skips the
spec/contract/orchestration but keeps the full Definition of Done.
