# System-wide shell config, where present. Goes first: it runs compinit, and
# prezto (sourced below) expects to run after it.
[ -r /usr/facebook/ops/rc/master.zshrc ] && source /usr/facebook/ops/rc/master.zshrc

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

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.fzf/bin:$PATH"
export PATH="$HOME/homebrew/bin:$HOME/homebrew/sbin:$PATH"

alias fbcode='cd ~/fbsource/fbcode'
alias fbsource='cd ~/fbsource'
alias fbcode2='cd ~/fbsource2/fbcode'
alias fbsource2='cd ~/fbsource2'
alias fbcode3='cd ~/fbsource3/fbcode'
alias fbcode4='cd ~/fbsource4/fbcode'
alias fbcode5='cd ~/fbsource5/fbcode'
alias fbcode6='cd ~/fbsource6/fbcode'
alias fbcode7='cd ~/fbsource7/fbcode'
alias fbcode8='cd ~/fbsource8/fbcode'
alias fbsource3='cd ~/fbsource3'
alias opsfiles='cd ~/opsfiles'
alias rustfmt='~/fbsource/tools/third-party/rustfmt/rustfmt'
alias jfds='jf submit --draft --stack -u'
alias jfd='jf submit --draft -u'
alias et='et -p 2022'

alias g="git"

alias suss='sush2 --reason "Tupperware or resource control related debugging"'

# Proxy
alias with-proxy='env http_proxy=fwdproxy:8080 https_proxy=fwdproxy:8080 no_proxy=.fbcdn.net,.facebook.com,.thefacebook.com,.tfbnw.net,.fb.com,.fburl.com,.facebook.net,.sb.fbsbx.com,localhost RSYNC_PROXY=fwdproxy:8080 HTTP_PROXY=http://fwdproxy:8080 HTTPS_PROXY=http://fwdproxy:8080'
alias proxycurl='curl -x fwdproxy:8080'

# Bash completion
# export BUCK_COMPLETION_GUESS_TARGETS=1

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ] && source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

[ -s "/home/linuxbrew/.linuxbrew/bin/brew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
[ -s "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Use the fastest available ignore-aware file walker. Avoid hidden files and
# ignored build output by default; both can make fuzzy finding unusable in
# large repositories. Debian installs fd as `fdfind`.
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
    export FZF_CTRL_T_COMMAND='fd --strip-cwd-prefix'
    export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix'
elif command -v fdfind >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fdfind --type f --strip-cwd-prefix'
    export FZF_CTRL_T_COMMAND='fdfind --strip-cwd-prefix'
    export FZF_ALT_C_COMMAND='fdfind --type d --strip-cwd-prefix'
elif command -v rg >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='rg --files'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Machine-local overrides, not tracked in the dotfiles repo
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
