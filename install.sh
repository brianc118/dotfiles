#!/usr/bin/env bash

set -ex

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PKGS_CENTOS="zsh vim neovim tmux git the_silver_searcher"
PKGS_DEBIAN="zsh vim neovim tmux git silversearcher-ag build-essential"
PKGS_DARWIN="zsh vim neovim tmux git tectonic wget karabiner-elements"
# Build deps for compiling mosh from source
MOSH_PKGS_DARWIN="protobuf boost pkg-config automake"

install() {
  cd ~
  # Figure out which package manager to use
  platform=$(uname)
  if [[ $platform == 'Linux' ]]; then
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
    $PKG_MANAGER_CMD $PKGS
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
  command -v vim  >/dev/null && vim  -es -u ~/.vimrc +PlugInstall +qa
  command -v nvim >/dev/null && nvim -es -u ~/.config/nvim/init.vim +PlugInstall +qa

  echo "You may also want to install"
  echo "bat"
}

symlinks () {
  echo "Symlinks"
  cd "$DIR"
  ln -sf "$DIR/.gitconfig" ~
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
