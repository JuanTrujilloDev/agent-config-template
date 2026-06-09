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

Spawns `orchestrator`, which runs the pipeline in `docs/sdd-workflow.md`:

### 1. Spec + contract
If there's no approved contract for this work, the orchestrator spawns `pmo`
(or run `/spec` first). Output: `docs/specs/<slug>/{spec.md, contract.md, features.json}`.
**Gate 1 — you approve `contract.md` before any code is written.**

### 2. Per mini-feature (one at a time)
- Set `in_progress`; check out the typed branch (never `{{default_branch}}`).
- **Apply TDD?** If yes, the implementer writes the failing tests first → **Gate 2: you approve the tests** before production code.
- Spawn `backend-dev`{{#has_frontend}} / `frontend-dev` / `ui-designer`{{/has_frontend}} to implement to green, honoring the Design-notes pattern.
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
