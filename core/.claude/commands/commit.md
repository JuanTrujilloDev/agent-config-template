# /commit

Create a conventional commit with the staged changes.

## Steps

1. Run `git status` to see staged and unstaged changes
2. Run `git diff --staged` to see what will be committed
3. Run `git log --oneline -5` to see recent commit style
4. Draft a commit message following conventional commits:
   - `feat(scope): description`
   - `fix(scope): description`
   - `refactor(scope): description`
   - `test(scope): description`
   - `docs(scope): description`
   - `style(scope): description`
   - `chore(scope): description`
5. **Ask the user to confirm** the commit message before committing.
6. Run `git commit -m "<message>"` only after explicit confirmation.

Never commit on `{{default_branch}}`. If on `{{default_branch}}`, stop and tell the user to check out a typed branch first.
