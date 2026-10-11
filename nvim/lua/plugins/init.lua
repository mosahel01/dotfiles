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

    {
        "Wansmer/treesj",
        keys = {
            { "<leader>tt", "<cmd>TSJToggle<cr>", desc = "Toggle split/join code block" },
        },
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        opts = {
            use_default_keymaps = false,
            max_join_indent_length = 120,
        },
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
                "javascript",
                "typescript",
                "tsx",
                "jsdoc",
                "json",
                "jsonc",
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
