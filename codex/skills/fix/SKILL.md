---
name: fix
description: Small, scoped change with an obvious cause — skip the spec and Design First, keep the full Definition of Done.
---

# /fix

Fast path for a small, scoped change with an obvious root cause. Skips the
brief, the plan, and the formal Design First artifact — but keeps the full
Definition of Done.

Use `/fix` for genuinely small changes with a clear cause. For anything that
adds a model, migration, or endpoint — or that you can't scope in a sentence —
use `/feature`.

## Usage

```
/agent-config-template:fix <description>
```

## What it does

1. **State the root cause** in a sentence or two, plus 2–4 verifiable success criteria. No separate brief/plan docs.
2. **Check out a typed branch** — `fix/<slug>` (or `hotfix/<slug>` for urgent prod). Never edit on a protected branch.
3. **Implement** the scoped change, surgically — the diff traces 1:1 to the success criteria.
4. **Run the full Definition of Done:** your project's format → lint → test commands, then spawn `code-reviewer` (and `security-reviewer` if the fix touches auth/permissions/data).
5. **Commit / open the PR** on the typed branch.

## Guardrails

- If the change grows past a small scoped edit, **stop and switch to `/feature`** and do the brief + Design First properly.
- `/fix` skips Design First, not the Definition of Done. Review is never optional.
