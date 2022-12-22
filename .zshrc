# zsh
export ZSH="/Users/young/.oh-my-zsh"

# theme
ZSH_THEME="amuse"

# basic plugins
plugins=(
  git
  zsh-autosuggestions
)

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(direnv hook zsh)"

# scm breeze
autoload -Uz compinit
compinit
[ -s "/Users/young/.scm_breeze/scm_breeze.sh" ] && source "/Users/young/.scm_breeze/scm_breeze.sh"

source $ZSH/oh-my-zsh.sh