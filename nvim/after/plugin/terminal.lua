require("toggleterm").setup({
    size = 12,
    open_mapping = [[<C-\>]],
    hide_numbers = true,
    shade_filetypes = {},
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    insert_mappings = true,
    terminal_mappings = true,
    persist_size = true,
    direction = "float", -- default direction
    close_on_exit = true,
    shell = vim.o.shell,
    float_opts = {
        border = "curved",
        winblend = 3,
    },
})

-- Keybindings for custom layouts
vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Toggle Floating Terminal" })
vim.keymap.set("n", "<leader>tb", "<cmd>ToggleTerm direction=horizontal size=12<cr>", { desc = "Toggle Bottom Terminal" })

-- Optional: keymap to exit terminal mode quickly
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
