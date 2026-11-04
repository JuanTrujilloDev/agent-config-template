# ABC-0000: <task title>

- {{tracker}} id: `<card id>`
- Project repo: `<project repo path>`
- Base branch: `main`
- Orchestrator thread: `<T3 thread id>`
- State file: `state/ABC-0000.yaml` (live status lives there, not in this file)
- History: `plans/ABC-0000/history.md` (superseded sections move there in the same update that supersedes them)
- Plan status: `draft | approved | executing | reviewing | done`
- Created: <date>. Approved by {{approver}}: <date or pending>.

## Current

One short block, rewritten in place when anything changes: what is true now, the next ready step, open blockers, pending approvals. Nothing historical stays here.

## Research summary

Key findings from the research stage, with sources. Link to the learnings and flake-registry entries consulted.

## Security invariants

Statements the project must keep true after this work, written by the planner from the research, the project learnings and earlier reviews. The security review checks each one.

| ID | Invariant | Guard test (path or planned) | Added by Task | Status |
| --- | --- | --- | --- | --- |
| SI-1 | <invariant> | <test path or planned> | 1.1 | planned |

## Epics

### Epic 1: <name>

- Goal: one sentence.
- Review at end of epic: see the review matrix below.
- Epic status: `queued | executing | in review | done`.

| # | Task | Owner model | State | Worktree / branch | Thread or task ID | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 1.1 | <task> | <model> <effort> | queued | | | |

## Parallelism

- Tasks that may run in parallel worktrees and why the merge is safe (disjoint files or modules).
- Tasks that must be sequential and why.
- Shared files (migrations, locale catalogs) and who owns them.

### Review parallelism

Classes: `remote` (reads code, hosted model only), `local-suite` (re-runs suites or builds), `browser` (drives a browser). Everything in a group is dispatched at the same time on the same frozen range.

| Epic | Review | Model and skill | Class | Group |
| --- | --- | --- | --- | --- |
| 1 | <review> | <model>, `<skill>` | remote | 1 |

## Review log

- Epic 1 review: <run id>, verdict, decisions taken.
- Fix rounds: batched findings, range re-checked, by whom.

## Learnings

- Pointers to entries written in `learnings/`, `flakes/` and the project's `CLAUDE.md` after each epic.
