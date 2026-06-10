---
description: Fast path for a small scoped change with an obvious cause — skips the spec and Design First, keeps the full Definition of Done.
argument-hint: "<description>"
---

# /fix

Fast path for a small, scoped change with an obvious root cause. Skips the
brief, the plan, and the formal Design First artifact — but keeps the full
Definition of Done.

Use `/fix` when the change is genuinely small and the cause is clear. For
anything that adds a model, migration, or endpoint — or that you can't scope in
a sentence — use `/feature` instead.

## Usage

```
/fix <description>
```

{{#branch_prefix}}
For a tracked fix, reference the ticket: `/fix {{branch_prefix}}-<#>` — e.g. `/fix {{branch_prefix}}-104`.

{{/branch_prefix}}
## What it does

1. **State the root cause** in a sentence or two, plus 2–4 verifiable success criteria. No separate brief/plan docs.
2. **Check out a typed branch** — `fix/{{#branch_prefix}}{{branch_prefix}}-<#>-{{/branch_prefix}}<slug>` (or `hotfix/<slug>` for urgent prod). Never on `{{default_branch}}`.
3. **Implement** the scoped change. Stay surgical — the diff traces 1:1 to the success criteria.
4. **Run the full Definition of Done** (no shortcuts here):
   - `{{format_cmd}}` → `{{lint_cmd}}` → `{{test_cmd}}`
   - Spawn `judge` — address all blockers
   - Spawn `security-reviewer` if the fix touches auth/permissions/data
5. **Commit / open the PR** on the typed branch.

## Guardrails

- If the change grows past a small scoped edit — a new model/migration/endpoint, or it stops tracing to the stated cause — **stop and switch to `/feature`** and do the brief + Design First properly.
- `/fix` skips Design First, not the Definition of Done. Review is never optional.
