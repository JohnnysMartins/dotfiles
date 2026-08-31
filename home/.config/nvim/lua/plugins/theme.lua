-- Omarchy tokyo-night theme
-- Upstream: basecamp/omarchy @ quattro : themes/tokyo-night/neovim.lua
return {
	{
		"folke/tokyonight.nvim",
		priority = 1000,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight-night",
		},
	},
}
