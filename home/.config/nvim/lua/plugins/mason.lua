return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      -- hadolint publishes no arm64 release, so Mason pulls a ~99MB x86 binary
      -- that never finished on this connection. Installed natively via
      -- `brew install hadolint` instead; nvim-lint finds it on PATH.
      opts.ensure_installed = vim.tbl_filter(function(pkg)
        return pkg ~= "hadolint"
      end, opts.ensure_installed or {})
    end,
  },
}
