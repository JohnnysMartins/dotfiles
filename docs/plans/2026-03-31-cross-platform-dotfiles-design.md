# Cross-Platform Dotfiles Design

## Goal

Make the dotfiles repo work for both Arch Linux and macOS, so a fresh machine can be set up with a single command. Shared configs are not duplicated — platform-specific parts are isolated into overlay files.

## Directory Structure

```
dotfiles/
├── install.sh                        # Entry point — detects OS, delegates
├── Brewfile                          # Curated Homebrew packages (Mac)
├── .gitignore                        # Excludes secrets.zsh, .DS_Store, etc.
├── home/
│   ├── .zshrc                        # Shared — sources overlays by OS
│   ├── .zsh/
│   │   ├── spaceship.zsh             # Shared — devbox section, prompt order
│   │   ├── aliases.zsh               # Cross-platform aliases
│   │   ├── aliases.linux.zsh         # fn_enable, pbcopy/pbpaste via xclip, vpn
│   │   ├── aliases.mac.zsh           # Mac-specific aliases
│   │   ├── exports.zsh               # Shared non-secret exports
│   │   ├── exports.linux.zsh         # JAVA_HOME, ANDROID_HOME (Linux paths)
│   │   ├── exports.mac.zsh           # Mac-specific paths
│   │   ├── utils.zsh                 # extract, find_file, source_if_exists
│   │   ├── utils.linux.zsh           # list_ips (ip command)
│   │   ├── utils.mac.zsh             # list_ips (ifconfig variant)
│   │   └── tmux.zsh                  # Shared — tdl/tds/tdlm/tsl dev layouts
│   └── .config/
│       ├── ghostty/
│       │   ├── config                # Shared (XDG path works on both OSes)
│       │   └── themes/
│       │       └── tokyo-night.conf  # Palette from Omarchy's colors.toml
│       ├── tmux/
│       │   └── tmux.conf             # Shared — Omarchy tmux config
│       └── nvim/                     # Shared — LazyVim, linked as a directory
│           ├── lazy-lock.json        # Pinned plugin versions
│           ├── lazyvim.json          # Enabled LazyVim extras
│           └── lua/                  # config/ + plugins/ overrides
├── scripts/
│   └── nvim-bootstrap.sh             # Plugins, LSP servers, treesitter parsers
├── linux/
│   └── install.sh                    # Arch: pacman/yay + Linux-specific setup
└── mac/
    └── install.sh                    # Homebrew install + brew bundle + Mac-specific setup
```

## Install Flow

### Entry point: `install.sh`

1. Detect OS via `uname`
2. Delegate to `mac/install.sh` or `linux/install.sh` for package installation
3. Install oh-my-zsh, plugins, and spaceship theme if missing
4. Create symlinks from `home/` to `$HOME/` (preserving directory structure)
5. Remind user to create `~/.zsh/secrets.zsh` for tokens/keys

### `mac/install.sh`

1. Check if Homebrew is installed — if not, install it
2. Run `brew bundle --file=Brewfile` to install all curated packages
3. Create Ghostty config symlink (`home/.config/ghostty/config` -> macOS Application Support path)

### `linux/install.sh`

1. Update pacman mirrors
2. Install base dependencies via pacman
3. Install yay if missing
4. Install all packages via yay
5. Docker setup (usermod, daemon.json)

## Symlink Strategy

The installer creates symlinks from the repo into `$HOME`:

- `home/.zshrc` -> `~/.zshrc`
- `home/.zsh/*` -> `~/.zsh/*`
- `home/.config/tmux/tmux.conf` -> `~/.config/tmux/tmux.conf`
- `home/.config/ghostty/config` -> `~/.config/ghostty/config`
- `home/.config/ghostty/themes/tokyo-night.conf` -> `~/.config/ghostty/themes/tokyo-night.conf`
- `home/.config/nvim` -> `~/.config/nvim` (whole directory)

If a file already exists at the target, the installer backs it up to `~/.dotfiles-backup/` before symlinking.

### Paths that get retired

Two tools read more than one config path, so a leftover file silently competes
with the one we manage. The installer moves these into the backup dir:

- `~/.tmux.conf` — tmux reads it *and* `~/.config/tmux/tmux.conf`, old one first.
- `~/Library/Application Support/com.mitchellh.ghostty/config` — Ghostty on
  macOS reads it *and* the XDG path. A stray `theme = ...` here overrides the
  palette from the XDG file, which is confusing to debug.

### Why `ln -sfn`

