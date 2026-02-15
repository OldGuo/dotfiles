#!/bin/sh

set -eu

REPO_ROOT="$(pwd)"

brew_install() {
  if brew list "$1" >/dev/null 2>&1; then
    echo "$1 already installed"
  else
    brew install "$1"
  fi
}

clone_if_missing() {
  repo_url="$1"
  target_dir="$2"
  if [ -d "$target_dir/.git" ]; then
    echo "repo already present at $target_dir"
  elif [ -e "$target_dir" ]; then
    echo "cannot clone $repo_url because $target_dir already exists and is not a git repo"
  else
    git clone "$repo_url" "$target_dir"
  fi
}

link_file() {
  source_path="$1"
  target_path="$2"

  target_dir="$(dirname "$target_path")"
  mkdir -p "$target_dir"

  if [ -L "$target_path" ]; then
    if [ "$(readlink "$target_path")" = "$source_path" ]; then
      echo "link already configured: $target_path"
      return
    fi
    rm "$target_path"
  elif [ -e "$target_path" ]; then
    backup_path="${target_path}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$target_path" "$backup_path"
    echo "backed up existing file to $backup_path"
  fi

  ln -s "$source_path" "$target_path"
}

# homebrew
echo "installing homebrew"
if command -v brew >/dev/null 2>&1; then
  echo "homebrew already installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# zsh
echo "installing zsh"
brew_install zsh
echo "installing oh my zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "installing zsh plugins"
brew_install direnv
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
brew_install fzf
$(brew --prefix)/opt/fzf/install
echo "applying zsh config"
link_file "$REPO_ROOT/zsh/.zshrc" "$HOME/.zshrc"
chsh -s /usr/bin/zsh

# ghostty
echo "applying ghostty config"
mkdir -p ~/.config/ghostty
link_file "$REPO_ROOT/ghostty/config" "$HOME/.config/ghostty/config"

# tmux
echo "installing tmux"
brew_install tmux
echo "applying tmux config"
link_file "$REPO_ROOT/tmux/.tmux.conf" "$HOME/.tmux.conf"

# vscode
echo "copying vscode configs"
link_file "$REPO_ROOT/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
link_file "$REPO_ROOT/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"

# scm breeze
echo "installing scm breeze (git plugin)"
clone_if_missing https://github.com/scmbreeze/scm_breeze.git "$HOME/.scm_breeze"
~/.scm_breeze/install.sh

# neovim
brew_install neovim
brew_install ripgrep
brew_install fd
link_file "$REPO_ROOT/neovim/.config/nvim" "$HOME/.config/nvim"

echo "Done"
