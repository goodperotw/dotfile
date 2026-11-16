if ! [[ $(command -v xonsh) ]]
then
  sudo pacman -S xonsh
fi
curl -sL https://raw.githubusercontent.com/goodperotw/dotfile/refs/heads/main/_setup-os.xsh | xonsh
