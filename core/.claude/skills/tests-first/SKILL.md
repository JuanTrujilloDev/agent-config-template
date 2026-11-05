---
name: tests-first
description: "Write every test for the current slice's stories through the public seam, run them red, commit them, and stop for the user to read and approve them. After the yes, record the approved paths so they are locked. Adapted from mattpocock/skills tdd (MIT)."
argument-hint: "[<ID> <n>]"
disable-model-invocation: true
---

# tests-first

Input: the slice file `docs/epics/<ID>/slices/<n>.md` (the current branch's slice when no argument is given) and the TS lines of its stories in `docs/epics/<ID>/epic.md`. Read `docs/CONTEXT.md` when it exists so test names match the domain language.

## What a good test is

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists, and it survives refactors because it doesn't care about internal structure.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Seams: where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at pre-agreed seams.** The slice brief's table names the seam per story; the user approved it with the slice. No test is written at a seam the brief does not name. If a story needs a seam the brief lacks, stop and ask before writing it.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: here, the literal values in the TS line.

## The slice's tests, then one red run

The stories were already cut to one case each and the seams agreed, so the usual objection to writing tests in bulk (testing imagined behavior) does not apply: write **all** tests for this slice's stories, then run them once.

1. Check the branch matches the slice's `- Branch:` line; check it out if not.
2. One test per TS line the slice covers, named `test_S<n>_<case>` exactly as in the slice's `## Tests` list. Given = fixtures, When = one call through the seam, Then = assertions on the TS literals.
3. Use the project's existing fixtures and factories; add a fixture only when none fits.
4. Run only these test files. Every test must fail for the right reason: the behavior is missing (404, assertion on the expected value, missing symbol), not a typo, an import error in the test itself or a broken fixture. Fix any test that fails for the wrong reason and rerun.
5. Commit the tests on the slice branch: `test(<scope>): add slice <n> tests for <ID>`.

## Gate

Reply with the test file paths, the command, and the red output pasted verbatim. Then **stop**: the user reads the test files and says yes or asks for changes. Do not write production code before the yes.

## After yes

Append to the slice file, one line per approved test file, plus the commit that holds them:

```markdown
## Approved tests
Commit: `<sha>`
- `tests/sso/test_callback.py`
```

Commit that edit. From now on the `agent-enforcement` hook blocks edits to these paths on this branch, and `code-review` fails when `git diff <sha> -- <paths>` is not empty. If a test turns out wrong later, stop and ask; the user unlocks with `AGENT_CONFIG_UNLOCK_TESTS=1` and approves the changed test again (new `Commit:` line).

Next: `implement`.
