# zsh
export ZSH="/Users/young/.oh-my-zsh"

# theme
ZSH_THEME="amuse"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=10"

# basic plugins
plugins=(
  git
  zsh-autosuggestions
)

# scm breeze
autoload -Uz compinit
compinit
[ -s "/Users/young/.scm_breeze/scm_breeze.sh" ] && source "/Users/young/.scm_breeze/scm_breeze.sh"

source $ZSH/oh-my-zsh.sh

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(direnv hook zsh)"

# git
export GIT_EDITOR=nvim

# git aliases
alias gcomm="git commit -m"
alias gcom="git commit"
alias gcoma="git commit --amend"
alias vim="nvim"