`ln -sf link_target existing_dir` puts the link *inside* the directory instead of
replacing it. Since `~/.config/nvim` is linked as a whole directory, the helper
uses `-n` to treat the destination as a plain file.

## ZSH Config

### .zshrc (shared)

```zsh
# Auto-attach tmux
if [[ -z "$TMUX" ]]; then
  tmux attach-session -t default || tmux new-session -s default
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="spaceship"
ZSH_CUSTOM="$ZSH/custom"
VI_MODE_SET_CURSOR=true

plugins=(vi-mode git extract zsh-autosuggestions zsh-syntax-highlighting)

# Spaceship config must be set before sourcing OMZ
source $ZSH_CUSTOM/spaceship.zsh
source $ZSH/oh-my-zsh.sh

# Source shared configs
source $HOME/.zsh/aliases.zsh
source $HOME/.zsh/utils.zsh
source $HOME/.zsh/exports.zsh

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
```

### Platform split

| File | Shared | Linux-only | Mac-only |
|------|--------|------------|----------|
| aliases | `dbs` | `fn_enable`, `pbcopy`/`pbpaste` (xclip), vpn aliases | (empty for now — native pbcopy) |
| exports | `SPACESHIP_*` config | `JAVA_HOME=/usr/lib/jvm/java-8-openjdk`, `ANDROID_HOME` | Mac paths as needed |
| utils | `extract`, `find_file`, `source_if_exists` | `list_ips` (uses `ip` cmd) | `list_ips` (uses `ifconfig`) |
| spaceship.zsh | Devbox section + prompt order | — | — |

### Secrets handling

- Secrets live in `~/.zsh/secrets.zsh` — local-only, never committed
- Contains: `GITHUB_PERSONAL_ACCESS_TOKEN`, `STRIPE_SECRET_KEY`, etc.
- `.gitignore` includes `secrets.zsh`
- Install script prints a reminder to create this file manually

## Brewfile (curated, Mac-only)

Starting point from current installation:

### Formulae
```
brew "fish"
brew "gh"
brew "htop"
brew "mkcert"
brew "neovim"
brew "node"
brew "spaceship"
brew "tig"
brew "tmux"
brew "zsh"
brew "zsh-autocomplete"
brew "zsh-autosuggestions"
brew "zsh-git-prompt"
brew "zsh-syntax-highlighting"
```

### Casks
```
cask "alfred"
cask "amethyst"
cask "app-cleaner"
cask "caffeine"
cask "copyq"
cask "cursor"
cask "font-fira-code"
cask "ghostty"
cask "grammarly-desktop"
cask "iterm2"
cask "ngrok"
cask "orbstack"
```

Note: `claude-code` and `claude-usage-tracker` excluded — installed via npm/other means.

## Ghostty Config (shared)

Symlinked from `home/.config/ghostty/config` to `~/.config/ghostty/config` on
both platforms. macOS Ghostty reads the XDG path as well as its native
Application Support path, and Linux reads only XDG, so one file covers both.

Current config:
- Theme: Tokyo Night, via `home/.config/ghostty/themes/tokyo-night.conf`
  (rendered from Omarchy's `themes/tokyo-night/colors.toml` through its
  `ghostty.conf.tpl`, so it matches Omarchy exactly)
- JetBrains Mono Nerd Font 14, 14px padding, block cursor
- `macos-option-as-alt = left` — left Option acts as Alt so tmux receives
  `M-Enter` and `M-1..9`; right Option still types accented characters
- `shift+enter` / `alt+shift+enter` sent as CSI-u so tmux can tell them apart
  from plain Enter
- Unbound `alt+arrow_left/right` for tmux window navigation

## Migration from Current State

The live Mac configs become the baseline:

| File | Action |
|------|--------|
| `~/.tmux.conf` | Copy live version into repo (has prefix-based resize) |
| `~/.zshrc` | Copy live version, add OS overlay sourcing |
| `~/.zsh/aliases.zsh` | Split: shared -> `aliases.zsh`, Linux-only -> `aliases.linux.zsh` |
| `~/.zsh/exports.zsh` | Secrets -> `secrets.zsh` (local), shared exports -> `exports.zsh` |
| `~/.zsh/spaceship.zsh` | Copy into repo as shared |
| `~/.zsh/utils.zsh` | Split: shared -> `utils.zsh`, `list_ips` -> `utils.linux.zsh` + `utils.mac.zsh` |
| Ghostty config | Copy into repo under `home/.config/ghostty/config` |
