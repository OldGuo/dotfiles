# Codex/AI Commit Rules

These are guidance rules for Codex-generated commits in this repo.
They are not enforced by Git hooks or commit templates.

## Format
- Use a concise subject line: `type(scope): summary`
- Include a body with these required sections:
  - `Context:`
  - `Changes:`
  - `Validation:`
- Optional section:
  - `Notes:`

## Expectations
- Explain why the change exists, not only what changed.
- Describe validation with concrete commands/checks when possible.
- Keep each section short and factual.

## Good Example
```text
feat(neovim): add Neogit repo-wide log keymap

Context:
- I need one shortcut for repository history, not file-only history.

Changes:
- Mapped <leader>gl to Neogit's log_all_references action.
- Kept existing diff and Neogit shortcuts unchanged.

Validation:
- Ran nvim --headless '+qa' with clean exit.
- Triggered <leader>gl in Neovim and confirmed all-ref log view opens.

Notes:
- If this key conflicts later, move to <leader>gL.
```
