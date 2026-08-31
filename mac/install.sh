#!/bin/bash

set -e

DOTFILES_DIR="$1"

# --- Install Homebrew if missing ---
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for the rest of this script
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# --- Install packages from Brewfile ---
echo "==> Installing Homebrew packages from Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

# --- Rust toolchain ---
# `brew install rustup` installs the multiplexer only: no toolchain, and its
# shims live in the brew prefix rather than ~/.cargo/bin.
RUSTUP_BIN="/opt/homebrew/opt/rustup/bin"
[[ -d "$RUSTUP_BIN" ]] && export PATH="$RUSTUP_BIN:$PATH"

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

echo "==> macOS packages installed."
