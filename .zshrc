[ -f "$LOCAL_ADMIN_SCRIPTS/master.zshrc" ] && source "$LOCAL_ADMIN_SCRIPTS/master.zshrc"
source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Disable C-S and C-Q
if [[ -t 0 && $- = *i* ]]
then
    stty -ixon
fi 

# Don't save duplicate commands ot history
setopt HIST_IGNORE_DUPS

export EDITOR='nvim'
