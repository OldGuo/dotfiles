# AGENTS.md

## Git Hygiene

- Keep commits small and focused. One logical change per commit.
- Write clear commit messages that explain what changed and why.
- Commit regularly while working so progress is easy to review and recover.
- Push your branch frequently (especially after meaningful checkpoints).
- Keep repo hooks enabled (`git config core.hooksPath .githooks`) so pre-push checks run.
- Pull/rebase before pushing if the remote branch has moved.
- Run relevant checks/tests before committing when possible.
- Do not commit secrets, local env files, or machine-specific generated files.
- Review `git status` before every commit to avoid accidental file adds.
- Prefer feature branches for larger changes instead of committing directly to shared branches.
- Avoid force-pushing shared branches unless everyone involved agrees.

## Suggested Workflow

1. Create or switch to a branch for the task.
2. Make a small, testable change.
3. Review `git diff` and `git status`.
4. Commit with a descriptive message.
5. Push the branch to remote (let `pre-push` checks run).
6. Repeat in small increments.
