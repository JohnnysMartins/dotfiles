#!/bin/bash

set -e

if [ "$EUID" -eq 0 ]; then
  echo "This script should not be executed as root"
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
OS="$(uname)"

echo "==> Detected OS: $OS"
echo "==> Dotfiles dir: $DOTFILES_DIR"

# --- Platform-specific package installation ---
if [[ "$OS" == "Darwin" ]]; then
  echo "==> Running macOS installer..."
  bash "$DOTFILES_DIR/mac/install.sh" "$DOTFILES_DIR"
elif [[ "$OS" == "Linux" ]]; then
  echo "==> Running Linux installer..."
  bash "$DOTFILES_DIR/linux/install.sh" "$DOTFILES_DIR"
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# --- Install oh-my-zsh if missing ---
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "==> Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- Install zsh plugins if missing ---
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  echo "==> Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
  echo "==> Installing zsh-completions..."
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  echo "==> Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# --- Install spaceship theme if missing ---
if [[ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]]; then
  echo "==> Installing spaceship theme..."
  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
  ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
fi

# --- Symlink spaceship.zsh into oh-my-zsh custom dir ---
ln -sf "$DOTFILES_DIR/home/.zsh/spaceship.zsh" "$ZSH_CUSTOM/spaceship.zsh"

# --- Symlink helper ---
create_symlink() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "    Backing up $dest -> $BACKUP_DIR/"
    mkdir -p "$BACKUP_DIR/$(dirname "${dest#$HOME/}")"
    mv "$dest" "$BACKUP_DIR/${dest#$HOME/}"
  fi

  mkdir -p "$(dirname "$dest")"
  # -n is required for directory targets: without it, `ln -sf dir existing_dir`
  # creates the link *inside* the destination instead of replacing it.
  ln -sfn "$src" "$dest"
  echo "    $dest -> $src"
}

# --- Back up and remove a path we no longer manage ---
retire_path() {
  local dest="$1"
  local reason="$2"

  [[ -e "$dest" || -L "$dest" ]] || return 0

  echo "    Retiring $dest ($reason)"
  mkdir -p "$BACKUP_DIR/$(dirname "${dest#$HOME/}")"
  mv "$dest" "$BACKUP_DIR/${dest#$HOME/}"
}

# --- Create symlinks for shared configs ---
echo "==> Creating symlinks..."

create_symlink "$DOTFILES_DIR/home/.zshrc" "$HOME/.zshrc"

# tmux reads ~/.tmux.conf *and* $XDG_CONFIG_HOME/tmux/tmux.conf. We use the
# XDG path only, so a leftover ~/.tmux.conf would silently load first.
retire_path "$HOME/.tmux.conf" "config moved to ~/.config/tmux/tmux.conf"
create_symlink "$DOTFILES_DIR/home/.config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

# Ghostty: the XDG path is read on both macOS and Linux, so one file serves both.
create_symlink "$DOTFILES_DIR/home/.config/ghostty/config" "$HOME/.config/ghostty/config"
create_symlink "$DOTFILES_DIR/home/.config/ghostty/themes/tokyo-night.conf" "$HOME/.config/ghostty/themes/tokyo-night.conf"

# Neovim: linked as a whole directory so lazy-lock.json updates land in the repo
# when you run :Lazy update, which is what makes plugin versions reproducible.
create_symlink "$DOTFILES_DIR/home/.config/nvim" "$HOME/.config/nvim"

# Symlink all .zsh/ files
for file in "$DOTFILES_DIR/home/.zsh/"*.zsh; do
  filename="$(basename "$file")"
  create_symlink "$file" "$HOME/.zsh/$filename"
done

# --- Platform-specific symlinks ---
if [[ "$OS" == "Darwin" ]]; then
  # Ghostty on macOS loads BOTH ~/.config/ghostty/config and this native path.
  # Leaving settings in both makes the effective config impossible to reason
  # about (a stray `theme = ...` here silently overrides the palette), so this
  # file is retired in favour of the XDG one above.
  retire_path "$HOME/Library/Application Support/com.mitchellh.ghostty/config" \
    "superseded by ~/.config/ghostty/config"
fi

# --- Neovim bootstrap (plugins, LSP servers, treesitter parsers) ---
if [[ "${SKIP_NVIM_BOOTSTRAP:-0}" != "1" ]]; then
  echo "==> Bootstrapping Neovim (set SKIP_NVIM_BOOTSTRAP=1 to skip)..."
  bash "$DOTFILES_DIR/scripts/nvim-bootstrap.sh"
fi

# --- Done ---
echo ""
echo "==> Dotfiles installed successfully!"
echo ""

if [[ ! -f "$HOME/.zsh/secrets.zsh" ]]; then
  echo "REMINDER: Create ~/.zsh/secrets.zsh for your tokens/keys (not tracked by git)."
  echo "Example:"
  echo "  export GITHUB_PERSONAL_ACCESS_TOKEN=\"your-token\""
  echo ""
fi
