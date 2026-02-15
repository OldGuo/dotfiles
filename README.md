# dotfiles

Personal macOS dotfiles bootstrap for:
- `zsh`
- `tmux`
- `neovim`
- `ghostty`
- `vscode`

## Prerequisites
- macOS (Apple Silicon/Homebrew path assumptions)
- Admin access (needed only if you want to change login shell with `chsh`)
- Xcode command line tools/license accepted (`sudo xcodebuild -license`)
- Internet access for Homebrew and git clone steps

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
- Installs missing packages via Homebrew (`zsh`, `direnv`, `fzf`, `tmux`, `neovim`, `ripgrep`, `fd`)
- Installs Oh My Zsh and shell plugins
- Installs `scm_breeze`
- Symlinks configs from this repo into `$HOME`
- Bootstraps Neovim plugin manager and runs plugin/tree-sitter sync

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
