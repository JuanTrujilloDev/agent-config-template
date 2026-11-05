---
description: Fast path for a small scoped change with an obvious cause — skips the epic and Design First, keeps the full Definition of Done.
argument-hint: "<description>"
---

# /fix

Fast path for a small, scoped change with an obvious root cause. Skips the
brief, the plan, and the formal Design First artifact — but keeps the full
Definition of Done.

Use `/fix` when the change is genuinely small and the cause is clear. For
anything that adds a model, migration, or endpoint — or that you can't scope in
a sentence — use `/epic` instead.

## Usage

```
/fix <description>
```

## What it does

1. **Reproduce red first.** Obtain a red-capable reproduction — a failing test or a command that fails for *this* bug and goes green only when fixed — before naming the cause.

   If you cannot get a reproduction in one step, stop and switch to `/epic`. Write 2–4 ranked falsifiable hypotheses only when the reproduction does not single out a cause, and test them one variable at a time.
2. **State the root cause** in a sentence or two, plus 2–4 verifiable success criteria. No separate brief/plan docs.
3. **Check out a typed branch** — `fix/<slug>` (or `hotfix/<slug>` for urgent prod). Never on `main`.
4. **Implement** the scoped change. Stay surgical — the diff traces 1:1 to the success criteria.
5. **Run the full Definition of Done** (no shortcuts here):
   - `your project's format command` → `your project's lint command` → `your project's test command`
   - Run `code-review` — address all blockers
   - Spawn `security-reviewer` if the fix touches auth/permissions/data
6. **Offer one optional manual check** matched to `the project type`: `web-app` → browser walk; `library-cli` or `desktop-app` → run the CLI/app; `mobile-app` → simulator; anything else → artifact/screenshot review. Never make it a gate.
7. **Commit / open the PR** on the typed branch.

## Guardrails

- If the change grows past a small scoped edit — a new model/migration/endpoint, or it stops tracing to the stated cause — **stop and switch to `/epic`** and do the brief + Design First properly.
- `/fix` skips Design First, not the Definition of Done. Review is never optional.
