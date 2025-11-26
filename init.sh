askForProcessing(){
  local processingTarget="$1"
  printf "Do you want to $processingTarget ?(y/N/q): -> "
  read ans < /dev/tty
  # downcase the answer, btw, ${ans^^} for upcase
  ans=${ans,,}
  # if the anser is q, quit program immediately
  [[ $ans == "q" ]] && exit
  # return 0 if ans is yes, return 1 if ans is no
  [[ $ans == "y" ]]
}

installAPTpackages(){
  askForProcessing "install apt packages" || return
  printf "now installing APT packages...\r"
  inputMethod="fcitx5 fcitx5-chewing fcitx5-anthy fcitx5-pinyin"
  commonBuildDependencies="build-essential git curl wget cmake"
  utilities="fzf fd-find ripgrep bat xclip neovim httpie"
  container="podman podman-compose qemu-system-x86"
  desktopApps="mpv"

  rubyDependencies="zlib1g-dev libreadline-dev libffi-dev libyaml-dev"
  sudo apt-get install -yqq ${inputMethod} ${commonBuildDependencies} ${utilities} ${rubyDependencies} ${container} ${desktopApps}
}

downloadFonts(){
  askForProcessing "download fonts" || return
  mkdir -p $HOME/.local/share/fonts

  # nerd fonts
  local fontNames=(CascadiaCode FiraCode D2Coding Hasklig Lilex)
  for fontName in $fontNames
  do
    curl -sfLo ${fontName}.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/${fontName}.zip
    unzip -jo ${fontName}.zip '*.ttf' -d $HOME/.local/share/fonts && rm -f ${fontName}.zip
  done

  # jetbrain mono
  curl -sfLo JetBrainsMono.zip https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip
  unzip -jo JetBrainsMono.zip  '*.ttf' -d $HOME/.local/share/fonts/ && rm -f JetBrainsMono.zip

  # victor
  curl -sfLo VictorMono.zip https://rubjo.github.io/victor-mono/VictorMonoAll.zip
  unzip -jo VictorMono.zip '*.ttf' -d $HOME/.local/share/fonts/ && rm -f VictorMono.zip

  fc-cache -fv
}

configureInputMethod(){
  askForProcessing "configure input method" || return
  echo "please select Update input method config, and activate fcitx5 framework"
  im-config
  echo "please open up fcitx5 configuration window, and activate the input methods you need"
  fcitx5-configtool
}

installStarship(){
  askForProcessing "configure starship" || return
  curl -sS https://starship.rs/install.sh | sh
}

installASDF(){
  askForProcessing "install asdf version manager" || return
  wget "https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz" -O asdf.tar.gz
  tar xf asdf.tar.gz
  sudo mv asdf /usr/local/bin/
  rm -f asdf.tar.gz
  mkdir -p $HOME/.asdf
  local plugins=(ruby rust golang nodejs gleam)
  for plugin in $plugins
  do
    asdf plugin add ${plugin}
  done
}

configureBash(){
  askForProcessing "configure bash" || return
  _configureBashAlias
  _configureBashEnv
  _configureBashPath
  _installZoxide

  cat << BashRC > $HOME/.bashrc_custom
source \$HOME/.bashrc_custom_alias
source \$HOME/.bashrc_custom_env
source \$HOME/.bashrc_custom_path
eval "\$(fzf --bash)"
eval "\$(starship init bash)"
eval "\$(zoxide init bash)"
BashRC

if [[ $(cat $HOME/.bashrc | grep 'bashrc_custom' | wc -l) -eq 0 ]]
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
alias gap="ga -p"
alias gau="ga -u"
alias gp="git push"
alias gf="git fetch"
alias gck="git checkout"
alias gc="git commit"
alias gcm="gc -m"
alias gd="git diff"
alias grmt="git remote"
alias gsh="git stash"

# navi
alias b="cd .."
alias bb="cd ../.."
alias c="clear"

# ruby bundler
alias bd="bundle"
alias bda="bd add"
alias bde="bd exec"
alias bdi="bd install"
alias bdr="bd remove"
alias bdu="bd update"

# others
alias vim="nvim"
alias v="vim"
alias fd="fdfind"
alias t="batcat"

# podman
alias docker="podman"
alias dk="docker"
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
  export PATH=\$PATH:\$HOME/.local/bin
BashPath
}

