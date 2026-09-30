return {
    {
        "stevearc/conform.nvim",
        event = "BufWritePre", -- uncomment for format on save
        opts = require "configs.conform",
    },

    -- These are some examples, uncomment them if you want to see them work!
    {
        "neovim/nvim-lspconfig",
        config = function()
            require "configs.lspconfig"
        end,
    },

    -- test new blink
    { import = "nvchad.blink.lazyspec" },

    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "vim",
                "lua",
                "vimdoc",
                "html",
                "css",
            },
        },
    },

    {
        "lukas-reineke/indent-blankline.nvim",
        enable = false,
        opts = {
            indent = {
                char = " ",
            },
            scope = {
                enabled = false,
            },
        },
    },

    {
        "stevearc/oil.nvim",
        ---@module 'oil'
        ---@type oil.SetupOpts
        opts = {},
        -- Optional dependencies (e.g., for file icons)
        dependencies = { "nvim-tree/nvim-web-devicons" },
        lazy = false,
        config = function()
            require("oil").setup {
                default_file_explorer = true, -- Replaces netrw completely
                skip_confirm_for_simple_edits = true,
                view_options = {
                    show_hidden = true,
                },
            }
        end,
    },
}
