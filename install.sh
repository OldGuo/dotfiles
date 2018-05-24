#!/bin/sh
echo "Copying Neovim config"
mkdir -p ~/.config/nvim/ && cp init.vim ~/.config/nvim/
echo "Tmux Neovim config"
cp .tmux.conf ~
echo "Done"
