# Epic → story → slice

How a feature moves through a project rendered by agent-config-template v0.11. The design and its decisions are in `docs/design/epic-story-slice.md`; this page is the short version.

## The loop

```
/epic <ID or ask>   → draft: capability groups, stories, AC, TS, slices   → you: "approve" or "change 3"
/slice <ID> <n>     → brief: stories, seams, fixtures, tests table         → you: "yes"
tests-first         → all the slice's tests, red run pasted, committed     → you read the tests: "yes"
implement           → code to green, Definition of Done pasted
code-review         → Standards + Spec axes, one fix round
/pr                 → base = previous layer branch while its PR is open
```

Everything runs in one thread. There is no coordinator agent and no dev subagent; `security-reviewer` and `ui-designer` are the only agents, and `council` is an opt-in single review round by three providers.

## Files

| File | Holds | Size guidance |
| --- | --- | --- |
| `docs/epics/<ID>/epic.md` | Request, Description, Capability groups, User Stories, Acceptance Criteria, Test Scenarios, Technical tasks, Estimate | ≤120 lines; one AC and one TS per story |
| `docs/epics/<ID>/slices/<n>.md` | Layer, capability group, stories covered, branch, status, expected behaviour, tests, approved tests | ≤60 lines; ≤5 stories |
| `docs/epics/archive/<slug>/` | pre-v0.11 `docs/specs/` folders, moved verbatim by `migrate.py` | never rendered |

The first line of every file says where the truth lives: `source=<tracker>` (rendered from cards by `/epic render <ID>`; edit the card, not the file), `source=local` (no tracker; the files are the truth) or `source=migrated`. A worked example is in `docs/epics/EXAMPLE/`.

`python3 .claude/skills/epic/validate-epics.py docs/epics` checks the grammar: unknown stories, missing sections or a missing `- Layer:` / `- Stories covered:` line exit 1; size guidance only warns. CI runs it on this repository.

## Stories and tests

- One case per story: one When per test scenario, literal values, no "etc.".
- `TSn` tests `Sn`; test names are `test_S<n>_<case>`, expected values are the TS literals.
- Tests go through the public seam the slice brief names; mock only at system boundaries (`tests-first/mocking.md`).

## Slices and branches

One slice = one layer of one capability group = one branch = one PR, in `db → be → fe` order: `feature/<ID>-<group>-db` → `-be` → `-fe`, each stacked on the previous while its PR is open. Aim for 200–400 non-test lines; the hard cap is the project's files/lines limit, and a slice that would exceed it is split.

## Approved tests are locked

After you approve the tests, `tests-first` appends to the slice file:

```markdown
## Approved tests
Commit: `<sha>`
- `tests/sso/test_callback.py`
```

From then on, on the branch named by the slice's `- Branch:` line:

- `agent-enforcement.sh` blocks Edit/Write on those paths (override `AGENT_CONFIG_UNLOCK_TESTS=1`, then approve the changed test again);
- `code-review` fails when `git diff <sha> -- <paths>` is not empty.

Codex has no hooks: there the lock is the `implement` instruction plus the `code-review` check.

## Small changes

`/fix` keeps the full Definition of Done without an epic: reproduce red first, fix, `code-review`. Anything that adds a model, migration or endpoint goes through `/epic`.

## Upgrading

`update-config` plans the re-render, prunes the dropped files you approve and runs `migrate.py`; see the v0.11 section of `docs/upgrade-guide.md`.
