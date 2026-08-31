#!/bin/bash

set -e

DOTFILES_DIR="$1"

# --- Update pacman mirrors ---
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

# --- Install base dependencies ---
echo "==> Installing base dependencies..."
sudo pacman -S --needed --noconfirm base base-devel git

# --- Install yay if missing ---
if ! command -v yay &>/dev/null; then
  echo "==> Installing yay..."
  pushd /tmp
  git clone https://aur.archlinux.org/yay-bin.git
  cd yay-bin
  makepkg --noconfirm -si
  popd
fi

# --- Install packages ---
echo "==> Installing packages via yay..."
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
  ripgrep \
  fd \
  fzf \
  lazygit \
  go \
  rustup \
  hadolint \
  ttf-jetbrains-mono-nerd \
  chromium \
  google-chrome \
  neofetch \
  jdk8-openjdk

# --- Install nvm ---
if [[ ! -d "$HOME/.nvm" ]]; then
  echo "==> Installing nvm..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh)"
fi

# --- Install sdkman ---
if [[ ! -d "$HOME/.sdkman" ]]; then
  echo "==> Installing sdkman..."
  sh -c "$(curl -fsSL https://get.sdkman.io)"
fi

# --- Docker setup ---
echo "==> Configuring Docker..."
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

# --- Set default shell to zsh ---
if [[ "$SHELL" != */zsh ]]; then
  echo "==> Setting zsh as default shell..."
  sudo chsh --shell /bin/zsh "$USER"
fi

# --- Rust toolchain ---
# Arch's rustup package ships the multiplexer without a toolchain.
if command -v rustup &>/dev/null; then
  if ! rustup show 2>/dev/null | grep -q "stable"; then
    echo "==> Installing Rust stable toolchain..."
    rustup default stable
  fi
  if ! rustup which rust-analyzer &>/dev/null; then
    echo "==> Adding rust-analyzer component..."
    rustup component add rust-analyzer
  fi
fi

echo "==> Linux packages installed."
