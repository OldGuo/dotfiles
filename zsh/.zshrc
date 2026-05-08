# zsh
export ZSH="$HOME/.oh-my-zsh"

# theme
ZSH_THEME="amuse"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=10"

# basic plugins
plugins=(
  git
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# scm breeze
[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"

# fzf
if [[ -o zle ]] && command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
elif [[ -o zle ]] && [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# git
export GIT_EDITOR=nvim

# git aliases
alias gcomm="git commit -m"
alias gcom="git commit"
alias gcoma="git commit --amend"
alias vim="nvim"

export PATH="$HOME/.local/bin:$PATH"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# personal aliases/functions/secrets live outside the dotfiles repo
[ -r "$HOME/.personal-plugins/.shell_config" ] && source "$HOME/.personal-plugins/.shell_config"
