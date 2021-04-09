[ -f "$LOCAL_ADMIN_SCRIPTS/master.zshrc" ] && source "$LOCAL_ADMIN_SCRIPTS/master.zshrc"
source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Don't save duplicate commands ot history
setopt HIST_IGNORE_DUPS

export EDITOR='nvim'
