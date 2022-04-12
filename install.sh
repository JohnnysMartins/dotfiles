#!/bin/bash

if [ "$EUID" -eq 0 ]; then
  echo "This script should not be executed as root"
  exit 1
fi

echo "Updating Pacman?"
select yn in "yes" "no"; do
  case $yn in
  yes)
    sudo pacman-mirrors -c Brazil && sudo pacman -Syyu
    break
    ;;
  no)
    echo "Skipping mirror update"
    break
    ;;
  esac
done

echo "Installing base dependencies"
sudo pacman -S --needed --noconfirm base base-devel git

if ! hash yay; then
  pushd /tmp
  git clone https://aur.archlinux.org/yay-bin.git
  cd yay-bin
  makepkg --noconfirm -si
  sudo pacman -U --noconfirm yay-bin-*.tar.*
  popd
fi

yay -S --needed --noconfirm \
  autojump \
  aws-cli \
  bat \
  docker \
  clustergit-git \
  cmake \
  docker-compose \
  xclip \
  yarn \
  zsh \
  zsh-syntax-highlighting \
  neovim \
  htop \
  pgadmin4 \
  postgresql-libs \
  powerline \
  tig \
  tigervnc \
  tmux \
  kubectl \
  openvpn3 \
  unzip \
  visual-studio-code-bin \
  slack-desktop \
  chromium \
  google-chrome \
  neofetch \
  jdk8-openjdk

sh -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh)"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sh -c "$(curl -fsSL https://get.sdkman.io)"
source "$HOME/.sdkman/bin/sdkman-init.sh"

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "Install spaceship theme?"
select yn in "yes" "no"; do
  case $yn in
  yes)
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
    ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
    break
    ;;
  no)
    echo "Skipping spaceship theme"
    break
    ;;
  esac
done

sudo chsh --shell /bin/zsh "$USER"
sudo usermod -aG docker "$USER"
sudo mkdir -p /etc/docker

if [[ ! -e /etc/docker/daemon.json ]]; then
  cat <<EOF | sudo tee /etc/docker/daemon.json >/dev/null
  {
    "default-address-pools" : [
      {
        "base" : "172.240.0.0/16",
        "size" : 24
      }
    ]
  }
EOF
fi
