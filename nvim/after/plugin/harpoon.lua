
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

-- Harpoon Keymaps
vim.keymap.set("n", "<leader>ha", mark.add_file)
vim.keymap.set("n", "<leader>hh", ui.toggle_quick_menu)
vim.keymap.set("n", "<leader>hn", ui.nav_next)
vim.keymap.set("n", "<leader>hp", ui.nav_prev)

vim.keymap.set("n", "<A-h>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<A-j>", function() ui.nav_file(2) end)
vim.keymap.set("n", "<A-k>", function() ui.nav_file(3) end)
vim.keymap.set("n", "<A-l>", function() ui.nav_file(4) end)

-- Optional: add from netrw using 'ma'
vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function()
		vim.keymap.set("n", "ma", function()
			local filename = vim.fn.expand("<cfile>")
			if filename and filename ~= "" then
				vim.cmd("edit " .. filename)
				mark.add_file()
				print("Harpooned: " .. filename)
			end
		end, { buffer = true })
	end,
})
