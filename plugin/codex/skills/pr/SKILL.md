---
name: pr
description: "Open a pull request for the current branch after verifying micro-PR limits, with a confirmation gate."
---

# /pr

Open a pull request for the current branch.

## Steps

1. Run `git status` — confirm not on `main`, no uncommitted changes
2. Run `git log main..HEAD --oneline` — list commits in this branch
3. Run `git diff main...HEAD --stat` — list changed files
4. Verify against principles:
  - ≤12 files changed?
  - <3000 lines changed?
  - Branch name typed correctly?
5. Draft PR title (conventional) + body (Goal, Changes, Tests, Screenshots if FE)
6. **Ask the user to confirm** title, body, target branch (default: `main`), and whether to push first.
7. Only after confirmation:
  ```bash
  git push -u origin <branch-name>
  gh pr create --title "<title>" --body "<body>" --base main
  ```
