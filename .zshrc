[ -f "$LOCAL_ADMIN_SCRIPTS/master.zshrc" ] && source "$LOCAL_ADMIN_SCRIPTS/master.zshrc"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Disable C-S and C-Q
if [[ -t 0 && $- = *i* ]]
then
    stty -ixon
fi 

# Disable globbing
set -o no_extended_glob

# Don't save duplicate commands ot history
setopt HIST_IGNORE_DUPS

export EDITOR='nvim'
export VISUAL='nvim'

export BAT_THEME='Monokai Extended Light'

export PATH=/home/brianc118/.local/bin:$PATH
export PATH=/home/brianc118/.fzf/bin:$PATH
export PATH="$HOME/homebrew/bin:$HOME/homebrew/sbin:$PATH"

# use ripgrep with fzf
export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden 2>/dev/null'

alias fbcode='cd ~/fbsource/fbcode'
alias fbsource='cd ~/fbsource'
alias fbcode2='cd ~/fbsource2/fbcode'
alias fbsource2='cd ~/fbsource2'
alias fbcode3='cd ~/fbsource3/fbcode'
alias fbsource3='cd ~/fbsource3'
alias opsfiles='cd ~/opsfiles'
alias rustfmt='~/fbsource/tools/third-party/rustfmt/rustfmt'
alias jfds='jf submit --draft --stack -u'
alias jfd='jf submit --draft -u'
alias et='et -p 8080'

alias suss='sush2 --reason "Tupperware or resource control related debugging"'

# Proxy
alias with-proxy='env http_proxy=fwdproxy:8080 https_proxy=fwdproxy:8080 no_proxy=.fbcdn.net,.facebook.com,.thefacebook.com,.tfbnw.net,.fb.com,.fburl.com,.facebook.net,.sb.fbsbx.com,localhost RSYNC_PROXY=fwdproxy:8080 HTTP_PROXY=http://fwdproxy:8080 HTTPS_PROXY=http://fwdproxy:8080'
alias proxycurl='curl -x fwdproxy:8080'

# Bash completion: D33783636
# export BUCK_COMPLETION_GUESS_TARGETS=1
source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
