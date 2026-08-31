# ─────────────────────────────────────────────────────────────────────────────
# Omarchy tmux dev layouts, ported to zsh
# Upstream: basecamp/omarchy @ quattro : default/bash/fns/tmux
#
# tdl  - editor left, AI agent right, terminal bottom
# tds  - four-way square: editor, git watcher, terminal, AI
# tdlm - one tdl window per subdirectory of the current dir
# tsl  - N panes tiled, same command in each (agent swarm)
#
# Porting/bug notes vs upstream:
#   * zsh arrays are 1-indexed, so ${panes[0]} becomes ${panes[1]}
#   * split-window -p N is deprecated in tmux 3.5 -> -l N%
#   * upstream tdl ends with `select-pane -t "$opencode_pane"`, a variable that
#     function never sets, so focus landed on whatever pane was last active
#   * upstream tds hardcodes `hunk diff --watch` and `opencode`; using lazygit
#     and claude here
#   * tdl/tdlm default to claude when no agent is named
# ─────────────────────────────────────────────────────────────────────────────

# Create a Tmux Dev Layout with editor, ai, and terminal
# Usage: tdl [<c|cx|codex|other_ai>] [<second_ai>]
tdl() {
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }

  local current_dir="${PWD}"
  local editor_pane ai_pane ai2_pane
  local ai="${1:-claude}"
  local ai2="$2"

  # Use TMUX_PANE for the pane we're running in (stable even if active window changes)
  editor_pane="$TMUX_PANE"

  # Name the current window after the base directory name
  tmux rename-window -t "$editor_pane" "${current_dir:t}"

  # Split window vertically - top 85%, bottom 15% (target editor pane explicitly)
  tmux split-window -v -l 15% -t "$editor_pane" -c "$current_dir"

  # Split editor pane horizontally - AI on right 30% (capture new pane ID directly)
  ai_pane=$(tmux split-window -h -l 30% -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  # If second AI provided, split the AI pane vertically
  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  # Run ai in the right pane
  tmux send-keys -t "$ai_pane" "$ai" C-m

  # Run nvim in the left pane
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m

  # Select the nvim pane for focus
  tmux select-pane -t "$editor_pane"
}

# Create a Tmux Dev Square layout with editor, git watcher, terminal, and AI
# Usage: tds
tds() {
  [[ -n $1 ]] && { echo "Usage: tds"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tds."; return 1; }

  local current_dir="${PWD}"
  local editor_pane diff_pane terminal_pane ai_pane

  editor_pane="$TMUX_PANE"

  tmux rename-window -t "$editor_pane" "${current_dir:t}"

  terminal_pane=$(tmux split-window -v -l 50% -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  diff_pane=$(tmux split-window -h -l 50% -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  ai_pane=$(tmux split-window -h -l 50% -t "$terminal_pane" -c "$current_dir" -P -F '#{pane_id}')

  tmux send-keys -t "$editor_pane" -l "$EDITOR ."
  tmux send-keys -t "$editor_pane" C-m
  tmux send-keys -t "$diff_pane" -l "lazygit"
  tmux send-keys -t "$diff_pane" C-m
  tmux send-keys -t "$ai_pane" -l "claude"
  tmux send-keys -t "$ai_pane" C-m

  tmux select-pane -t "$editor_pane"
}

# Create multiple tdl windows with one per subdirectory in the current directory
# Usage: tdlm [<c|cx|codex|other_ai>] [<second_ai>]
tdlm() {
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdlm."; return 1; }

  local ai="${1:-claude}"
  local ai2="$2"
  local base_dir="$PWD"
  local first=true
  local dir dirpath pane_id

  # Rename the session to the current directory name (replace dots/colons which tmux disallows)
  tmux rename-session "${${base_dir:t}//[.:]/-}"

  for dir in "$base_dir"/*/; do
    [[ -d $dir ]] || continue
    dirpath="${dir%/}"

    if $first; then
      # Reuse the current window for the first project
      tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai $ai2" C-m
      first=false
    else
      pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
      tmux send-keys -t "$pane_id" "tdl $ai $ai2" C-m
    fi
  done
}

# Create a multi-pane swarm layout with the same command started in each pane (great for AI)
# Usage: tsl <pane_count> <command>
tsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: tsl <pane_count> <command>"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tsl."; return 1; }

  local count="$1"
  local cmd="$2"
  local current_dir="${PWD}"
  local -a panes
  local new_pane split_target pane

  tmux rename-window -t "$TMUX_PANE" "${current_dir:t}"

  panes+=("$TMUX_PANE")

  while (( ${#panes[@]} < count )); do
    split_target="${panes[-1]}"
    new_pane=$(tmux split-window -h -t "$split_target" -c "$current_dir" -P -F '#{pane_id}')
    panes+=("$new_pane")
    tmux select-layout -t "${panes[1]}" tiled
  done

  for pane in "${panes[@]}"; do
    tmux send-keys -t "$pane" "$cmd" C-m
  done

  tmux select-pane -t "${panes[1]}"
}
