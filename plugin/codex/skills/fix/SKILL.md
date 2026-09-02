---
name: fix
description: "Fast path for a small scoped change with an obvious cause — skips the spec and Design First, keeps the full Definition of Done."
---

# /fix

> **On Codex (no subagents):** you play every role yourself, switching hats
> explicitly and in sequence — `pmo` (spec/contract), the dev specialist
> (implement), `judge` (review), `security-reviewer` (when auth/permissions/
> data are touched). Same artifacts under `docs/specs/<slug>/`, same human
> gates (contract approval; failing tests under TDD), same Definition of Done.
> Announce each hat switch in one line.


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

1. **Reproduce red first.** Obtain a red-capable reproduction — a failing test or a command that fails for *this* bug and goes green only when fixed — before naming the cause.

   If you cannot get a reproduction in one step, stop and switch to `/feature`. Write 2–4 ranked falsifiable hypotheses only when the reproduction does not single out a cause, and test them one variable at a time.
2. **State the root cause** in a sentence or two, plus 2–4 verifiable success criteria. No separate brief/plan docs.
3. **Check out a typed branch** — `fix/<slug>` (or `hotfix/<slug>` for urgent prod). Never edit on a protected branch.
4. **Implement** the scoped change, surgically — the diff traces 1:1 to the success criteria.
5. **Run the full Definition of Done:** your project's format → lint → test commands, then spawn `judge` (and `security-reviewer` if the fix touches auth/permissions/data).
6. **Offer one optional manual check** matched to the project type: web app → browser walk; library/CLI or desktop → run the CLI/app; mobile → simulator; anything else → artifact/screenshot review. Never make it a gate. When this fix has a `features.json` entry, record `verified_by_human`: `yes` when verified, `no` when explicitly declined, `skipped` when the user says skip or does not answer; freeform fixes only make the offer.
7. **Commit / open the PR** on the typed branch.

## Guardrails

- If the change grows past a small scoped edit, **stop and switch to `/feature`** and do the brief + Design First properly.
- `/fix` skips Design First, not the Definition of Done. Review is never optional.
