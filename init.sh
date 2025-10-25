askForProcessing(){
  local processingTarget="$1"
  printf "Do you want to $processingTarget ?(y/N): -> "
  read ans
  # downcase the answer, btw, ${ans^^} for upcase
  ans=${ans,,}
  echo $ans
  # return 0 if ans is yes, return 1 if ans is no
  [[ $ans == "y" ]]
}

installAPTpackages(){
  askForProcessing 'install apt packages' || return
  printf "now installing APT packages...\r"
  inputMethod="fcitx5 fcitx5-chewing fcitx5-anthy fcitx5-pinyin"
  commonBuildDependencies="build-essential git curl wget"
  utilities="fzf fd-find ripgrep bat xclip"
  terminal="starship"

  rubyDependencies="zlib1g-dev libreadline-dev libffi-dev libyaml-dev"
  apt-get install -yqq ${inputMethod} ${commonBuildDependencies} ${utilities} ${terminal} ${rubyDependencies}
}

configureInputMethod(){
  askForProcessing "configure input method" || return
  echo "please select Update input method config, and activate fcitx5 framework"
  im-config
  echo "please open up fcitx5 configuration window, and activate the input methods you need"
  fcitx5-configtool
}

installASDF(){
  askForProcessing "install asdf version manager" || return
  wget "https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz" -O asdf.tar.gz
  tar xf asdf.tar.gz
  mv asdf /usr/local/bin/
  rm -f asdf.tar.gz
  mkdir -p $HOME/.asdf
}

configureBash(){
  askForProcessing "configure bash" || return
  _configureBashAlias
  _configureBashEnv
  _configureBashPath
cat << BashRC > $HOME/.bashrc_custom
source \$HOME/.bashrc_custom_alias
source \$HOME/.bashrc_custom_env
source \$HOME/.bashrc_custom_path
eval "\$(fzf --bash)"
eval "\$(starship init bash)"

BashRC
if [[ $(cat $HOME/.bashrc | grep 'bashrc_custom' | wc -l) -gt 0 ]]
then
  echo "source \$HOME/.bashrc_custom" >> $HOME/.bashrc
fi
}

_configureBashAlias(){
  cat << BashAlias > $HOME/.bashrc_custom_alias
  # git
  alias gst="git status"
  alias glg="git log"
  alias gb="git branch"
  alias gbm="gb -m"
  alias grb="git rebase"
  alias grbi="grb -i"
  alias grs="git reset"
  alias ga="git add"
  alias gau="ga -u"
  alias gp="git push"
  alias gf="git fetch"
  alias gck="git checkout"
  alias gc="git commit"
  alias gcm="gc -m"
  alias gd="git diff"

  # navi
  alias b="cd .."
  alias bb="cd ../.."
  alias c="clear"

  # ruby bundler
  alias bd="bundle"
  alias bdi="bd install"
  alias bdu="bd update"
  alias bde="bd exec"

  # others
  alias vim="nvim"
  alias v="vim"
  alias fd="fdfind"
  alias t="batcat"
BashAlias
}

_configureBashEnv(){
  cat << BashEnv > $HOME/.bashrc_custom_env
  export ASDF_DIR=\$HOME/.asdf
BashEnv
}

_configureBashPath(){
  cat << BashPath > $HOME/.bashrc_custom_path
  export PATH=\$PATH:\$ASDF_DIR/shims
BashPath
}

configureSSHkey(){
  askForProcessing "configure ssh key" || return
  ssh-keygen -b 4096 -t ed25519 -f $HOME/.ssh/personal -q -N ""
  cat << SSHConfig >> $HOME/.ssh/config
Host mygithub
  Hostname github.com
  User git
  IdentityFile \$HOME/.ssh/personal
SSHConfig
}

configureGit(){
  askForProcessing "configure git" || return
  git config --global user.name "Pero.Xie"
  git config --global user.email "perox@duck.com"
  git config --global rebase.abbreviateCommands true
}

configureNeovim(){
  askForProcessing "configure neovim" || return
  # download vim-plug
  mkdir -p $HOME/.config/nvim/autoload
  if [[ ! -f $HOME/.config/nvim/autoload/plug.vim ]]
  then
    curl -fLo $HOME/.config/nvim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
  _configureNvimKeybind
  _configureNvimAutocomplete
  _configureNvimWindow
  _configureNvimPlugins
  _configureNvimFtPlugin
  _configureNvimPluginsConfig
  _configureNvimInit
  nvim -c ":PlugInstall | qa"
}

_configureNvimInit(){
  cat << NvimInit > $HOME/.config/nvim/init.vim
filetype on
syntax on
set cursorline
set number
set mouse=
" highlight trailing whitespace
:highlight ExtraWhitespace ctermbg=red guibg=red
:match ExtraWhitespace /\s\+$/
autocmd FileType * TSBufEnable highlight

function! SourceRelatively(relative_path)
  " let base_file = expand('%:p')
  " let base_dir = fnamemodify(base_file, ':h')
  " 根據 init.vim 讀取相對路徑上的其他設定檔
  let absolute_path = \$HOME . '/.config/nvim/' . a:relative_path . '.vim'
  " let absolute_path = fnamemodify(base_dir . '/' . a:relative_path . '.vim', ':p')
  execute 'source' absolute_path
endfunction

call SourceRelatively('keybind')
call SourceRelatively('autocomplete')
call SourceRelatively('window')
call SourceRelatively('plugins')
call SourceRelatively('plugins-config/fzf')
call SourceRelatively('plugins-config/easymotion')
call SourceRelatively('plugins-config/commentary')
NvimInit
}

