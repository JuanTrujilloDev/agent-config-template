# Agent operating rules

> Portable rules for any coding agent (Claude Code, Codex, OpenCode, Antigravity).
> This is the always-on baseline. The full capabilities — `spec`, `fix`, `verify`,
> `security-audit`, and the style guides — install as skills (see the README).

## Principles (non-negotiable)

1. **Think before coding.** State assumptions; if a request has multiple readings, ask before writing. Restate the goal and list 2–4 verifiable success criteria first.
2. **Simplicity first (YAGNI).** Write the minimum code that solves the stated problem. No speculative classes, options, or abstractions. Reach for a design pattern only when the problem genuinely matches one.
3. **Surgical changes.** Touch only what the task needs. No drive-by refactors or reformatting. Match the file's existing style.
4. **Goal-driven execution.** Define success criteria, implement, run them, fix gaps, repeat until they pass — then declare done.

## Spec-driven workflow (non-trivial features)

Prefer: idea → a conversed spec with a **Given/When/Then contract** you approve → implement **one PR-sized mini-feature at a time** → review (and, under TDD, write the failing tests first and approve them before code) → self-review → micro-commit. Use the `spec` then `feature` flow. For a small change with an obvious cause, use `fix` (skip the spec, keep the Definition of Done). Before declaring done, run `verify` — re-read the request, read the diff, and actually run it.

## Branch discipline

Never commit on a **protected branch** (e.g. `main`/`master`, or your environment branches). Start every change on a typed branch: `feature/…`, `fix/…`, `hotfix/…`, `refactor/…`, `chore/…`, `docs/…`.

## Definition of Done

Format → lint → tests green (coverage maintained) → code review → security review when the change touches auth, permissions, data, or external input → then done. Keep PRs small (≈ ≤12 files / <3000 lines); split if larger.

## Security baseline

Run the `security-audit` skill on anything touching auth, secrets, user data, or external input: no committed secrets, strong password hashing, parameterized queries, escaped output, security headers and cookie flags, rate limiting on sensitive endpoints, and no known-vulnerable dependencies.
