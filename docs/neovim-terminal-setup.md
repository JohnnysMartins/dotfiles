# Neovim + Terminal Setup

An Omarchy-style terminal dev environment: Ghostty + tmux + LazyVim, built so
most work can happen in the terminal alongside an AI agent.

Modelled on [Omarchy](https://omarchy.org) (`basecamp/omarchy`, branch
`quattro`). Configs are ports of the upstream files, with macOS adjustments and
a few upstream bugs fixed — see the comments in each file.

## Fresh machine

```sh
git clone <this repo> ~/workarea/dotfiles
cd ~/workarea/dotfiles
./install.sh                 # packages + symlinks + Neovim bootstrap
```

`install.sh` ends by running `scripts/nvim-bootstrap.sh`, which installs
plugins, LSP servers and treesitter parsers up front. Skip it with
`SKIP_NVIM_BOOTSTRAP=1 ./install.sh` and run the script later by hand.

Restart Ghostty and open a new shell afterwards.

## Daily driver

```sh
cd ~/some/project
tdl claude       # nvim left, claude right, shell bottom
```

| command | layout |
|---|---|
| `tdl [agent]` | editor left, agent right, terminal bottom (agent defaults to `claude`) |
| `tds` | four-way square: editor, lazygit, terminal, agent |
| `tdlm [agent]` | one `tdl` window per subdirectory — good for a monorepo |
| `tsl N "cmd"` | N tiled panes all running `cmd` (agent swarm) |

## Keybindings

Leader is `Space`. `Ctrl-Space` is the tmux prefix.

### Finding code

| key | action |
|---|---|
| `grr` | LSP references for the symbol under the cursor |
| `Space c S` | same, in a persistent Trouble panel |
| `Ctrl-]` | go to definition (via `tagfunc`) |
| `Ctrl-o` | jump back |
| `gri` / `grt` | implementations / type definition |
| `grn` / `gra` | rename / code action |
| `K` | hover docs |
| `Space s S` | find any symbol across the project |
| `Space s s` / `gO` | symbols in the current file |
| `Space s g` | live grep |
| `Space s w` | grep word under cursor |
| `Space s r` | search and replace across the project |
| `Ctrl-q` | send picker results to the quickfix list |

Note: `gd`, `gr`, `gI` and `gy` are **not** mapped. Current LazyVim defers to
Neovim 0.11+'s built-in LSP defaults (`grr`, `gri`, `grn`, `gra`, `grt`, `gO`),
so older LazyVim tutorials will give keys that do nothing here.

### Files and buffers

| key | action |
|---|---|
| `Space Space` | find files |
| `Space e` | file tree |
| `Shift-L` / `Shift-H` | next / previous buffer |
| `Space b j` | pick a buffer by letter |
| `Space b d` / `Space b o` | close this / all other buffers |
| `Space g g` | lazygit |

### tmux

| key | action |
|---|---|
| `Alt-Enter` / `Alt-Shift-Enter` | split vertical / horizontal |
| `Alt-1` … `Alt-9` | jump to window |
| `Alt-Left` / `Alt-Right` | previous / next window |
| `Ctrl-Space h/j/k/l` | move between panes, aware of nvim splits |
| `Ctrl-Space -` / `\|` | split vertical / horizontal |
| `Ctrl-Space ?` | list all keybindings |
| `Ctrl-Space q` | reload tmux config |

On macOS only the **left** Option key acts as Alt (`macos-option-as-alt = left`),
which keeps the right one available for accented characters.

`Ctrl-Space h` is bound to nvim-aware pane navigation, which takes that key from
Omarchy's "split vertical" — that lives on `Alt-Enter` and `Ctrl-Space -` here.

## Gotchas worth remembering

These all cost real debugging time. The configs already work around them.

**lazy.nvim partial clones fail on some machines.** lazy.nvim clones with
`--filter=blob:none` by default. Where that path is broken, `index-pack` loses
its `tmp_pack_*` file and the clone dies with `invalid index-pack output` — but
only for repos big enough to need pack negotiation, so most plugins install fine
and treesitter/snacks fail. `lua/config/lazy.lua` sets `git = { filter = false }`.

**Neovim 0.12+ is required.** rustaceanvim refuses to load below it, so Rust gets
no LSP at all with a stale nvim. `scripts/nvim-bootstrap.sh` checks this.

**LazyVim's python extra defaults to `pyright`, not basedpyright.**
`lua/config/options.lua` sets `vim.g.lazyvim_python_lsp = "basedpyright"`.

**Homebrew's `rustup` has no `~/.cargo/bin`.** Its shims live in
`/opt/homebrew/opt/rustup/bin` with `RUSTUP_HOME=~/.rustup`, and it installs no
toolchain on its own. `mac/install.sh` runs `rustup default stable` and
`rustup component add rust-analyzer`.

**hadolint publishes no arm64 build.** Mason pulls a ~99MB x86 binary that can
take forever. It comes from the package manager instead, and
`lua/plugins/mason.lua` filters it out of Mason's `ensure_installed`.

**Mason aborts in-flight installs when Neovim exits.** Any headless
`nvim --headless +MasonInstall … +qa` silently rolls back. The bootstrap script
waits for `ensure_installed` to actually land before quitting.

**Treesitter parsers install to `stdpath('data')/site/parser`**, not into the
plugin directory, on nvim-treesitter's `main` branch. Compiling them needs the
`tree-sitter` CLI, which Mason provides — hence Mason before parsers.

**`checktime` cannot run synchronously inside an autocmd** (textlock). The
Claude auto-reload in `lua/config/autocmds.lua` wraps it in `vim.schedule`.

**spaceship's `spaceship::section` API changed.** v4 parses `--color`/`--prefix`
flags with `zparseopts`; the old positional form silently drops the color, which
renders the section invisible. `home/.zsh/spaceship.zsh` uses the flag form.
