---
name: sdd-workflow
description: The spec-driven (SDD) + optional TDD workflow — task to conversed spec to Given/When/Then contract to human gate to implementation to judge review. Reference when running /spec or /feature or orchestrating a multi-step feature.
---

# The SDD + TDD workflow

How a task becomes shipped code in this config. Spec-driven, one mini-feature at
a time, with the human approving an executable contract **before** any
production code. Inspired by Robert C. Martin's harness — conversation → contract
→ TDD → judgment — adapted to be **invoked, not forced**: you opt in via
`/feature` or `/spec`. For a small scoped change with an obvious cause, skip all
of this and use `/fix`.


> **Who is "the orchestrator"?** A role, not a subagent. On Codex there are no
> subagents: **you** play every role in sequence — orchestrator, `pmo`, dev
> specialist, `judge`, `security-reviewer` — switching hats explicitly (announce
> the switch in one line). Same artifacts on disk, same human gates.

## The pipeline

```
task in  (tracker ticket or freeform description)
  │
  ├─ [pmo]  CONVERSE  ───────────────►  docs/specs/<slug>/spec.md
  │     debate decisions, record the *why*, write Design notes
  │
  ├─ [pmo]  DISTILL   ───────────────►  docs/specs/<slug>/contract.md
  │     one Given/When/Then block per mini-feature  (@s1, @s2, …)
  │
  ├─ [pmo]  SCOPE     ───────────────►  docs/specs/<slug>/features.json
  │     mini-features, each ≤ micro-PR limits, status: pending
  │
  ▼  ⏸  GATE 1 (human): approve the contract — the point of max leverage
  │
in_progress  (per mini-feature, one at a time)
  │
  ├─ ⏸  GATE 2 (human, ONLY under TDD): implementer writes the failing
  │      tests first; you approve the tests before any production code
  │
  ├─ [dev specialist for the stack | ui-designer]  implement to green
  │     (backend-dev/frontend-dev for web · mobile-dev · game-dev · desktop-dev · core-dev)
  ├─ [judge]              review code AND tests against the contract
  ├─ [security-reviewer]  when auth / permissions / data are touched
  ├─ [mutation-tester]    only if `enforce_mutation_testing` is on
  ├─ [human]              one optional project-matched verification offer
  │
  ▼  micro-commit on the typed branch; mark the mini-feature `done`
done  (when every mini-feature is done)
```

**One mini-feature at a time. Two gates: the contract (always), the tests (only
under TDD). State lives on disk, not in chat.**

## Who writes what (state on disk)

| File | Written by | Holds |
|---|---|---|
| `docs/specs/<slug>/spec.md` | `pmo` | Problem, goal, verifiable success criteria, decisions + *why*, out-of-scope, open questions, **Design notes** |
| `docs/specs/<slug>/contract.md` | `pmo` | Given/When/Then acceptance scenarios — the signed contract (or `.feature` files if Gherkin is enabled) |
| `docs/CONTEXT.md` | `pmo` | Project glossary, created lazily on the first coined project term: `**Term** — what it IS (1–2 sentences). Avoid: <synonyms>` |
| `docs/specs/<slug>/features.json` | `orchestrator` / `pmo` | Mini-feature list + state machine: `pending → spec_ready → in_progress → done / blocked` |
| `docs/specs/<slug>/progress/<feature>.tdd.md` | implementer | Red→Green→Refactor log + `scenario → test` map (TDD on) |
| `docs/specs/<slug>/progress/<feature>.judge.md` | `judge` | Review verdict + blockers/nits |
| `docs/specs/<slug>/progress/<feature>.mutation.md` | `mutation-tester` | Mutation score + survivors (when enabled) |

## Contract grammar

- `spec.md` separates numbered functional requirements (`FR-###`) from
  technology-agnostic, measurable success criteria (`SC-###`). Every contract
  scenario cites at least one defined `FR-###` and one defined `SC-###`.
- Put each unresolved question on its own line as
  `NEEDS CLARIFICATION: <question>`. Gate 1 stays closed while any marker
  remains; the orchestrator lists the questions instead of implementing.

## The gates

- **Gate 1 — the contract.** The cheapest place to fix ambiguity is before code
  exists. The orchestrator stops here and waits for an explicit approval of
  `contract.md`. A wrong scenario drags the whole implementation.
- **Gate 2 — the tests (TDD only).** When the user opts into TDD for a
  mini-feature, the implementer writes the failing tests first and stops for
  approval. Production code starts only after the tests are signed off.

## The anti-telephone rule

When the orchestrator launches a subagent, it instructs that subagent to **write
its output to a file** under `docs/specs/<slug>/` and return only a one-line
reference. Content lives on disk and survives restarts and blown context windows;
it does not get paraphrased through chat.

## Skill taxonomy

- **Commands** (`/spec`, `/feature`, `/fix`, …) are **user-invoked**: a person types them. On Cursor they render with `disable-model-invocation: true` so the model cannot fire them.
- **Rules and skills** (`principles`, `patterns`, `code-query`, `sdd-workflow`) are **model-invoked**: loaded as reference when the task matches.
- A command may **suggest** another command to the user ("for a small change, use `/fix`") but never instructs the model to invoke one — user-invoked may call model-invoked, never another user-invoked.

## How it relates to the rest of the config

- **`/fix`** is the escape hatch for small scoped changes — no spec, no
  contract, no orchestrator. Just the typed branch + the full Definition of Done.
- **Design notes** in the spec name a design pattern when the problem genuinely
  warrants one (Strategy, Factory, Adapter, Repository, …) — never speculatively.
  The implementer treats the named pattern as part of the contract. They also
  carry a **Leverage** subsection: per mini-feature, what existing code /
  stdlib / native platform / installed dependency covers it (leverage ladder,
  `principles` skill) — so the implementer reuses instead of rewriting.
- **Structural questions** during CONVERSE, SCOPE, and implementation (what
  exists, what depends on what, how are A and B connected) go through the
  `code-query` skill — a codebase knowledge graph when one is available
  (e.g. graphify), a deterministic repo map otherwise. Graph first, grep second;
  Read Before You Write still applies to everything you edit.
- **Definition of Done** still applies to every mini-feature (format → lint →
  tests → `judge` → `security-reviewer` when relevant).
- **Manual verification is an offer, not a gate.** After the Definition of Done,
  offer one project-matched check and record `verified_by_human` as
  `yes|no|skipped` when a `features.json` entry exists.
- **Mutation testing** (`enforce_mutation_testing`, off by default) adds a final
  gate per mini-feature: defects are injected and a test must fail, proving the
  tests bite.
