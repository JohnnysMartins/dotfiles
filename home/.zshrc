export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="spaceship"

plugins=(git docker docker-compose zsh-autosuggestions zsh-completions zsh-syntax-highlighting kubectl)

if [[ -z "$TMUX" ]]; then
  tmux attach-session -t default || tmux new-session -s default
fi

source $ZSH/oh-my-zsh.sh

source $HOME/.zsh/aliases.zsh
source $HOME/.zsh/utils.zsh
source $HOME/.zsh/exports.zsh

source_if_exists /usr/share/autojump/autojump.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

