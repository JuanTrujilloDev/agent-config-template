---
name: implement
description: "Implement the current slice to green against its approved tests, in this thread: load the layer's style skill, never edit approved tests, paste the Definition of Done outputs, then run code-review and commit."
argument-hint: "[<ID> <n>]"
disable-model-invocation: true
---

# implement

Input: the slice file `docs/epics/<ID>/slices/<n>.md` (the current branch's slice when no argument is given) with a non-empty `## Approved tests` section. No approved tests yet: run `tests-first` first.

1. **Load context.** Read the slice file, its stories and TS lines in `epic.md`, and every approved test file. Load the style skill for the layer: `backend-style` for `db` and `be`, `frontend-style` for `fe`.
2. **Check the branch** against the slice's `- Branch:` line.
3. **Read before you write.** For each file you will change, read it end to end and check its callers (`code-query` skill: graph first, grep second).
4. **Implement to green.** Minimum code for the approved tests and the slice's Expected behaviour; follow the slice's pattern decision (`patterns` skill). Run the single test file often, typecheck when the project has one.
5. **Never edit an approved test.** If one looks wrong or cannot pass without changing it, stop and ask; do not work around it (no skips, no xfail, no weakened fixture). The hook blocks the edit anyway.
6. **Definition of Done** (`.claude/rules/principles.md`), in order, pasting each command and its output: format, lint, the slice's test files, then the full suite with coverage.
7. **Review.** Run `code-review` against the slice's base branch, fix its blockers in one round, rerun the suite.
8. **Commit** on the slice branch (`feat(<scope>): <slice name> (<ID> slice <n>)`) and set `- Status: done` in the slice file (or on the sub-issue, then `/epic render <ID>`). Push and `/pr` stay gated: ask first.
