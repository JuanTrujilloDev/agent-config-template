---
name: principles
description: The 8 always-loaded operating principles for coding tasks (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution, Micro-PR Discipline, Definition of Done, Conciseness, Branch Discipline). Reference these whenever starting any non-trivial coding task.
---

# Core Operating Principles

> Always-loaded. These principles apply to **every** coding task in this project. They are non-negotiable. When a request conflicts with a principle, surface the conflict and ask — do not silently override.

## 1. Think Before Coding

State your assumptions explicitly. If a request has multiple valid interpretations, ask before writing. No silent decisions on ambiguous requirements.

Before any implementation:
- Restate the goal in one sentence.
- List 2–4 verifiable success criteria.
- Surface tradeoffs when more than one approach exists.

## 2. Simplicity First (YAGNI)

Write the minimum code that solves the stated problem. **Nothing speculative.**

- No `*Service` classes "in case we need them later."
- No flexible options/parameters that have no current caller.
- No abstractions for hypothetical second use cases.
- Three similar lines beats a premature abstraction.
- Trust internal code and framework guarantees — only validate at system boundaries.

## 3. Surgical Changes

Touch only what the task requires.

- Don't refactor adjacent code.
- Don't reformat unrelated lines.
- Don't "clean up" things you didn't break.
- Match the file's existing style — even if you'd write it differently from scratch.
- Remove only the dependencies your changes created. Pre-existing dead code stays unless cleanup *is* the task.

## 4. Goal-Driven Execution

Define success criteria. Loop until verified.

For each task:
1. Write 2–4 verifiable checks (e.g., *"endpoint X returns 201 with the new record"*, *"`your project's test command` is green"*).
2. Implement.
3. Run the criteria.
4. Fix gaps.
5. Repeat until all criteria pass — *then* declare done.


## Design Patterns (when warranted)

Reach for a known design pattern **only when the problem genuinely matches one and it reduces complexity for a real, present need** — Strategy, Factory, Adapter, Repository, Observer, etc. Name it in the spec's Design notes with a one-line *why*. Never impose a pattern speculatively: a pattern with no present second caller or real variation is YAGNI (see Principle 2, and the `backend-dev` gotcha about wrapping a single call site in a `*Service` class).

## Spec-Driven & Test-First (when invoked)

For non-trivial features, prefer the spec-driven flow (`/spec` → `/feature`): an approved Given/When/Then contract **before** code, one mini-feature at a time, optionally test-first. See the `sdd-workflow` skill. For a small scoped change with an obvious cause, `/fix` is the right tool — skip the ceremony, keep the Definition of Done.

## Micro-PR Discipline

Every PR must stay under both limits:
- **≤12 files changed**
- **<3000 lines changed**

If a feature won't fit, the `pmo` agent breaks it into sequential mini-features, each its own PR. Bigger ≠ better; smaller PRs review faster, merge cleaner, and roll back safely.

## Definition of Done

A coding task is **NOT** complete until all of these pass, in order:

1. **Format** — `your project's format command`
2. **Lint** — `your project's lint command` (zero new warnings)
3. **Unit tests** — `your project's test command` green, ≥80% coverage maintained
4. **Code review** — a `judge` review of the change (the main conversation spawns it); address all blockers it flags.
5. **Security review** — Spawn `security-reviewer` if change touches authentication, permissions, data exposure, or external input boundaries.
6. **Live browser verification** — For any change under `src/frontend` OR diff exceeding 5 files / 500 lines: use `mcp__playwright__*` tools to walk through the user flow described in success criteria and confirm it works end-to-end.

Skipping any step = the task is open. The agent that did the work is responsible for running the checklist and reporting results before declaring done.

## Conciseness

Be brief. Default to short answers and summaries. No filler ("Great question!", "Let me explain...", "I hope this helps!"). No restating the user's question. No unsolicited recap of what you just did when the diff/output already shows it.

- Match length to need: yes/no questions get yes/no; one-line tasks get one-line answers.
- Skip preambles. Lead with the answer or the action.
- Lists only when there are 3+ items. Tables only when comparing.
- Code blocks only for code or terminal output.
- For multi-step work: progress note → result. Not progress note → recap → next-steps → meta-commentary.
- After a tool call, summarize only what's NOT already visible in the tool output.

## Branch Discipline

**Never code on `main`.** Every change starts with a checkout to a typed branch:

| Type | Pattern | Example |
|---|---|---|
| Feature | `feature/<kebab-name>` | `feature/csv-export` |
| Fix | `fix/<kebab-name>` | `fix/login-redirect` |
| Hotfix (urgent prod) | `hotfix/<kebab-name>` (branches from `main`) | `hotfix/login-500` |
| Refactor | `refactor/<kebab-name>` | `refactor/consolidate-auth` |
| Chore (tooling/config/deps) | `chore/<kebab-name>` | `chore/upgrade-deps` |
| Docs only | `docs/<kebab-name>` | `docs/api-overview` |

Before any code edit, confirm the current branch matches the task type. If on `main`, check out a properly-named branch first.
