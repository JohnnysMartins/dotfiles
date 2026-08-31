return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate window/pane left" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate window/pane down" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate window/pane up" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate window/pane right" },
    },
  },
}
