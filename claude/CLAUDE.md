# Personal Context

## Source Control

- Prefer Graphite (`gt`) for source-control operations instead of raw `git`.
- Use Graphite for branch creation, stacking, restacking, submitting, syncing, and merging when Graphite can express the operation.
- Do not assume every change needs a PR. Direct pushes to `main` are fine for personal or shared automation repos when that repo's policy allows it, such as `~/claude-code-shared`; use PRs for repos or changes that expect review.
- Use raw `git` only for low-level inspection or maintenance that Graphite does not cover, and mention why when doing so.
