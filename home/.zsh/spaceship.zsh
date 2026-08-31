# Spaceship Devbox Section
export SPACESHIP_DEVBOX_COLOR="#7dcfff"
export SPACESHIP_DEVBOX_SHOW=true
export SPACESHIP_DEVBOX_SYMBOL="📦 "
export SPACESHIP_DEVBOX_PREFIX="via "
export SPACESHIP_DEVBOX_SUFFIX=" "

export SPACESHIP_PROMPT_ORDER=(time user host dir git node exec_time devbox docker battery line_sep exit_code char)

spaceship_devbox() {
  [[ $SPACESHIP_DEVBOX_SHOW != true ]] && return
  [[ -z "$DEVBOX_PROJECT_ROOT" ]] && return

  # NOTE: spaceship >= 4 parses these with zparseopts, so the flags are
  # required. The old positional form silently dropped the color.
  spaceship::section \
    --color "$SPACESHIP_DEVBOX_COLOR" \
    --prefix "$SPACESHIP_DEVBOX_PREFIX" \
    --suffix "$SPACESHIP_DEVBOX_SUFFIX" \
    --symbol "$SPACESHIP_DEVBOX_SYMBOL" \
    "devbox"
}
