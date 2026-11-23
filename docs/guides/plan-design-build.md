# Plan, design, build: the v0.13 flow

How a feature with several layers or a UI goes from an ask to merged slices. Each step names what
runs, what you get and what you approve. The worked example is the `EXAMPLE` epic (company SSO
login); every file named below exists in this repository.

| # | Step | Runs | You get | You approve |
| --- | --- | --- | --- | --- |
| 1 | Flows | `scope-page` | the scope markdown and a page that walks each user flow, one screen per step | the flows |
| 2 | Design | `architect <design folder>` | `design.md`: three providers' full designs, consolidated, interrogated | the design, in a `Round N decisions` block |
| 3 | Plan | `scope-page` (add `plan`) | the slices per flow on the page and a Plan checklist, every slice `todo` | nothing new: it is the design's slices |
| 4 | Epic | `/epic` | `docs/epics/<ID>/epic.md`, citing the design; Technical tasks = its slices | the epic |
| 5 | Slice | `/slice <ID> <n>` | the slice file with `## Placement` and `## Last-resort error handling` | the slice, and any last-resort try |
| 6 | Tests | `tests-first` | the tests, red; the Complexity rows as tests; progress `tests approved` | the tests (then locked) |
| 7 | Code | `implement` → `code-review` | code to green, a deslop pass, the verifier clean, progress `review` | the PR |

## 1. Flows

The scope holds user flows only, no slices. Each flow is a story walked step by step on real
screens (or drawn ones, marked as drawn). Example: the three flows in
[content.mjs](../epics/EXAMPLE/design/_build/content.mjs) before its `plan` export existed.

## 2. Design on three models

`architect` gives Claude, Codex and Cursor the same inputs (the approved scope, the
[architecture map](../../core/.claude/rules/architecture-map.md), the code-query findings, the
[design template](../../core/.claude/skills/architect/design-template.md)). Each writes the whole
design; its brief stresses its lead area (frontend and design, backend, security). The epic's own
thread consolidates once, lists the real disagreements with a pick, then checks every claim by
running something. Example: [design.md](../epics/EXAMPLE/design/design.md):

- **Interrogation**: 23 claims checked; a duplicated field, a per-request query and a sweep that
  loaded every row were caught and fixed before the reviewer saw the design.
- **Complexity**: what n is, time, queries, memory and outside calls per piece, each with the test
  that keeps it true.
- **Last-resort error handling**: the one try the design cannot avoid, and why.
- **Round 1 decisions**: the reviewer's answers and approval, in their words.

## 3. Plan and checklist

Only after the design is approved, `content.mjs` gains `plan`: the design's slices, each naming
the flow steps it builds. The page then shows "Built by" chips on every step, a flow → slices
diagram and the Plan checklist. Build it:

```bash
node core/.claude/skills/scope-page/build.mjs docs/epics/EXAMPLE/design/_build/content.mjs
open docs/epics/EXAMPLE/design/scope/index.html
```

In a project the skill lives at `.claude/skills/scope-page/` and the design folder outside the
repository.

## 4–5. Epic and slices

`/epic` reads the approved design: the Request cites it and the Technical tasks are its slices
([epic.md](../epics/EXAMPLE/epic.md)). `/slice` copies each piece's file into `## Placement` and
lists any approved last-resort try ([slice 2](../epics/EXAMPLE/slices/2.md)). File paths stay out
of the card.

## 6–7. Tests, code, review

`tests-first` writes the stories' tests and the Complexity tests, red. After your yes it writes
the slice's progress file (`tests approved`). `implement` goes to green, runs a deslop pass
(principles, Deslop), and `tools/verify_changed.py` checks the added lines: no new comment, no try
the slice does not list, no nested if, depth ≤2, the architecture map. `code-review` fails any
changed file outside Placement. `implement` writes progress `review` with the files to read; the
checklist shows them ([progress/2.json](../epics/EXAMPLE/design/_build/progress/2.json)). You read
those files, not the whole diff, and the box ticks itself when the slice is done.
