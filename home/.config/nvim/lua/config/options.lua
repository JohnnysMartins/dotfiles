-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- LazyVim's python extra defaults to pyright; use basedpyright instead (it is
-- the maintained fork with stricter inference, and is what Mason installed).
vim.g.lazyvim_python_lsp = "basedpyright"
