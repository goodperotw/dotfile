sudo cachyos-rate-mirrors
sudo pacman -Syu --noconfirm
if ! [[ $(command -v xonsh) ]]
then
  sudo pacman -S xonsh
fi
curl -sLO https://raw.githubusercontent.com/goodperotw/dotfile/refs/heads/main/_setup-os.xsh && xonsh _setup-os.xsh
