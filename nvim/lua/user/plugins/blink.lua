return {
    "saghen/blink.cmp",
    event = "VimEnter",
    version = "1.*",
    dependencies = {
        {
            "L3MON4D3/LuaSnip",
            version = "v2.*",
            build = (function()
                -- Optional: enables regex features in LuaSnip snippets.
                if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
                    return
                end
                return "make install_jsregexp"
            end)(),
            dependencies = {
                "rafamadriz/friendly-snippets",
            },
            config = function()
                -- Load the community snippet collection (JavaScript, TypeScript, JSON, etc.).
                require("luasnip.loaders.from_vscode").lazy_load()
            end,
        },
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        keymap = {
            preset = "default",
            ["<CR>"] = { "accept", "fallback" },
            ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
            ["<M-Tab>"] = { "select_next", "fallback" },
            ["<M-S-Tab>"] = { "select_prev", "fallback" },
            ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-e>"] = { "hide" },
            ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
        },
        appearance = {
            nerd_font_variant = "mono",
        },
        completion = {
            documentation = {
                auto_show = false,
                auto_show_delay_ms = 500,
            },
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
        snippets = {
            preset = "luasnip",
        },
        fuzzy = {
            implementation = "lua",
        },
        signature = {
            enabled = true,
        },
    },
}
