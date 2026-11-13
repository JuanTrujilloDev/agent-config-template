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
