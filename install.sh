#!/usr/bin/env bash

set -ex

DIR="$(dirname "$(readlink -f "$0")")"
DEFAULT_PKGS_CENTOS="zsh vim neovim tmux git the_silver_searcher"
DEFAULT_PKGS_DEBIAN="zsh vim neovim tmux git silversearcher-ag build-essential"
DEFAULT_PKGS_DARWIN="zsh vim neovim tmux git tectonic wget karabiner-elements"
DEFAULT_PKGS_AL2="zsh vim tmux git"
MOSH_PKGS_DARWIN="protobuf boost pkg-config automake"
PKGS_CENTOS="$DEFAULT_PKGS_CENTOS $MOSH_PKGS_CENTOS"
PKGS_AL2="$DEFAULT_PKGS_AL2"
PKGS_DEBIAN="$DEFAULT_PKGS_DEBIAN $MOSH_PKGS_DEBIAN"
PKGS_DARWIN="$DEFAULT_PKGS_DARWIN $MOSH_PKGS_DARWIN"

install() {
  cd ~
  # Figure out which package manager to use
  platform=$(uname)
  if [[ $platform == 'Linux' ]]; then
    if [[ -f /etc/redhat-release ]]; then
      PKG_MANAGER_CMD="sudo dnf install -y"
      PKGS="$PKGS_CENTOS"
    elif [[ -f /etc/debian_version ]]; then
      PKG_MANAGER_CMD="sudo apt-get install"
      PKGS="$PKGS_DEBIAN"
    elif [[ -f /etc/arch-release ]]; then
      PKG_MANAGER_CMD="sudo pacman -S"
      PKGS="$PKGS_CENTOS"
    elif [[ -f /etc/os-release && $(source /etc/os-release && echo $NAME) == "Amazon Linux" && $(source /etc/os-release && echo $VERSION) == "2" ]]; then
      echo "Detected AL2 brianc118"
      PKG_MANAGER_CMD="sudo yum install -y"
      PKGS="$PKGS_AL2"
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
    echo "Installing packages" $PKGS_DARWIN "with brew install"
    set HOMEBREW_NO_UPDATE=1
    PKG_MANAGER_CMD="brew install"
    $PKG_MANAGER_CMD $PKGS_DARWIN
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
    sh -c 'curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  fi

  if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    echo "Installing Tmux Plugin Manager"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi

  #echo "Installing pynvim (for deoplete)"
  #python3 -m pip install --user --upgrade pynvim
}

post_install () {
  echo "Post Install"
  cd $DIR
  vim -es -u ~/.vimrc +PlugInstall +qa
  nvim -es -u ~/.config/nvim/init.vim +PlugInstall +qa

  echo "You may also want to install"
  echo "bat"
}

symlinks () {
  echo "Symlinks"
  cd $DIR
  ln -sf $DIR/.zshrc ~
  ln -sf $DIR/.zpreztorc ~
  ln -sf $DIR/.vimrc ~
  ln -sf $DIR/.tmux.conf ~
  ln -sf $DIR/.alacritty.toml ~

  mkdir -p ~/.config/nvim
  touch ~/.config/nvim/init.vim
  ln -sf $DIR/init.vim ~/.config/nvim/init.vim
  if [[ -d ~/.config/karabiner ]]; then
    rm -rf ~/.config/karabiner
    ln -sf $DIR/.config/karabiner ~/.config/karabiner
  fi

  mkdir -p ~/.local/bin
  ln -sf $DIR/brazil_test_env_wrap.sh ~/.local/bin
  ln -sf $DIR/rebase.sh ~/.local/bin
  ln -sf $DIR/pasta.sh ~/.local/bin/pasta
  ln -sf $DIR/yes2.sh ~/.local/bin/yes2
}

install
symlinks
post_install
