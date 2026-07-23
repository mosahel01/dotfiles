vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/ribru17/bamboo.nvim" },
	{ src = "https://github.com/dgox16/oldworld.nvim" },
	{ src = "https://github.com/askfiy/visual_studio_code" },
	{ src = "https://github.com/martinsione/darkplus.nvim" },
	-- { src = "https://github.com/mofiqul/vscode.nvim", name = "vscode" },
	{ src = "https://github.com/jensenr30/vscode.nvim", name = "jensen_vscode" },
	{
		src = "https://github.com/rose-pine/neovim",
		name = "rose-pine",
	},
})

require("catppuccin").setup({
	transparent_background = true,
	styles = {
		comments = {
			"italic",
		},
		conditionals = {},
		loops = {},
	},
	cmp = true,
	gitsigns = true,
	nvimtree = true,
	notify = false,
	mini = {
		enabled = true,
		indentscope_color = "",
	},
})
require("visual_studio_code").setup({
	mode = "dark",
	preset = true,
	transparent = false,
	expands = {
		hop = true,
		dbui = true,
		lazy = true,
		aerial = true,
		null_ls = true,
		nvim_cmp = true,
		gitsigns = true,
		which_key = true,
		nvim_tree = true,
		lspconfig = true,
		telescope = true,
		bufferline = true,
		nvim_navic = true,
		nvim_notify = true,
		vim_illuminate = true,
		nvim_treesitter = true,
		nvim_ts_rainbow = true,
		nvim_scrollview = true,
		nvim_ts_rainbow2 = true,
		indent_blankline = true,
		vim_visual_multi = true,
	},
	hooks = {
		before = function(conf, colors, utils) end,
		after = function(conf, colors, utils) end,
	},
})
require("bamboo").setup({})
require("kanagawa").setup({})
require("oldworld").setup({})
require("rose-pine").setup({
	dark_variant = "main",
	styles = {
		bold = true,
		italic = false,
		transparency = true,
	},
})

vim.cmd.colorscheme("vscode")
-- vim.cmd.colorscheme("vscode")
-- vim.cmd.colorscheme("visual_studio_code")
-- vim.cmd.colorscheme("catppuccin")
-- vim.cmd.colorscheme("rose-pine")
-- vim.cmd.colorscheme("oldworld")