_configureNvimKeybind(){
  mkdir -p $HOME/.config/nvim
  cat << NvimKeybind > $HOME/.config/nvim/keybind.vim
  " 快捷鍵設定
  nm <C-p> <Up>
  im <C-p> <Up>
  vm <C-p> <Up>

  nm <C-v> <PageDown>
  im <C-v> <PageDown>
  vm <C-v> <PageDown>

  nm <C-u> <PageUp>
  im <C-u> <PageUp>
  vm <C-u> <PageUp>

  nm <C-n> <Down>
  im <C-n> <Down>
  vm <C-n> <Down>

  nm <C-b> <Left>
  im <C-b> <Left>
  vm <C-b> <Left>

  nm <C-f> <Right>
  im <C-f> <Right>
  vm <C-f> <Right>

  nm <C-a> <Home>
  im <C-a> <Home>
  vm <C-a> <Home>

  nm <C-e> <End>
  im <C-e> <End>
  vm <C-e> <End>


  nm <silent> <S-up> <C-w>k
  nm <silent> <S-right> <C-w>l
  nm <silent> <S-down> <C-w>j
  nm <silent> <S-left> <C-w>h
  im <C-d> <Delete>

  " multi edit
  nm <C-x><C-n> cgn

  im <C-\> <ESC>
  vm <C-\> <ESC>
  nm <C-\> <ESC>
NvimKeybind
}


_configureNvimAutocomplete(){
  mkdir -p $HOME/.config/nvim
  cat << NvimAutocomplete > $HOME/.config/nvim/autocomplete.vim
function! s:BufferKeywordOmni(findstart, base) abort
  if a:findstart
    " 找補全起始點
    let line = getline('.')
    let col = col('.') - 1
    while col > 0 && line[col - 1] =~ '\k'
      let col -= 1
    endwhile
    return col
  else
    " 提供候選字串
    let res = []
    let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    let words = {}

    for b in buffers
      if bufloaded(b)
        let lines = getbufline(b, 1, '$')
        for l in lines
          for w in split(l, '[ ()"'']\+')
            if w =~# '' . a:base && strlen(w) > 2
              let words[w] = 1
            endif
          endfor
        endfor
      endif
    endfor

    return sort(keys(words))
  endif
endfunction

set omnifunc=<SID>BufferKeywordOmni

" 簡易的補全
im <C-o><C-o> <C-x><C-o>
im <C-o><C-l> <C-x><C-f>
NvimAutocomplete
}

_configureNvimWindow(){
  mkdir -p $HOME/.config/nvim
  cat << NvimWindow > $HOME/.config/nvim/window.vim
" 分割視窗
nm <C-w><Right> :vsplit<CR>
nm <C-w><Down> :split<CR>
NvimWindow
}

_configureNvimPlugins(){
  mkdir -p $HOME/.config/nvim
  cat << NvimPlugins > $HOME/.config/nvim/plugins.vim
call plug#begin()

im <C-'> <Plug>(emmet-expand-abbr)

" List your plugins here
Plug 'easymotion/vim-easymotion'
Plug 'mattn/emmet-vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-commentary'
Plug 'folke/tokyonight.nvim'
Plug 'nvim-treesitter/nvim-treesitter'

call plug#end()
NvimPlugins
}

_configureNvimFtPlugin(){
  mkdir -p $HOME/.config/nvim/ftplugin
  cat << NvimFtPluginGleam > $HOME/.config/nvim/ftplugin/gleam.vim
setlocal tabstop=2
setlocal shiftwidth=2
setlocal expandtab
NvimFtPluginGleam

  cat << NvimFtPluginVim > $HOME/.config/nvim/ftplugin/vim.vim
setlocal tabstop=2
setlocal shiftwidth=2
setlocal expandtab
NvimFtPluginVim

  cat << NvimFtPluginSh > $HOME/.config/nvim/ftplugin/sh.vim
setlocal tabstop=2
setlocal shiftwidth=2
setlocal expandtab
NvimFtPluginSh
}


_configureNvimPluginsConfig(){
  __configureNvimCommentary
  __configureNvimEasymotion
  __configureNvimFzf
}

__configureNvimCommentary(){
  mkdir -p $HOME/.config/nvim/plugins-config
  cat << NvimCommentary > $HOME/.config/nvim/plugins-config/commentary.vim
  " 註解
  nm <C-c>/ :Commentary<CR>
  vm <C-c>/ :Commentary<CR>
NvimCommentary
}

__configureNvimEasymotion(){
  mkdir -p $HOME/.config/nvim/plugins-config
  cat << NvimEasymotion > $HOME/.config/nvim/plugins-config/easymotion.vim
  " 快速移動 cursor
  nm <C-j> <Plug>(easymotion-s)
  vm <C-j> <Plug>(easymotion-s)
NvimEasymotion
}

__configureNvimFzf(){
  mkdir -p $HOME/.config/nvim/plugins-config
  cat << NvimFzf > $HOME/.config/nvim/plugins-config/fzf.vim
  " FZF 功能
  nm <C-c><C-f> :Files<CR>
  nm <C-c><C-b> :Buffers<CR>
  nm <C-c><C-r> :RG<CR>
  nm <C-c><C-/> :BLines<CR>
NvimFzf
}

installAPTpackages
configureInputMethod
installASDF

configureBash
configureSSHkey
configureGit
configureNeovim
