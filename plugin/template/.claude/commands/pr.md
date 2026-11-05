---
description: Open a pull request for the current branch after verifying micro-PR limits, with a confirmation gate. Stacked slices target the previous layer's branch.
---

# /pr

Open a pull request for the current branch.

## Steps

1. Run `git status` — confirm not on `{{default_branch}}`, no uncommitted changes.
2. **Pick the base.** Find the slice whose `- Branch:` line names this branch (`docs/epics/*/slices/*.md`). When that line says `stacked on <branch>` and that branch's PR is still open, the base is that branch (stacked PR); otherwise `{{default_branch}}`. No slice (a `/fix`, a refactor): `{{default_branch}}`.
3. Run `git log <base>..HEAD --oneline` and `git diff <base>...HEAD --stat`.
4. Verify against the principles (Micro-PR Discipline):
   - Target 200–400 non-test lines changed; say so in the body when outside it.
   - Hard cap: ≤{{max_files_per_pr}} files and <{{max_loc_per_pr}} lines. Over the cap, stop: split the slice instead of opening the PR.
   - Branch name typed correctly (`feature/<ID>-<group>-<layer>` for slices).
5. Draft the PR title (conventional) and body: Goal, link to the slice file `docs/epics/<ID>/slices/<n>.md` and its stories, Changes, Tests (Definition of Done outputs), the `code-review` summary and open judgement calls, Screenshots if UI.
6. **Ask the user to confirm** title, body, base branch, and whether to push first. This confirmation ALWAYS applies regardless of autonomy mode — push, merge, and publish are action-level confirms that `autonomous` never skips (`.claude/rules/principles.md`, "Autonomy Mode").
7. Only after confirmation:
   ```bash
   git push -u origin <branch-name>
   gh pr create --title "<title>" --body "<body>" --base <base>
   ```
