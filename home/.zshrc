# Auto-attach tmux
if [[ -z "$TMUX" ]]; then
  tmux attach-session -t default || tmux new-session -s default
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="spaceship"
ZSH_CUSTOM="$ZSH/custom"
VI_MODE_SET_CURSOR=true

plugins=(
  vi-mode
  git
  extract
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Spaceship config must be set before sourcing OMZ
source $ZSH_CUSTOM/spaceship.zsh
source $ZSH/oh-my-zsh.sh

# Source shared configs
source $HOME/.zsh/aliases.zsh
source $HOME/.zsh/utils.zsh
source $HOME/.zsh/exports.zsh
source $HOME/.zsh/tmux.zsh

# Source OS-specific overlays
if [[ "$(uname)" == "Darwin" ]]; then
  source $HOME/.zsh/aliases.mac.zsh
  source $HOME/.zsh/exports.mac.zsh
  source $HOME/.zsh/utils.mac.zsh
else
  source $HOME/.zsh/aliases.linux.zsh
  source $HOME/.zsh/exports.linux.zsh
  source $HOME/.zsh/utils.linux.zsh
fi

# Local secrets (not tracked by git)
[[ -f "$HOME/.zsh/secrets.zsh" ]] && source "$HOME/.zsh/secrets.zsh"

# Local env (e.g. uv, cargo, etc.)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
