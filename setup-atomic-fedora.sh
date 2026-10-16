

cmd_packages_dict(){
  case "$1" in
    "ripgrep")
      echo "rg"
      ;;
    *)
      echo "$1"
      ;;
  esac
}

install_cmd_packages(){
  local to_be_install
  for pkg in ${@}
  do
    [[ ! $(command -v $(cmd_packages_dict $pkg)) ]] && to_be_install="$to_be_install $pkg"
  done

  [[ -z ${to_be_install// /} ]] && return

  echo "now installing system packages: $to_be_install"
  sudo rpm-ostree install -yq  $to_be_install && systemctl reboot
}

binstall_cmd_packages(){
  local to_be_install
  for pkg in ${@}
  do
    [[ ! $(command -v $(cmd_packages_dict $pkg)) ]] && to_be_install="$to_be_install $pkg"
  done

  [[ -z ${to_be_install// /} ]] && return

  echo "now installing brew packages: $to_be_install"
  brew install -yq $to_be_install
}

### if any process needs a reboot, the lefted parts will be continued after a reboot and a new bash session
current_script=$(realpath "${BASH_SOURCE[0]}")
[[ ! -f ~/.setup.lock ]] && echo "bash ${current_script}" >> ~/.bashrc || touch ~/.setup.lock
touch ~/.setup.lock 

install_cmd_packages curl

if [[ ! $(command -v brew) ]]
then
  echo "now installing linuxbrew" &&
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &&
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" &&
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
fi

binstall_cmd_packages bat fd fzf httpie mise ripgrep starship vim xclip zoxide

# installing code editor vscodium
[[ ! $(flatpak list | rg VSCodium) ]] && flatpak install -y flathub com.vscodium.codium
# installing code editor zed (if not installed)
[[ ! $(command -v zed) ]] && curl -f https://zed.dev/install.sh | bash

# setup ssh key
if [[ ! -f ~/.ssh/my-hub-key ]]
then
  ssh-keygen -t ed25519 -C "ME" -f ~/.ssh/my-hub-key -N "" &&
  cat ~/.ssh/my-hub-key.pub | xclip -sel clip &&
  echo "public ssh key copied!" &&
  echo "make sure to add copied key to github ssh key page" &&
   xdg-open "https://github.com/settings/keys"
fi

# setup ssh custom hostname
if [[ ! -f ~/.ssh/config ]] || [[ ! $(cat ~/.ssh/config | rg github) ]]
then
  cat << 'SSHConfig' > ~/.ssh/config
Host github
  Hostname github.com
  User git
  IdentityFile ~/.ssh/my-hub-key
SSHConfig
fi

# setup alias
[[ ! $(cat ~/.bashrc | rg "setup by setup-atomic-fedora.sh") ]] && cat << 'BashAlias' >> ~/.bashrc
### setup by setup-atomic-fedora.sh start ###
# git
alias gst="git status"
alias glg="git log"
alias glgo='git log --oneline'
alias gb="git branch"
alias gbm="gb -m"
alias grb="git rebase"
alias grbi="grb -i"
alias grs="git reset"
alias ga="git add"
alias gap="ga -p"
alias gau="ga -u"
alias gpl="git pull"
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
alias c="reset"

# others
alias v="vim"
alias n="nano"
alias t="bat"

cb(){
  if [[ -z $1 ]]
  then
    xclip -sel clip
    return 0
  fi

  if [[ -f $1 ]] && [[ $(du $1 | awk '{print $1}') -lt 2000 ]]
  then
    xclip -sel clip < $1
  else printf $1 | xclip -sel clip
  fi
}

getwh(){
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of default=noprint_wrappers=1 "$1"
}

mp(){
  getwh "$1"
  mpv --autofit=100%x480 "$1" > /dev/null
}

detect_processor_encoder(){
  local cache_path=$HOME/.cache/processor_encoder_name
  if [[ -f $cache_path ]]
  then
    cat $cache_path
  else
    if ffmpeg -f lavfi -i nullsrc -c:v h264_nvenc -frames:v 1 -f null - 2>/dev/null
    then
      encoder_name=cuda
    elif ffmpeg -f lavfi -i nullsrc -c:v h264_qsv -frames:v 1 -f null - 2>/dev/null
    then
      encoder_name=qsv
    elif ffmpeg -f lavfi -i nullsrc -c:v h264_amf -frames:v 1 -f null - 2>/dev/null
    then
      encoder_name=amf
    else
      encoder_name=none
    fi
    printf $encoder_name > $cache_path
    printf $encoder_name
  fi
}

scale_p(){
  local scale_param_name
  case $(detect_processor_encoder) in
  cuda)
    printf scale_cuda
    ;;
  qsv)
    printf scale_qsv
    ;;
  amf)
    printf scale_amf
    ;;
  none)
    printf scale
    ;;
  esac
}

xv(){
  local input="$1"
  local _vwh=$(getwh "$input")
  local vwidth=$(echo $_vwh | rg -Po '(?<=width=)\d+')
  local vheight=$(echo $_vwh | rg -Po '(?<=height=)\d+')
  local is_landscape=$(($vwidth / $vheight))
  local output=$(echo "$input" | sed 's/[ ()]//g')
  output=${output%.*}.mp4
  local full_output_path="$HOME/Videos/xxx/$output"
  scale_option=$(scale_p)
  local vf
  if [[ -z "$2" ]]
  then
    if [[ $is_landscape == 1 ]]
    then
      [[ $vheight -gt 880 ]] && vf="-vf ${scale_option}=-1:880"
    elif [[ $is_landscape == 0 ]]
    then
      [[ $vwidth -gt 880 ]] && vf="-vf ${scale_option}=880:-1"
    fi
  else
    if [[ "$2" == w* ]]
    then
      vf="${2##*w}"
      vf="-vf ${scale_option}=$vf:-1"
    elif [[ "$2" == h* ]]
    then
      vf="${2##*h}"
      vf="-vf ${scale_option}=-1:$vf"
    else
      echo "incorrect, scale number, either w\d+ or h\d+ should be given!"
      return 1
    fi
  fi
  local extra_options=$(echo "${@:2}" | sed 's/scale=/scale_qsv=/')
  local command="ffmpeg -hide_banner -loglevel error -hwaccel qsv -hwaccel_output_format qsv -i '$input' -c:v hevc_qsv -c:a libopus -af loudnorm=I=-16:TP=-1.5:LRA=11,volume=-2dB  -preset medium -b:v 5M -progress pipe:1 $vf '$full_output_path' | rg -o -P '(?<=time=)\d{2}:\d{2}:\d{2}\.\d{2}'"
  echo "$command"
  eval "$command" &&
    echo "'$input' -> '$output' COMPLETE!"
}

hashrename(){
  local input=$(basename "$1")
  local ext=${input##*.}
  local base=${input%.*}
  local hash_part=$(md5sum "$input"  | awk '{print $1}' | rg '^.{8}' -o)
  local orig_part=$(echo $base | sed 's/[ ()]//g' | rg -o '^.{1,8}')
  local new_name="${hash_part}${orig_part}.${ext}"
  mv "$input" "${new_name}" &&
  echo "$input --> $new_name"
}

rv(){
  mpv $v.mp4 --volume=35 --geometry=x880
}

rd(){
  rm -i $v.mp4
  unset output vf EXT output
}

f(){
  [[ ${#@} -lt 2 ]] && echo "args not enough, e.g. f <start> <end>" && return 1
  [[ -z $output ]] && echo "\$output not set" && return 1

  [[ -z $EXT ]] && EXT=mp4
  local start_seconds end_seconds t_time
  local start_time=$1
  local end_time=$2
  if [[ $(echo $start_time | rg -o "[:-]" | wc -l) -eq 2 ]]
  then
    start_seconds=$(echo $start_time | sed "s/[:\-]/*3600+/" | sed "s/[:\-]/*60+/" | bc)
  elif [[ $(echo $start_time | rg -o "[:-]" | wc -l) -eq 1 ]]
  then
    start_seconds=$(echo $start_time | sed "s/[:\-]/*60+/" | bc)
  else
    start_seconds=$start_time
  fi
  start_time="-ss $start_seconds"
  if [[ $(echo $end_time | rg -o "[:-]" | wc -l) -eq 2 ]]
  then
    end_seconds=$(echo $end_time | sed "s/[:\-]/*3600+/" | sed "s/[:\-]/*60+/" | bc)
  elif [[ $(echo $end_time | rg -o "[:-]" | wc -l) -eq 1 ]]
  then
    end_seconds=$(echo $end_time | sed "s/[:\-]/*60+/" | bc)
  else
    end_seconds=$end_time
  fi
  t_time=$(echo "$end_seconds - $start_seconds" | bc)
  reset
  echo ffmpeg $start_time -i $v.$EXT -c:v libx265 -c:a libopus $vf -t $t_time ${@:3} x-videos/$output
  sleep 1
  flock /tmp/ff.lock ffmpeg -stats_period 3 -v error -hide_banner -stats $start_time -i $v.$EXT -c:v libx265 -c:a libopus $vf -t $t_time ${@:4} x-videos/$output
  echo "$v"
  echo "  ~ $end_time complete"
  echo "  -> x-videos/$output"
}

x(){
  if [[ ${#@} -eq 1 ]]
  then
    output=${v}_${1}.mp4
  elif [[ ${#@} -eq 0 ]]
  then
    output=${v}.mp4
  fi
}
### setup by setup-atomic-fedora.sh end ###
BashAlias

# setup git
if [[ ! $(git config get --global user.name) ]]
then
  git config set --global user.name $USER
  git config set --global user.email ${USER}@gmail.com
  git config set --global rebase.abbreviateCommands true
  git config set --global core.editor vim
  git config set --global init.defaultBranch main
fi

# setup vim (minimum)
[[ ! -f ~/.vimrc ]] || [[ ! $(cat ~/.vimrc | rg noremap) ]] && cat << 'VimConfig' > ~/.vimrc
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
VimConfig


### ending script, remove the script command from bashrc
sed -i "/setup-atomic-fedora/d" ~/.bashrc
unlink ~/.setup.lock
