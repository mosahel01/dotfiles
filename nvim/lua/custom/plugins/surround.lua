vim.pack.add({ {
    src = "https://github.com/kylechui/nvim-surround",
    version = vim.version.range("4.x"), -- Use for stability; omit to use `main` branch for the latest features
} })

-- Optional: See `:h nvim-surround.configuration` and `:h nvim-surround.setup` for details
require("nvim-surround").setup({
    -- Put your configuration here
})
