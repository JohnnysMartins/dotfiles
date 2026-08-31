-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- ── Working alongside Claude Code ────────────────────────────────────────────
-- Claude writes files on disk while they are open in a buffer here. LazyVim
-- already runs checktime on FocusGained/TermClose/TermLeave; this adds the
-- idle case, so a buffer refreshes while you are just sitting in nvim.
vim.opt.autoread = true

vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("claude_checktime", { clear = true }),
  callback = function()
    -- checktime reloads buffers, which is not allowed synchronously inside
    -- an autocmd callback (textlock), so defer it to the main loop.
    if vim.bo.buftype == "" and vim.fn.filereadable(vim.api.nvim_buf_get_name(0)) == 1 then
      vim.schedule(function()
        pcall(vim.cmd, "checktime")
      end)
    end
  end,
})

-- Say so, rather than silently swapping content underfoot.
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = vim.api.nvim_create_augroup("claude_reload_notify", { clear = true }),
  callback = function()
    vim.notify("File changed on disk — buffer reloaded", vim.log.levels.WARN)
  end,
})