_installZoxide(){
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
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
  git config --global core.editor nvim
}

configurePodman(){
  askForProcessing "configure podman" || return
  sudo wget https://github.com/containers/gvisor-tap-vsock/releases/download/v0.8.7/gvproxy-linux-amd64 -O /usr/libexec/podman/gvproxy && sudo chmod +x /usr/libexec/podman/gvproxy
  curl -fsLo virtiofsd.zip https://gitlab.com/-/project/21523468/uploads/0298165d4cd2c73ca444a8c0f6a9ecc7/virtiofsd-v1.13.2.zip
  sudo unzip -jo virtiofsd.zip  -d /usr/local/libexec/podman && rm -f virtiofsd.zip
  podman machine init
#  podman machine start
}

configureNeovim(){
  askForProcessing "configure neovim" || return
  # download vim-plug
  mkdir -p $HOME/.config/nvim/autoload
  if [[ ! -f $HOME/.config/nvim/autoload/plug.vim ]]
  then
    curl -sfLo $HOME/.config/nvim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
  _configureNvimKeybind
  _configureNvimWindow
  _configureNvimPlugins
  _configureNvimPluginsConfig
  _configureNvimInit
  nvim -c ":PlugInstall | qa"
  nvim -c "TSInstallSync typescript ruby python rust go javascript | qa"
}

_configureNvimInit(){
  cat << NvimInit > $HOME/.config/nvim/init.lua
-- init.lua
--------------------------------------------------
-- 基礎外觀
--------------------------------------------------
vim.opt.tabstop	      = 2
vim.opt.shiftwidth    = 2
vim.opt.expandtab     = true
vim.opt.filetype      = 'on'        -- 其實 nvim 預設就開，留著相容
vim.opt.syntax        = 'on'        -- 等同 syntax on
vim.opt.cursorline    = true        -- set cursorline
vim.opt.number        = true        -- set number
vim.opt.mouse         = ''          -- 關閉 mouse（等同 set mouse=）
-- 高亮游標所在行
vim.opt.cursorline = true

-- 高亮游標所在列（垂直）
vim.opt.cursorcolumn = true

--------------------------------------------------
-- 高亮行尾空白
--------------------------------------------------
vim.api.nvim_set_hl(0, 'ExtraWhitespace', { ctermbg = 'red', bg = 'red' })
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'InsertLeave' }, {
  pattern = '*',
  command = 'match ExtraWhitespace /\\\s+$/',
})

--------------------------------------------------
-- 檔案開啟後啟用 TreeSitter highlight（對應原 TSBufEnable）
--------------------------------------------------
-- vim.api.nvim_create_autocmd('FileType', {
--   pattern = '*',
--   callback = function(args)
--     -- 只在有 parser 的檔案啟用，避免報錯
--     local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
--     -- if lang then
--     --   vim.treesitter.start(args.buf, lang)
--     -- end
--   end,
-- })

--------------------------------------------------
-- 相對載入
--------------------------------------------------
local function source_vim_relatively(name)
  -- 載入 ~/.config/nvim/<name>.vim
  local path = vim.fn.stdpath('config') .. '/' .. name .. '.vim'
  vim.cmd('source ' .. path)
end

local function source_lua_relatively(name)
  -- 載入 ~/.config/nvim/<name>.vim
  local path = vim.fn.stdpath('config') .. '/' .. name .. '.lua'
  vim.cmd('source ' .. path)
end

