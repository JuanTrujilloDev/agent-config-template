---
name: slice
description: "Brief the next slice of an approved epic: one layer of one capability group, its stories, seams, fixtures, expected behaviour and tests table. Optional cold review by two fresh reviewers before the yes. Writes docs/epics/<ID>/slices/<n>.md after the user's yes. Cold-review prompts adapted from google/elephant-goldfish-model (Apache-2.0)."
argument-hint: "<ID> [n] [cold-review]"
disable-model-invocation: true
---

# /slice

> **On Codex (no subagents):** run every step in this thread, in sequence.
> `code-review` runs its Standards axis, then its Spec axis, and reports them
> separately; `security-reviewer` becomes a read-only pass you announce in one
> line. Same files under `docs/epics/<ID>/`, same user gates (epic draft, slice
> brief, approved tests), same Definition of Done.


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
- Ask only about granularity (split or merge?) and story coverage (anything missing?). With `cold-review`, run step 4 first. Stop for the user's yes.

## 4. Cold review (only with `cold-review`)

Off by default. Run it when the arguments or the request say `cold-review`: two reviewers who never saw this thread read the slice before the user does. One round, no loop.

1. Write the draft to `docs/epics/<ID>/slices/<n>.md`, uncommitted (delete it if the user drops the slice).
2. Start two fresh sub-agents in parallel with the prompts in [cold-review.md](cold-review.md): **Comprehension** writes what it thinks will be built; **Readiness** lists what a developer would have to guess. Give each only its prompt and three inputs: `docs/epics/<ID>/epic.md`, the slice file, the repo. Nothing from the conversation: no brief table, no code-query findings, no summary of what you meant.
3. Model: Claude Sonnet 5.5 with `effort: medium` set explicitly (it defaults to `high`), a different model from the author on purpose. Cost: roughly 0.2–0.4M tokens per round (an estimate).
4. Hosts without sub-agents (Codex) run Comprehension, then Readiness, one after the other in this thread, each starting from the three inputs only and not from the brief; say the review is weaker for it.
5. In the reply, under the brief (not in the slice file), add `## Cold review`: Comprehension's paraphrase, then one short findings list from both. A paraphrase that differs from what you meant is a finding. Per finding, fix the draft or answer it in one line. The user reads it with the slice.

## 5. After yes

- Write `docs/epics/<ID>/slices/<n>.md` (or keep the cold-review draft). If the epic lives on a tracker and the brief changed the sub-issue, update its body, then `/epic render <ID>` instead of editing the file.
- Create the branch from the line above (from the stacked base, else the default branch).
- Run `python3 .claude/skills/epic/validate-epics.py docs/epics/<ID>`.
- Next: `tests-first`. It appends `## Approved tests` once the user approves the tests; that section and the `- Branch:` line drive the approved-tests lock.
