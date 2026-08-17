#!/usr/bin/env bash

set -ex

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PKGS_CENTOS="zsh vim neovim tmux git the_silver_searcher"
PKGS_DEBIAN="zsh vim neovim tmux git silversearcher-ag build-essential"
PKGS_DARWIN="zsh vim neovim tmux git tectonic wget karabiner-elements"
# Meta devservers: installed via devfeature, not the distro package manager.
# zsh/vim/tmux/git are already present; fzf is deliberately omitted because we
# install it from git below to get the key bindings. tree_sitter_cli is needed
# by nvim-treesitter to build parsers.
FEATURES_META="neovim ripgrep bat tree_sitter_cli"
# Build deps for compiling mosh from source
MOSH_PKGS_DARWIN="protobuf boost pkg-config automake"

# ~/.gitconfig must be a REAL file that *includes* the copy in this repo -- not
# a symlink to it. `git config --global` writes to ~/.gitconfig, and plenty of
# things call it: Meta tooling adds x509 client-cert blocks for internal git
# hosts, and `git config --global user.email ...` is the first thing anyone
# reaches for. With a symlink those machine-specific values land in a tracked
# file and get committed by accident.
#
# The include goes at the top, so anything appended later (which is where
# --global writes) takes precedence -- git applies config in file order.
# Runs before anything else here, because the proxy setup below uses --global.
ensure_real_gitconfig() {
  if [[ -L "$HOME/.gitconfig" ]]; then
    echo "Converting ~/.gitconfig from symlink to real file"
    rm -f "$HOME/.gitconfig"
  fi

  if [[ ! -e "$HOME/.gitconfig" ]]; then
    cat > "$HOME/.gitconfig" <<EOF
# Machine-local git config -- NOT tracked in the dotfiles repo.
# The shared config is included below; put host-specific settings (x509 certs,
# proxies, work email) here, or just let \`git config --global\` append them.
[include]
	path = $DIR/.gitconfig
EOF
  fi

  # Idempotent: only add the include if it isn't already there.
  if ! git config --global --get-all include.path 2>/dev/null \
    | grep -qxF "$DIR/.gitconfig"; then
    git config --global --add include.path "$DIR/.gitconfig"
  fi

  # Migrate the older ~/.gitconfig.local split into ~/.gitconfig, which is now
  # itself the machine-local file. Kept as a no-op once done.
  if [[ -f "$HOME/.gitconfig.local" ]]; then
    echo "Merging legacy ~/.gitconfig.local into ~/.gitconfig"
    cat "$HOME/.gitconfig.local" >> "$HOME/.gitconfig"
    mv "$HOME/.gitconfig.local" "$HOME/.gitconfig.local.migrated"
  fi
}
ensure_real_gitconfig

# Meta devservers/OnDemands have no direct internet access; everything outbound
# has to go via fwdproxy. Exported so git, curl, and vim-plug all pick it up.
if command -v fwdproxy-config >/dev/null 2>&1; then
  echo "Detected Meta host -- routing outbound traffic via fwdproxy"
  export http_proxy=http://fwdproxy:8080
  export https_proxy=http://fwdproxy:8080
  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$https_proxy"
  export no_proxy=.fbcdn.net,.facebook.com,.thefacebook.com,.tfbnw.net,.fb.com,.fburl.com,.facebook.net,.sb.fbsbx.com,localhost
  export NO_PROXY="$no_proxy"

  # The exports above only last for this script. Anything run interactively
  # later -- `:PlugInstall` from inside nvim, a manual `git clone` -- would
  # otherwise fail with "Could not resolve host: github.com". Persist the proxy
  # in git config, scoped to GitHub so internal hosts (git.internal.tfbnw.net,
  # mononoke, manifold) keep talking direct with their x509 certs.
  #
  # --global is safe now that ensure_real_gitconfig has made ~/.gitconfig a
  # real, untracked file.
  for host in "https://github.com/" "https://raw.githubusercontent.com/"; do
    git config --global "http.${host}.proxy" fwdproxy:8080
  done
fi