--------------------------------------------------
-- 依序載入分割檔（.lua 副檔名）
--------------------------------------------------
source_lua_relatively('window')
source_vim_relatively('plugins')
source_lua_relatively('keybind')
source_lua_relatively('plugins-config/fzf')
source_lua_relatively('plugins-config/easymotion')
source_lua_relatively('plugins-config/commentary')
source_lua_relatively('plugins-config/lsp')
source_lua_relatively('plugins-config/cmp')
NvimInit
}

_configureNvimKeybind(){
  mkdir -p $HOME/.config/nvim
  cat << NvimKeybind > $HOME/.config/nvim/keybind.lua
-- 快捷鍵設定

-- 上下左右、翻頁、首尾
local keymap = vim.keymap.set

-- <C-p> = 上箭頭
keymap({'n', 'i', 'v'}, '<C-p>', '<Up>')

-- <C-v> = PageDown
keymap({'n', 'i', 'v'}, '<C-v>', '<PageDown>')

-- <A-v> = PageUp（注意：Alt 組合在終端可能需額外設定）
keymap({'n', 'i', 'v'}, '<A-v>', '<PageUp>')

-- <C-n> = 下箭頭
keymap({'n', 'i', 'v'}, '<C-n>', '<Down>')

-- <C-b> = 左箭頭
keymap({'n', 'i', 'v'}, '<C-b>', '<Left>')

-- <C-f> = 右箭頭
keymap({'n', 'i', 'v'}, '<C-f>', '<Right>')

-- <C-a> = Home
keymap({'n', 'i', 'v'}, '<C-a>', '<Home>')

-- <C-e> = End
keymap({'n', 'i', 'v'}, '<C-e>', '<End>')

-- Insert 模式下 <C-d> = Delete
keymap('i', '<C-d>', '<Delete>')

-- Multi edit: <C-x><C-n> = cgn（normal 模式）
keymap('n', '<C-x><C-n>', 'cgn')

-- ESC（退出 insert/visual/normal 模式）
keymap({'n', 'i', 'v'}, '<C-\\\>', '<Esc>')
keymap({'n', 'i', 'v'}, '<C-g>', '<Esc>')

-- 模仿 emacs 的 <C-k>：刪除游標後到行尾的內容
vim.keymap.set('i', '<C-k>', '<C-o>D', { silent = true })

-- 禁用 <C-o> 的跳轉功能（設為 Nop）
keymap({'n', 'i', 'v'}, '<C-o>', '<Nop>')
NvimKeybind
}

_configureNvimWindow(){
  mkdir -p $HOME/.config/nvim
  cat << NvimWindow > $HOME/.config/nvim/window.lua
-- 視窗導航
-- -- 註解
vim.keymap.set('n', '<C-c><C-w><Right>', ':vsplit<CR>', { silent = true  })
vim.keymap.set('n', '<C-c><C-w><Down>', ':split<CR>', { silent = true  })
vim.keymap.set('n', '<C-w><up>', '<C-w>k', { silent = true })
vim.keymap.set('n', '<C-w><right>', '<C-w>l', { silent = true })
vim.keymap.set('n', '<C-w><down>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-w><left>', '<C-w>h', { silent = true })
NvimWindow
}

_configureNvimPlugins(){
  mkdir -p $HOME/.config/nvim
  cat << NvimPlugins > $HOME/.config/nvim/plugins.vim
call plug#begin()

nm <C-c>' <Plug>(emmet-expand-abbr)
im <C-c>' <Plug>(emmet-expand-abbr)

" List your plugins here
Plug 'easymotion/vim-easymotion'
Plug 'mattn/emmet-vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-commentary'
Plug 'folke/tokyonight.nvim'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'cohama/lexima.vim'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
call plug#end()
NvimPlugins
}

_configureNvimPluginsConfig(){
  __configureNvimLsp
  __configureNvimCmp
  __configureNvimCommentary
  __configureNvimEasymotion
  __configureNvimFzf
}

