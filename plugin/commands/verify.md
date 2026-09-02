---
description: Skeptical self-review of your own uncommitted diff — re-read the request, read every changed line, actually run it, fix what you find.
argument-hint: "[branch range]"
---

# /verify

A skeptical self-review of your **own** uncommitted work before you call it done. "Should work" is not a status — `/verify` is how you earn "done." Run it after implementing and before `judge` or the commit; for a `/fix`, it's the lightweight verification step.

This is the implementer checking its *own* diff. It complements `judge` (independent review afterward) and the Definition of Done — it doesn't replace either.

## Usage

```
/verify                       # review the current uncommitted diff
/verify main...HEAD   # review a branch range
```

## The pass

### 1. Did you do what was actually asked?
Re-read the original request — and the contract scenarios if there are any — the words, not your memory of them. Then cut the drift:

- Features nobody asked for → remove them.
- Adjacent code you "improved" that was already fine → revert it.
- A different (more interesting) problem solved instead of the one described → solve the right one.
- **Over-engineering** — for each new function, class, or dependency in the diff, ask: would a lower rung of the leverage ladder (`principles` skill) have covered it — existing code, stdlib, a native platform feature, an installed dependency? If yes, replace it. (Never trim security, validation, error handling, or accessibility to get smaller — that's negligence, not simplicity.)
- **Pattern ledger** — does each pattern in the diff appear in the spec's Design notes ledger (`pattern / force / rejected alternative`) with a present force? Would the simplest default (the `patterns` skill) — a plain function, if/dict, direct call — have done? If yes, use it.

The diff should trace 1:1 to the request and its success criteria. Anything that doesn't, justify in one line or drop.

### 2. Read the diff, line by line
Run `git diff` (or `git diff main...HEAD`) and read **every changed line** as if you're about to defend it in review:

- Logic that looks right but isn't — does it *actually* hold, or just pattern-match to something plausible?
- Edge cases: null, empty, boundary, the state that "never happens" until it happens in production.
- Dead code: imports, variables, functions you added and never used.
- Copy-paste seams, off-by-one errors, hardcoded values that should be config, loose `any` types that sidestep the checker.

### 3. What's missing?
- **Tests** — updated *and* run, not assumed. New behavior earns a new test.
- **Callers** — if you changed a signature, you owe every reference a check.
- **TODO / FIXME** you left behind — resolve it or name the debt out loud.
- **The sad path** — errors, timeouts, partial failures, not just the happy path.

### 4. Actually run it
Not "I'm confident." Run it:

- `your project's format command` and `your project's lint command` — clean.
- `your project's test command` — the whole suite, green (not just the tests you think are relevant).
- The real flow — exercise the feature (browser / CLI), and check the console and logs for errors you're tempted to wave off as "unrelated."

If you genuinely can't run something in this environment, **say so explicitly** — don't substitute confidence for verification.

### 5. Fix what you find, then re-review the fix
Don't just list problems — fix them. Then re-review the fixes with the same skepticism, because fixes introduce bugs. Loop until the success criteria actually pass.

## Output

A short verdict: what you checked, what you ran and its result, what you found and fixed, and anything you couldn't verify and why. If it's genuinely clean, say so plainly — a clean pass is a real outcome, not a failure to find something.

> Want a *second model's* eyes too? `judge`'s adversarial mode has an optional hook to route a review lens through an external CLI (e.g. Codex, Gemini) when you have one. `/verify` itself stays single-model and portable.
