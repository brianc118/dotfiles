#!/usr/bin/env bash

set -e

DIR=~/dotfiles
DEFAULT_PKGS="zsh vim neovim tmux git"

install_stuff () {
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
  elif [[ $platform == 'Darwin' ]]; then
    echo "OSX is unhandled for now -- giving up forever"
    echo "TODO: automate installation of homebrew and then continue"
    exit 1
  fi

  $PKG_MANAGER_CMD $DEFAULT_PKGS

  if [[ ! -d ~/.zprezto ]]; then
    git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto
  fi

  if [[ ! -d ~/.fzf ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all 
  fi

  if [[ ! -d ~/.vim/autoload/plug.vim ]]; then
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  if [[ ! -d ~/.local/share/nvim/site/autoload/plug.vim ]]; then
    sh -c 'curl -fLo ~.local/share/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  fi
}

post_install () {
  cd $DIR
  vim -es -u ~/.vimrc +PlugInstall +qa
  nvim -es -u ~/.config/nvim/init.vim +PlugInstall +qa
}

symlinks () {
  cd $DIR
  ln -sf $DIR/.zshrc ~
  ln -sf $DIR/.vimrc ~
  ln -sf $DIR/.tmux.conf ~
  ln -sf $DIR/init.vim ~/.config/nvim/init.vim
}

install_stuff
symlinks
post_install
