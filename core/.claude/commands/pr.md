# /pr

Open a pull request for the current branch.

## Steps

1. Run `git status` — confirm not on `{{default_branch}}`, no uncommitted changes
2. Run `git log {{default_branch}}..HEAD --oneline` — list commits in this branch
3. Run `git diff {{default_branch}}...HEAD --stat` — list changed files
4. Verify against principles:
   - ≤{{max_files_per_pr}} files changed?
   - <{{max_loc_per_pr}} lines changed?
   - Branch name typed correctly?
5. Draft PR title (conventional) + body (Goal, Changes, Tests, Screenshots if FE)
6. **Ask the user to confirm** title, body, target branch (default: `{{default_branch}}`), and whether to push first.
7. Only after confirmation:
   ```bash
   git push -u origin <branch-name>
   gh pr create --title "<title>" --body "<body>" --base {{default_branch}}
   ```
