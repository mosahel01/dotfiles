vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})

require("nvim-treesitter").setup({
	ensure_installed = {
		"lua",
		"bash",
		"html",
		"css",
		"javascript",
		"typescript",
		"tsx",
		"json",
		"json5",
		"yaml",
		"toml",
		"python",
		"rust",
		"go",
		"c",
		"cpp",
		"java",
		"markdown",
		"markdown_inline",
		"regex",
		"query",
		"git_config",
		"gitcommit",
		"gitignore",
		"dockerfile",
		"sql",
	},

	highlight = {
		enable = true,
	},

	indent = {
		enable = true,
	},
})
