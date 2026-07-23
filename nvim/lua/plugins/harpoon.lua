vim.pack.add({
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{
		src = "https://github.com/ThePrimeagen/harpoon",
		name = "harpoon",
		version = "harpoon2", -- harpoon2 branch
	},
})

local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<S-m>", function()
	harpoon:list():add()
end, { desc = "Harpoon add file" })

vim.keymap.set("n", "<leader>hh", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon quick menu" })

vim.keymap.set("n", "<M-h>", function()
	harpoon:list():select(1)
end)
vim.keymap.set("n", "<M-j>", function()
	harpoon:list():select(2)
end)
vim.keymap.set("n", "<M-k>", function()
	harpoon:list():select(3)
end)
vim.keymap.set("n", "<M-l>", function()
	harpoon:list():select(4)
end)
vim.keymap.set("n", "<M-;>", function()
	harpoon:list():select(5)
end)

-- cycle previous and next marked files
vim.keymap.set("n", "<C-S-P>", function()
	harpoon:list():prev()
end)
vim.keymap.set("n", "<C-S-N>", function()
	harpoon:list():next()
end)
