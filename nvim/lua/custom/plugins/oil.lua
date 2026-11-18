vim.pack.add({
    'https://github.com/stevearc/oil.nvim',
})

vim.keymap.set("n", "-", "<cmd>Oil<cr>")
require('oil').setup({})
