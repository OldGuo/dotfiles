# dotfiles

Personal macOS/Linux dotfiles bootstrap for:
- `zsh`
- `tmux`
- `neovim`
- `ghostty`
- `vscode`
- `codex`

## Prerequisites
- macOS or Linux
- Admin access (needed if package installation or `chsh` is required)
- macOS only: Xcode command line tools/license accepted (`sudo xcodebuild -license`)
- Internet access for package installs and git clone steps

## Fresh Machine Setup
```sh
git clone <this-repo>
cd dotfiles
python3 install.py
```

Optional: set login shell during install.
```sh
APPLY_LOGIN_SHELL=1 python3 install.py
```

## What Install Does
- Installs missing packages via Homebrew (or Linux package manager fallback: `apt`/`dnf`/`pacman`/`zypper`) for `zsh`, `direnv`, `fzf`, `tmux`, `neovim`, `ripgrep`, `fd`
- Installs Oh My Zsh and shell plugins
- Installs `scm_breeze`
- Symlinks configs from this repo into `$HOME`
- Applies Codex CLI config (`~/.codex/config.toml`)
- Bootstraps `lazy.nvim` and runs plugin/tree-sitter sync

The script is designed to be rerunnable and backs up pre-existing target files before replacing them with symlinks.

## Quick Verify
- `zsh --version`
- `tmux -V`
- `nvim --version`
- `nvim --headless "+checkhealth" +qa`
- Confirm symlinks:
  - `ls -l ~/.zshrc`
  - `ls -l ~/.tmux.conf`
  - `ls -l ~/.config/nvim`
  - `ls -l ~/.config/ghostty/config`
  - `ls -l ~/Library/Application\\ Support/Code/User/settings.json`
  - `ls -l ~/.codex/config.toml`

## Commit Message Rules (Codex/AI)
Commit message guidance for Codex lives in `codex/COMMIT_RULES.md`.
These are style rules only (no Git hook/template enforcement).
