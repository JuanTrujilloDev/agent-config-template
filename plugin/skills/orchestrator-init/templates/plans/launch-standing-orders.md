# Launch standing orders

Paste this block, unchanged, at the end of every task-thread launch message, after the task, the branch and the previous report (if any). {{approver}} is the owner below.

```text
Standing orders:
1. `/slice` is step 1: brief it from the approved epic before any code. If the slice file already exists, read it instead.
2. Read this repo's own rules first (AGENTS.md, CLAUDE.md, CONTRIBUTING, .cursor/rules, style skills) and follow them for branch name, commit style and tests. Do not read the orchestrator folder.
3. Tests first: write the slice's tests, run them, commit them and push them red (the push waits for {{approver}}'s approval), then stop and report to {{approver}}. Implement only after {{approver}} says yes. "Continue" from {{approver}} counts as yes to the tests.
4. Never write `approved_by` in any file; only {{approver}} approves.
5. Never delete a branch, never commit to or push the default branch, never merge. Work only on your own branch.
6. Before a rebase or review-fix round, re-read the MR/PR state (comments, approvals, pipeline, target-branch head); do not trust the launch message's copy.
7. End every turn that leaves a commit with: "commit done, push pending approval".
```

For a v0.13 repo (AGENTS.md "Which flow"), also paste the one block below that fits, with `<design folder>` filled in (an absolute path outside the repo). A slice launch takes "Slice gates"; an epic launch takes "Epic orders" in place of steps 1 and 3 above, or "High-level orders" when the task's owner is not {{approver}}.

```text
Slice gates. Design folder: <design folder>.
- Step 1: the slice file also has `## Placement` (from design.md) and `## Last-resort error handling`; {{approver}} approves any try with the slice.
- Step 3: after {{approver}}'s yes to the tests, write <design folder>/_build/progress/<n>.json with status `tests approved` and rebuild the page (scope-page skill).
- Before the hand-back: quote `python3 tools/verify_changed.py --base <target branch>` and the code-review Placement gate, and set the progress file to `review` with the files to read.
- If you cannot write in the design folder, print the progress JSON in your reply. Never write `done`; the orchestrator does after the merge.
```

```text
Epic orders. Design folder: <design folder>. You are the epic thread: you stay this thread for all three rounds, even days apart.
1. Flows: run the scope-page skill on the design folder (scope markdown and page, flows only). Then call orchestrator_capabilities and list, per provider (Claude, Codex, Cursor), the models it offers with their efforts and one recommendation each. Stop. {{approver}} approves the flows and picks one model per provider in the same answer.
2. Design: on the yes, record the answer as a dated Round N decisions block, run `architect <design folder>` with only the picked models, and stop with its hand-back. A provider that fails to start or stalls is retried once; then go ahead with the other two and name the missing one. Never substitute another provider or model.
3. Plan: on the yes to the design, add `plan` to _build/content.mjs (the design's slices), rebuild and verify the page, run /epic, and stop. Each slice then runs in its own thread.
- If T3 warns that this thread's context is near full, say so and stop; the orchestrator moves the next round to a fresh epic thread.
```

```text
High-level orders. Design folder: <design folder>. Owner: <owner>. Design at a high level only, so the owner can decide how to build it.
1. Run the scope-page skill on the design folder: the flows, plus a visual design for each new or changed screen (Proposed captures with overlays, or drawn screens marked "drawn", on the project's design tokens).
2. Write <design folder>/design.md, a high-level overview with the use cases: what each use case does, which apps and data it touches (no file paths), permissions, risks, open questions.
3. Stop. No architect, no Complexity, no Placement, no slices, no plan, no /epic. On {{approver}}'s yes the orchestrator hands it to the owner.
```
