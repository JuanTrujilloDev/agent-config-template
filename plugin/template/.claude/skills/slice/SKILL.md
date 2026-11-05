---
name: slice
description: "Brief the next slice of an approved epic: one layer of one capability group, its stories, seams, fixtures, expected behaviour and tests table. Writes docs/epics/<ID>/slices/<n>.md after the user's yes."
argument-hint: "<ID> [n]"
disable-model-invocation: true
---

# /slice

One slice = one layer of one capability group, one branch, one PR. Input: `docs/epics/<ID>/epic.md` (run `/epic` first if it is missing).

## 1. Pick the slice

- With `n`: that Technical task row.
- Without: the first row whose slice file is missing or not `Status: done`, in `db → be → fe` order within its capability group. One slice in progress per group; different groups may run in parallel threads.
- If the row covers more than 5 stories, or would clearly exceed the PR cap in `.claude/rules/principles.md` (Micro-PR Discipline), propose a split before briefing.

## 2. Ground it in the code

Use the `code-query` skill to find the seam each story is tested through (the highest public one: HTTP endpoint, public function, component), the fixtures and factories that already exist, and the code the slice will change. Run the patterns protocol (`patterns` skill): name the force for any new abstraction or write `no pattern — <reason>`.

## 3. Brief

Show the brief in the reply as one table plus the draft file:

| Story | TS | Seam | Fixtures | Test name |
| --- | --- | --- | --- | --- |
| S1 | TS1 | `GET /auth/sso/callback` | `company_factory(verified=True)` | `test_S1_verified_domain_callback_creates_session` |

Then the slice file:

```markdown
<!-- source=<local|tracker>; ... same header rule as the epic -->
# Slice <n> — <layer>: <name>

- Layer: <db|be|fe> (<what kind of code>)
- Capability group: <group>
- Stories covered: S1, S2
- Branch: `feature/<ID>-<group>-<layer>`
- Status: todo

## Expected behaviour
What the code does after this slice, in 2–5 sentences, with the literal values from the TS lines.

## Tests
- `test_S1_<case>` → TS1
```

Rules:

- Stack the branch on the previous layer's branch while its PR is open: write `- Branch: `feature/<ID>-<group>-be` (stacked on `feature/<ID>-<group>-db`)`.
- No file paths, no file lists and no MR links in the card or the slice body; the code-query findings stay in the reply.
- Ask only about granularity (split or merge?) and story coverage (anything missing?). Stop for the user's yes.

## 4. After yes

- Write `docs/epics/<ID>/slices/<n>.md`. If the epic lives on a tracker and the brief changed the sub-issue, update its body, then `/epic render <ID>` instead of editing the file.
- Create the branch from the line above (from the stacked base, else the default branch).
- Run `python3 .claude/skills/epic/validate-epics.py docs/epics/<ID>`.
- Next: `tests-first`. It appends `## Approved tests` once the user approves the tests; that section and the `- Branch:` line drive the approved-tests lock.