install() {
  cd ~
  # Figure out which package manager to use
  platform=$(uname)
  if [[ $platform == 'Linux' ]] && command -v devfeature >/dev/null 2>&1; then
    # Meta devserver/OnDemand. devfeature installs without root (plain dnf
    # needs sudo, which devservers don't grant) and `persist` re-installs the
    # feature on every server reserved from here on -- which is what makes
    # short-lease devvms survivable.
    echo "Meta host detected -- installing features with devfeature"
    for feat in $FEATURES_META; do
      devfeature install "$feat" \
        || { echo "WARNING: devfeature install $feat failed -- skipping"; continue; }
      devfeature persist "$feat" \
        || echo "WARNING: devfeature persist $feat failed (installed but not persisted)"
    done
  elif [[ $platform == 'Linux' ]]; then
    if [[ -f /etc/redhat-release ]]; then
      PKG_MANAGER_CMD="sudo dnf install -y"
      PKGS="$PKGS_CENTOS"
    elif [[ -f /etc/debian_version ]]; then
      PKG_MANAGER_CMD="sudo apt-get install -y"
      PKGS="$PKGS_DEBIAN"
    elif [[ -f /etc/arch-release ]]; then
      PKG_MANAGER_CMD="sudo pacman -S --noconfirm"
      PKGS="$PKGS_CENTOS"
    else
      echo "Unhandled Linux distro -- giving up forever"
      exit 1
    fi
    # Install one at a time: on locked-down/Chef-managed hosts some of these
    # aren't in the configured repos, and a single missing package would
    # otherwise abort the whole script via `set -e`.
    for pkg in $PKGS; do
      $PKG_MANAGER_CMD "$pkg" || echo "WARNING: could not install $pkg -- skipping"
    done
  elif [[ $platform == 'Darwin' ]]; then
    if ! command -v brew &> /dev/null; then
      echo "Installing homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "Installing packages" $PKGS_DARWIN $MOSH_PKGS_DARWIN "with brew install"
    export HOMEBREW_NO_AUTO_UPDATE=1
    brew install $PKGS_DARWIN $MOSH_PKGS_DARWIN
  fi

  if [[ ! -d ~/.zprezto ]]; then
    echo "Installing prezto"
    git clone --recursive https://github.com/brianc118/prezto.git ~/.zprezto
  fi

  # Could use package manager here but doesn't install key bindings by default
  if [[ ! -d ~/.fzf ]]; then
    echo "Installing fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
  fi

  if [[ ! -f ~/.vim/autoload/plug.vim ]]; then
    echo "Installing vim-plug"
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  if [[ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]]; then
    echo "Installing vim-plug (nvim)"
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    echo "Installing Tmux Plugin Manager"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
}

post_install () {
  echo "Post Install"
  cd "$DIR"
  # vim-plug exits non-zero from silent-ex mode even on a clean install, so
  # don't let `set -e` fail the whole script (and any automation calling it).
  command -v vim  >/dev/null && { vim  -es -u ~/.vimrc                 +PlugInstall +qa </dev/null || true; }
  command -v nvim >/dev/null && { nvim -es -u ~/.config/nvim/init.vim  +PlugInstall +qa </dev/null || true; }

  echo "You may also want to install"
  echo "bat"
}

symlinks () {
  echo "Symlinks"
  cd "$DIR"
  # NB: .gitconfig is deliberately not symlinked -- see ensure_real_gitconfig.
  ln -sf "$DIR/.zshrc" ~
  ln -sf "$DIR/.zpreztorc" ~
  ln -sf "$DIR/.vimrc" ~
  ln -sf "$DIR/.tmux.conf" ~
  ln -sf "$DIR/.alacritty.toml" ~

  mkdir -p ~/.config/nvim
  ln -sf "$DIR/init.vim" ~/.config/nvim/init.vim

  # Karabiner rewrites karabiner.json in place, so symlink the whole directory
  # rather than the file. Karabiner recreates this dir with a default config on
  # first launch, so move any real directory aside before linking.
  if [[ ! -L ~/.config/karabiner ]]; then
    if [[ -e ~/.config/karabiner ]]; then
      mv ~/.config/karabiner ~/.config/karabiner.bak."$(date +%Y%m%d%H%M%S)"
    fi
    ln -sfn "$DIR/.config/karabiner" ~/.config/karabiner
  fi

  mkdir -p ~/.local/bin
  ln -sf "$DIR/rebase.sh" ~/.local/bin
  ln -sf "$DIR/yes2.sh" ~/.local/bin/yes2
}

install
symlinks
post_install
