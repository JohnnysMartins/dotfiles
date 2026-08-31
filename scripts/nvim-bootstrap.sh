#!/bin/bash
#
# Install Neovim plugins, LSP servers and treesitter parsers up front, so the
# first real editing session doesn't stall on downloads.
#
# Order matters: treesitter's `main` branch compiles parsers with the
# tree-sitter CLI, which Mason provides, so Mason has to finish first.
#
# Safe to re-run; every step is idempotent.

set -u

if ! command -v nvim &>/dev/null; then
  echo "==> nvim not found, skipping Neovim bootstrap."
  exit 0
fi

if [[ ! -e "$HOME/.config/nvim/init.lua" ]]; then
  echo "==> ~/.config/nvim not linked yet, skipping Neovim bootstrap."
  exit 0
fi

echo "==> Neovim: $(nvim --version | head -1)"

# LazyVim needs 0.12+ (rustaceanvim hard-requires it).
if ! nvim --headless -c 'lua if vim.fn.has("nvim-0.12") == 0 then vim.cmd("cq") end' -c 'qa' &>/dev/null; then
  echo "!!! Neovim 0.12+ is required (rustaceanvim will not load below that)."
  echo "    macOS: brew upgrade neovim"
  echo "    Arch:  sudo pacman -S neovim"
  exit 1
fi

echo "==> Installing plugins (lazy.nvim)..."
nvim --headless "+Lazy! sync" +qa 2>&1 | grep -iE 'error|fail' || true

export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

echo "==> Waiting for Mason tools (LSP servers, formatters, tree-sitter CLI)..."
# Mason aborts in-flight installs when Neovim exits, so this blocks until every
# package in ensure_installed has landed rather than quitting immediately.
nvim --headless -c "lua
local reg = require('mason-registry')
local cfg = require('lazy.core.config').plugins['mason.nvim']
local want = require('lazy.core.plugin').values(cfg, 'opts', false).ensure_installed or {}
local function pending()
  local out = {}
  for _, name in ipairs(want) do
    local ok, p = pcall(reg.get_package, name)
    if ok and not p:is_installed() then table.insert(out, name) end
  end
  return out
end
vim.wait(900000, function() return #pending() == 0 end, 2000)
local left = pending()
if #left > 0 then print('still missing: ' .. table.concat(left, ', ')) end
" -c "qa" 2>&1 | tail -3

echo "==> Installing treesitter parsers..."
nvim --headless -c "lua
local cfg = require('lazy.core.config').plugins['nvim-treesitter']
local langs = require('lazy.core.plugin').values(cfg, 'opts', false).ensure_installed or {}
if #langs > 0 then require('nvim-treesitter').install(langs):wait(900000) end
print('parsers: ' .. #langs .. ' requested')
" -c "qa" 2>&1 | tail -3

echo ""
echo "==> Neovim bootstrap complete."
echo "    plugins: $(ls -d "$HOME/.local/share/nvim/lazy"/*/ 2>/dev/null | wc -l | tr -d ' ')"
echo "    parsers: $(ls "$HOME/.local/share/nvim/site/parser" 2>/dev/null | wc -l | tr -d ' ')"
echo "    mason:   $(ls "$HOME/.local/share/nvim/mason/packages" 2>/dev/null | wc -l | tr -d ' ')"
