vim.pack.add({
	{
		src = "https://github.com/nvim-tree/nvim-web-devicons",
		name = "nvim-web-devicons",
	},
	{
		src = "https://github.com/nvim-tree/nvim-tree.lua",
		name = "nvimtree",
	},
})

---@type nvim_tree.config
local config = {
	sort = {
		sorter = "case_sensitive",
	},
	view = {
		width = 32,
		side = "right",
	},
	renderer = {
		highlight_git = true,
		group_empty = true,
		icons = {
			show = {
				file = true,
				folder = true,
				folder_arrow = true,
				git = true,
				modified = true,
				hidden = false,
				diagnostics = true,
				bookmarks = true,
			},
		},
	},
	filters = {
		dotfiles = true,
	},
	git = {
		enable = true,
	},
}

vim.keymap.set("n", "<leader>ee", ":NvimTreeToggle<CR>", opts)

require("nvim-tree").setup(config)
