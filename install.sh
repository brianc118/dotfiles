#!/usr/bin/env bash

set -e

DIR=~/dotfiles
DEFAULT_PKGS="zsh vim neovim tmux git"
DEFAULT_PKGS_DARWIN="zsh vim neovim tmux git tectonic wget"
# Packages for building mosh
MOSH_PKGS_DARWIN="protobuf boost pkg-config automake"
PKGS_DARWIN="$DEFAULT_PKGS_DARWIN $MOSH_PKGS_DARWIN"

install() {
  cd ~
  # Figure out which package manager to use
  platform=$(uname)
  if [[ $platform == 'Linux' ]]; then
    if [[ -f /etc/redhat-release ]]; then
      PKG_MANAGER_CMD="sudo dnf install"
    elif [[ -f /etc/debian_version ]]; then
      PKG_MANAGER_CMD="sudo apt-get install"
    elif [[ -f /etc/arch-release ]]; then
      PKG_MANAGER_CMD="sudo pacman -S"
    else
      echo "Unhandled Linux distro -- giving up forever"
      exit 1
    fi
    $PKG_MANAGER_CMD $DEFAULT_PKGS
  elif [[ $platform == 'Darwin' ]]; then
    if ! command -v brew &> /dev/null; then
      echo "Installing homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "Installing packages" $PKGS_DARWIN "with brew install"
    set HOMEBREW_NO_UPDATE=1
    PKG_MANAGER_CMD="brew install"
    $PKG_MANAGER_CMD $PKGS_DARWIN
  fi

  if [[ ! -d ~/.zprezto ]]; then
    echo "Installing prezto"
    git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto
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
    sh -c 'curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  fi

  if ! command -v mosh &> /dev/null; then
    echo "Building/installing mosh for true color support"
    rm -rf ~/.mosh
    git clone https://github.com/brianc118/mosh.git ~/.mosh
    cd ~/.mosh
    ./autogen.sh
    ./configure
    make
    make install
    cd ~
  fi

  echo "Installing pynvim (for deoplete)"
  python3 -m pip install --user --upgrade pynvim
}

post_install () {
  echo "Post Install"
  cd $DIR
  vim -es -u ~/.vimrc +PlugInstall +qa
  nvim -es -u ~/.config/nvim/init.vim +PlugInstall +qa
}

symlinks () {
  echo "Symlinks"
  cd $DIR
  ln -sf $DIR/.zshrc ~
  ln -sf $DIR/.vimrc ~
  ln -sf $DIR/.tmux.conf ~
  mkdir -p ~/.config/nvim
  touch ~/.config/nvim/init.vim
  ln -sf $DIR/init.vim ~/.config/nvim/init.vim
}

install
symlinks
post_install
