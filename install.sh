#!/bin/sh

# homebrew
echo "installing homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# zsh
echo "installing zsh"
brew install zsh
echo "installing oh my zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "installing zsh plugins"
brew install direnv
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
brew install fzf
$(brew --prefix)/opt/fzf/install
echo "applying zsh config"
ln -s $(pwd)/zsh/.zshrc ~
chsh -s /usr/bin/zsh

# ghostty
echo "applying ghostty config"
mkdir -p ~/.config/ghostty
ln -s $(pwd)/ghostty/config ~/.config/ghostty/config

# tmux
echo "installing tmux"
brew install tmux
echo "applying tmux config"
ln -s $(pwd)/tmux/.tmux.conf ~

# vscode
echo "copying vscode configs"
ln -s $(pwd)/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -s $(pwd)/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

# scm breeze
echo "installing scm breeze (git plugin)"
git clone https://github.com/scmbreeze/scm_breeze.git ~/.scm_breeze
~/.scm_breeze/install.sh

# neovim
brew install neovim
brew install ripgrep
brew install fd
ln -s $(pwd)/neovim/.config/nvim ~/.config/nvim

echo "Done"
