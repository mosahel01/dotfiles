return {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
        require("gruvbox").setup {
            -- palette_overrides = {
            --     bright_green = "#990000",
            --     red = "#212122",
            -- },
            terminal_colors = true, -- add neovim terminal colors
            undercurl = true,
            underline = true,
            bold = true,
            italic = {
                strings = false,
                emphasis = false,
                comments = false,
                operators = false,
                folds = true,
            },
            strikethrough = true,
            invert_selection = false,
            invert_signs = false,
            invert_tabline = false,
            inverse = true, -- invert background for search, diffs, statuslines and errors
            contrast = "", -- can be "hard", "soft" or empty string
            overrides = {},
            dim_inactive = false,
            transparent_mode = false,
        }
        vim.cmd "colorscheme gruvbox"
        vim.api.nvim_set_hl(0, "SignColumn", { link = "Normal" })
    end,
}