__configureNvimLsp(){
  cat << NvimLsp > $HOME/.config/nvim/plugins-config/lsp.lua
-- Python
vim.lsp.enable('pyright')
-- Ruby
vim.lsp.enable('ruby_lsp')
-- JS, TS
vim.lsp.enable('ts_ls')
-- Rust
vim.lsp.enable('rust_analyzer')
-- Gleam
vim.lsp.enable('gleam')

vim.lsp.enable('clangd')
vim.diagnostic.config({
  virtual_text = true
})
NvimLsp
}

__configureNvimCmp(){
  cat << NvimCmp > $HOME/.config/nvim/plugins-config/cmp.lua
-- Set up nvim-cmp.
local cmp = require'cmp'
cmp.setup({
completion = {
  autocomplete = false
},
window = {
  -- completion = cmp.config.window.bordered(),
  -- documentation = cmp.config.window.bordered(),
},
mapping = cmp.mapping.preset.insert({
  ['<C-o>'] = cmp.mapping.complete(),
  ['<C-n>'] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_next_item()
    else
      fallback()
    end
  end, { 'i', 'c' }),
  ['<C-p>'] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_next_item()
    else
      fallback()
    end
  end, { 'i', 'c' }),
  ['<C-b>'] = cmp.mapping.scroll_docs(-4),
  ['<C-f>'] = cmp.mapping.scroll_docs(4),
  ['<C-Space>'] = cmp.mapping.complete(),
  ['<C-e>'] = cmp.mapping.abort(),
  ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set "select" to "false" to only confirm explicitly selected items.
}),
sources = cmp.config.sources({
  { name = 'nvim_lsp' },
}, {
  { name = 'buffer' },
  { name = 'path' }
})
})

-- Use buffer source for "/" and "?" (if you enabled "native_menu", this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
mapping = cmp.mapping.preset.cmdline(),
sources = {
  { name = 'buffer' }
}
})

-- Use cmdline & path source for ':' (if you enabled "native_menu", this won't work anymore).
cmp.setup.cmdline(':', {
mapping = cmp.mapping.preset.cmdline(),
sources = cmp.config.sources({
  { name = 'path' }
}, {
  { name = 'cmdline' }
}),
matching = { disallow_symbol_nonprefix_matching = false }
})
NvimCmp
}

__configureNvimCommentary(){
  mkdir -p $HOME/.config/nvim/plugins-config
  cat << NvimCommentary > $HOME/.config/nvim/plugins-config/commentary.lua
-- 註解
vim.keymap.set('n', '<C-c>;', ':Commentary<CR>', { silent = true })
vim.keymap.set('v', '<C-c>;', ':Commentary<CR>', { silent = true })
NvimCommentary
}

__configureNvimEasymotion(){
  mkdir -p $HOME/.config/nvim/plugins-config
  cat << NvimEasymotion > $HOME/.config/nvim/plugins-config/easymotion.lua
-- 快速移動 cursor（EasyMotion）
vim.keymap.set('n', '<C-j>', '<Plug>(easymotion-s)', { silent = true })
vim.keymap.set('v', '<C-j>', '<Plug>(easymotion-s)', { silent = true })
vim.keymap.set('i', '<C-j>', '<ESC><Plug>(easymotion-s)', { silent = true })
NvimEasymotion
}

__configureNvimFzf(){
  mkdir -p $HOME/.config/nvim/plugins-config
  cat << NvimFzf > $HOME/.config/nvim/plugins-config/fzf.vim
-- FZF 功能（使用 <Cmd> 避免模式切換）
vim.keymap.set('n', '<C-c><C-f>', '<Cmd>Files<CR>')
vim.keymap.set('n', '<C-c><C-b>', '<Cmd>Buffers<CR>')
vim.keymap.set('n', '<C-c><C-r>', '<Cmd>Rg<CR>')
vim.keymap.set('n', '<C-c>/', '<Cmd>Lines<CR>')
NvimFzf
}

installAPTpackages
downloadFonts
configureInputMethod
installStarship
installASDF
configureBash
configureSSHkey
configureGit
configurePodman
configureNeovim
