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
cp .zshrc ~

# tmux
echo "installing tmux"
brew install tmux
echo "applying tmux config"
cp .tmux.conf ~

# scm breeze
git clone https://github.com/scmbreeze/scm_breeze.git ~/.scm_breeze
~/.scm_breeze/install.sh

echo "Done"
