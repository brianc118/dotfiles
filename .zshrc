[ -f "/apollo/env/DevDesktopAL2/misc/zshrc_dev_dsk_base" ] && source "/apollo/env/DevDesktopAL2/misc/zshrc_dev_dsk_base"
[ -f "/apollo/env/envImprovement/var/zshrc" ] && source "/apollo/env/envImprovement/var/zshrc"
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

export PATH="/home/$USER/.local/bin:$PATH"
export PATH="/home/$USER/.fzf/bin:$PATH"
export PATH="$HOME/homebrew/bin:$HOME/homebrew/sbin:$PATH"
[ -d /apollo/env/OdinTools/bin ] && export PATH=/apollo/env/OdinTools/bin:$PATH
[ -d /apollo/env/OdinTools/bin ] && export PATH=/apollo/env/OdinTools/bin:$PATH

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
alias et='et -p 2022'
alias wp='cd ~/workplace'
alias pasta='paste.amazon.com'

alias suss='sush2 --reason "Tupperware or resource control related debugging"'

# Proxy
alias with-proxy='env http_proxy=fwdproxy:8080 https_proxy=fwdproxy:8080 no_proxy=.fbcdn.net,.facebook.com,.thefacebook.com,.tfbnw.net,.fb.com,.fburl.com,.facebook.net,.sb.fbsbx.com,localhost RSYNC_PROXY=fwdproxy:8080 HTTP_PROXY=http://fwdproxy:8080 HTTPS_PROXY=http://fwdproxy:8080'
alias proxycurl='curl -x fwdproxy:8080'

# Bash completion: D33783636
# export BUCK_COMPLETION_GUESS_TARGETS=1
source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

# if you wish to use IMDS set AWS_EC2_METADATA_DISABLED=false

export AWS_EC2_METADATA_DISABLED=true

PATH=$PATH:/apollo/env/NRE-Desktop/bin
export PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
