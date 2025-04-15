-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"


require("lazy").setup({
    spec = {

        -- Theme:
        -- Rose Pine | Catppuccin Mocha | etc
        { "catppuccin/nvim",  name = "catppuccin", priority = 1000 },
        { "rose-pine/neovim", name = "rose-pine",  config = false, },

        -- Colorizer
        {
            "norcalli/nvim-colorizer.lua",
            lazy = false,
            config = false,
        },

        -- Telescope
        {
            'nvim-telescope/telescope.nvim',
            tag = '0.1.8',
            dependencies = { "nvim-lua/plenary.nvim" },
        },

        -- Treesitter
        {
            "nvim-treesitter/nvim-treesitter",
            build = ":TSUpdate",
        },
        { "nvim-treesitter/playground" },


        -- Nvim-Autopairs
        {
            'windwp/nvim-autopairs',
            event = "InsertEnter",
            config = true
        },


        -- Harpoon
        {
            "theprimeagen/harpoon",
        },

        -- Undo
        {
            -- "mbbill/undotree" ,
            -- "jiaoshijie/undotree",
        },

        -- Git-Status
        {
            "tpope/vim-fugitive",
        },

        -- Surround
        {
            "kylechui/nvim-surround", config = true, event = "VeryLazy",
        },

        -- Oil
        {
            "stevearc/oil.nvim", opts = {}, lazy = false,

        },

        -- Which Key
        {
            "folke/which-key.nvim",
            event = "VeryLazy",
            config = function()
                require("which-key").setup({})
            end,
        },

        -- -- ShowkeysToggle
        -- {
        --     "nvzone/showkeys",
        --     cmd = "ShowkeysToggle",
        --     opts = {
        --         timeout = 1,
        --         maxkeys = 2,
        --     }
        -- },


        -- {
        --     "tamton-aquib/keys.nvim",
        --     config = true,
        -- },

        {
            "NStefan002/screenkey.nvim",
            lazy = false,
            version = "*",
        },


        -- Live Server
        {
            'barrett-ruth/live-server.nvim',
            build = 'npm add -g live-server',
            cmd = { 'LiveServerStart', 'LiveServerStop' },
            config = true
        },

        -- Terminal
        {
            'akinsho/toggleterm.nvim',
            version = "*",
            config = false -- we'll configure it manually in after/plugins
        },

        -- Neotree
        {
            "nvim-neo-tree/neo-tree.nvim",
            branch = "v3.x",
            dependencies = {
                "nvim-lua/plenary.nvim",
                "nvim-tree/nvim-web-devicons",
                "MunifTanjim/nui.nvim",
            },
            cmd = "Neotree",
        },

        -- LSPs
        {
            "VonHeikemen/lsp-zero.nvim",
            branch = "v1.x",
            dependencies = {
                -- LSP Support
                "neovim/nvim-lspconfig",
                "williamboman/mason.nvim",
                "williamboman/mason-lspconfig.nvim",

                -- Autocompletion
                "hrsh7th/nvim-cmp",
                "hrsh7th/cmp-buffer",
                "hrsh7th/cmp-path",
                "saadparwaiz1/cmp_luasnip",
                "hrsh7th/cmp-nvim-lsp",
                "hrsh7th/cmp-nvim-lua",

                -- Snippets
                "L3MON4D3/LuaSnip",
                "rafamadriz/friendly-snippets",
            }
        },


        -- Lazy config
        -- install = { colorscheme = { "habamax" } },
        checker = { enabled = true },
    }
})
