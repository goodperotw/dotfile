init(){
  set -o xtrace

  # verify sudo priviledge
  sudo print || return 1

  install_ruby 3.4.7
  install_bun 1.3.0
  install_rust 1.90.0

  apt_utils="xclip ripgrep fd-find fzf"
  apt_im="fcitx5 fcitx5-chewing"
  apt_coding="emacs-nox starship zoxide"
  sudo apt install -yqq "$apt_utils" "$apt_im" "apt_coding"

  configure_bash

  source $HOME/.bashrc

  set +x xtrace
}

# $1: command name
depends_on() {
  set -o xtrace

  case "$1" in
  git|curl)
    command -v "$1" && set +x xtrace && return
    sudo apt install -yqq "$1"
    ;;
  build-essential|zlib1g-dev|libyaml-dev|libffi-dev)
    [[ $(apt list "$1" --installed | wc -l) -gt 1 ]] && set +x xtrace && return
    sudo apt install -yqq "$1"
    ;;
  asdf)
    install_asdf
    ;;
  esac
  set +x xtrace
}

install_asdf(){
  set -o xtrace
  depends_on git
  depends_on curl
  wget "https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz" -q -O asdf.tar.gz
  tar xf asdf.tar.gz
  sudo mv asdf /usr/local/bin
  echo "export ASDF_DIR=\$HOME/.asdf" >> $HOME/.bashrc
  echo "export PATH=\$PATH:\$ASDF_DIR/shims" >> $HOME/.bashrc
  source $HOME/.bashrc
  set +x xtrace
}

# $1: ruby version
install_ruby(){
  set -o xtrace

  depends_on asdf
  depends_on build-essential
  depends_on zlib1g-dev
  depends_on libyaml-dev
  depends_on libffi-dev
  asdf plugin add ruby
  asdf install ruby "$1" && asdf set -u ruby "$1"

  set +x xtrace
}

# $1: bun version
install_bun(){
  set -o xtrace
  depends_on asdf
  asdf plugin add bun
  asdf install bun "$1" && asdf set -u ruby "$1"

  set +x xtrace
}

# $1: rust version
install_rust(){
  set -o xtrace

  asdf plugin add rust
  asdf install rust "$1" && asdf set -u rust "$1"

  set +x xtrace
}

configure_bash(){
  # tab auto complete behavior
  echo "bind \"set show-all-if-ambiguous on\"" >> $HOME/.bashrc
  echo "bind \"TAB:menu-complete\"" >> $HOME/.bashrc

  # utilities bash binding
  echo "eval \"\$(starship init bash)\"" >> $HOME/.bashrc
  echo "eval \"\$(zoxide init bash)\"" >> $HOME/.bashrc
  echo "eval \"\$(fzf --bash)\"" >> $HOME/.bashrc

  # setup alias

  ## common
  echo "alias b=\"cd ..\"" >> $HOME/.bashrc
  echo "alias bb=\"cd ../..\"" >> $HOME/.bashrc
  echo "alias c=\"clear\"" >> $HOME/.bashrc
  echo "alias bcat=\"batcat\"" >> $HOME/.bashrc
  echo "alias fd=\"fdfind\"" >> $HOME/.bashrc

  ## ruby
  echo "alias bd=\"bundle\"" >> $HOME/.bashrc
  echo "alias bdi=\"bd install\"" >> $HOME/.bashrc
  echo "alias bdu=\"bd update\"" >> $HOME/.bashrc
  echo "alias bda=\"bd add\"" >> $HOME/.bashrc

  ## editor
  echo "alias v=\"nvim\"" >> $HOME/.bashrc

  ## git
  echo "alias gst=\"git status\"" >> $HOME/.bashrc
  echo "alias gc=\"git commit\"" >> $HOME/.bashrc
  echo "alias gcm=\"gc -m\"" >> $HOME/.bashrc
  echo "alias gp=\"git push\"" >> $HOME/.bashrc
  echo "alias gf=\"git fetch\"" >> $HOME/.bashrc
  echo "alias gb=\"git branch\"" >> $HOME/.bashrc
  echo "alias gbr=\"gb -r\"" >> $HOME/.bashrc
  echo "alias ga=\"git add\"" >> $HOME/.bashrc
  echo "alias gau=\"git add -u\"" >> $HOME/.bashrc
  echo "alias grm=\"git remote\"" >> $HOME/.bashrc
  echo "alias grs=\"git reset\"" >> $HOME/.bashrc
  echo "alias glg=\"git log\"" >> $HOME/.bashrc
  echo "alias grb=\"git rebase\"" >> $HOME/.bashrc
  echo "alias grbi=\"grb -i\"" >> $HOME/.bashrc
  echo "alias gck=\"git checkout\"" >> $HOME/.bashrc
  echo "alias gcp=\"git cherry-pick\"" >> $HOME/.bashrc
  echo "alias gbd=\"gb -d\"" >> $HOME/.bashrc
  echo "alias gbdr=\"gbd -r\"" >> $HOME/.bashrc
  echo "alias gbD=\"gb -D\"" >> $HOME/.bashrc
  echo "alias gbDr=\"gbD -r\"" >> $HOME/.bashrc
  echo "alias gsh=\"git stash\"" >> $HOME/.bashrc
  echo "alias gd=\"git diff\"" >> $HOME/.bashrc

  #  reload bashrc
  source $HOME/.bashrc
}
