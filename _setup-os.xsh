if not 'xonsh' in $(echo $SHELL):
  # set default shell to xonsh, both user and root
  sudo chsh -s /usr/bin/xonsh
  chsh -s /usr/bin/xonsh


from shutil import which
from pathlib import Path
import subprocess

basic_pkgs = ['fcitx5', 'fcitx5-configtool', 'fcitx5-chewing', 'fcitx5-mozc', 'fcitx5-chinese-addons', 'gnome-terminal']

optional_pkgs = [
  {
    'name': 'game',
    'pkgs': ['cachyos-gaming-applications', 'cachyos-gaming-applications', 'gamescope', 'mangohud', 'polkit', 'steam']
  },
  {
    'name': 'developer',
    'pkgs': ['mise', 'xclip', 'vscodium', 'httpie']
  }
]

target_pkgs = basic_pkgs

print('optional packages:')
for i, optional_item in enumerate(optional_pkgs):
  print(f"  {i}) {optional_item['name']}")

print('selected optional packages with index, separate with comma')
ans = list(map(lambda i: int(i),input().split(',')))
for i in ans:
  target_pkgs.extend(optional_pkgs[i]['pkgs'])

![sudo pacman -S --needed @(target_pkgs)]

source_file = Path('~/.xonshrc').expanduser()

if not which('zoxide'):
  sudo pacman -S zoxide

if which('zoxide') and not which('z'):
  zoxide init xonsh >> ~/.xonshrc
  execx($(zoxide init xonsh))

# setup ssh key
ssh_key_file = Path('~/.ssh/my-hub-key').expanduser()
if not ssh_key_file.exists():
  ssh_key_file.parent.mkdir(parents=True, exist_ok=True)
  ![ssh-keygen -t 'ed25519' -f ~/.ssh/my-hub-key -N '']
  ![cat ~/.ssh/my-hub-key.pub | xclip -sel clip]
  print("public ssh key copied!") and print("make sure to add copied key to github ssh key page")
  ![xdg-open "https://github.com/settings/keys"]

# setup ssh custom hostname
ssh_config_file = Path('~/.ssh/config').expanduser()
if not ssh_config_file.exists() or not 'github' in ssh_config_file.read_text():
  ssh_config_file.write_text("""
    Host github
      Hostname github.com
      User git
      IdentityFile ~/.ssh/my-hub-key
  """)

if not 'aliases setup by setup-os.xsh' in source_file.read_text():
  with source_file.open('a', encoding='utf-8') as f:
    f.write("""
# aliases setup by setup-os.xsh
aliases['gst'] = "git status"
aliases['glg'] = "git log"
aliases['glgo'] = 'git log --oneline'
aliases['gb'] = "git branch"
aliases['gbm'] = "gb -m"
aliases['grb'] = "git rebase"
aliases['grbi'] = "grb -i"
aliases['grs'] = "git reset"
aliases['ga'] = "git add"
aliases['gap'] = "ga -p"
aliases['gau'] = "ga -u"
aliases['gpl'] = "git pull"
aliases['gp'] = "git push"
aliases['gf'] = "git fetch"
aliases['gck'] = "git checkout"
aliases['gc'] = "git commit"
aliases['gcm'] = "gc -m"
aliases['gd'] = "git diff"
aliases['grmt'] = "git remote"
aliases['gsh'] = "git stash"

# navi
aliases['b'] = "cd .."
aliases['bb'] = "cd ../.."
aliases['c'] = "reset"

# others
aliases['v'] = "vim"
aliases['n'] = "nano"
aliases['t'] = "bat"
    """)


# setup git
if ![git config get --global user.name].rtn == 1:
  ![git config set --global user.name $USER]
  ![git config set --global user.email $USER@gmail.com]
  ![git config set --global rebase.abbreviateCommands true]
  ![git config set --global core.editor vim]
  ![git config set --global init.defaultBranch main]


vim_source_file = Path('~/.vimrc').expanduser()
if not vim_source_file.exists() or 'noremap' in vim_source_file.read_text():
  vim_source_file.write_text("""
  " --------------------------------------------------
  " 基礎外觀
  " --------------------------------------------------
  set tabstop=2
  set shiftwidth=2
  set expandtab
  filetype on        " 其實 nvim 預設就開，留著相容
  syntax on          " 等同 syntax on
  set cursorline     " set cursorline
  set number         " set number
  set mouse=         " 關閉 mouse（等同 set mouse=）

  " 高亮游標所在行
  set cursorline

  " 高亮游標所在列（垂直）
  set cursorcolumn

  " --------------------------------------------------
  " 快捷鍵設定
  " --------------------------------------------------

  " <C-p> = 上箭頭
  noremap <C-p> <Up>
  inoremap <C-p> <Up>

  " <C-v> = PageDown
  noremap <C-v> <PageDown>
  inoremap <C-v> <PageDown>

  " <A-v> = PageUp（注意：Alt 組合在終端可能需額外設定）
  noremap <A-v> <PageUp>
  inoremap <A-v> <PageUp>

  " <C-n> = 下箭頭
  noremap <C-n> <Down>
  inoremap <C-n> <Down>

  " <C-b> = 左箭頭
  noremap <C-b> <Left>
  inoremap <C-b> <Left>

  " <C-f> = 右箭頭
  noremap <C-f> <Right>
  inoremap <C-f> <Right>

  " <C-a> = Home
  noremap <C-a> <Home>
  inoremap <C-a> <Home>

  " <C-e> = End
  noremap <C-e> <End>
  inoremap <C-e> <End>

  " Insert 模式下 <C-d> = Delete
  inoremap <C-d> <Delete>

  " Multi edit: <C-x><C-n> = cgn（normal 模式）
  nnoremap <C-x><C-n> cgn

  " ESC（退出 insert/visual/normal 模式）
  noremap <C-\> <Esc>
  inoremap <C-\> <Esc>
  noremap <C-g> <Esc>
  inoremap <C-g> <Esc>

  " 模仿 emacs 的 <C-k>：刪除游標後到行尾的內容
  inoremap <silent> <C-k> <C-o>D

  " 禁用 <C-o> 的跳轉功能（設為 Nop）
  noremap <C-o> <Nop>
  inoremap <C-o> <Nop>
  """)

with source_file.open('a', encoding='utf-8') as f:
  f.write("""
$PATH.insert(0, '~/.local/share/mise/shims')
""")

pkg_to_remove = ['alacritty', 'firefox', 'fish', 'fisher', 'fish-autopair', 'fish-pure-prompt', 'cachyos-fish-config']
# ignore even if those packages not exists anymore in the future
subprocess.run(['sudo', 'pacman', '-R'] + pkg_to_remove, check=False)

source ~/.xonshrc
