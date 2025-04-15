local lsp = require("lsp-zero")

-- Preset for recommended setttings
lsp.preset("recommended")

-- Ensure necessary LSPs are installed
lsp.ensure_installed({
    "ts_ls",       -- TypeScript and JavaScript
    "eslint",      -- Linting for JS/TS (integrates with `tsserver`)
    "lua_ls",      -- Lua support
    "cssls",       -- CSS support
    "html",        -- HTML support
    "jsonls",      -- JSON support
    "tailwindcss", -- Tailwind CSS support (if you plan to use it)
    "emmet_ls",    -- Emmet snippets for HTML and CSS
})

-- Load friendly snippets (CSS, HTML, JavaScript)
-- require("luasnip.loaders.from_vscode").lazy_load()


-- Setup completion
local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select } -- 🔧 fixed typo here
local cmp_mappings = lsp.defaults.cmp_mappings({
    ['<C-j>'] = cmp.mapping.select_next_item(cmp_select),   -- 🔧 fixed missing >
    ['<C-k>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<Tab>'] = cmp.mapping.select_next_item(cmp_select),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(), -- 🔧 fixed spelling
})

-- Apply the custom mappings
lsp.setup_nvim_cmp({
    mapping = cmp_mappings,
})

-- LSP keybindings
lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }

    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
    vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
    vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
    vim.keymap.set({ 'n', 'x' }, '<leader>cf', function() vim.lsp.buf.format({ async = true }) end, opts)
    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end)

-- Setup LSP
lsp.setup()

-- -- Setup completion with source prioritization
-- lsp.setup_nvim_cmp({
--     mapping = cmp_mappings,
--     sources = {
--         { name = 'nvim_lsp', priority = 100 },                    -- Highest priority (LSP completions)
--         { name = 'buffer',   priority = 90 },                     -- Buffer completions (e.g., previously typed text)
--         { name = 'path',     priority = 80 },                     -- Path completions
--         { name = 'luasnip',  priority = 70, keyword_length = 2 }, -- Snippets (lower priority)
--     },
--     formatting = {
--         fields = { 'kind', 'abbr', 'menu' },
--     },
-- })
--
-- -- Disable snippets for CSS filetype, but keep them in the list
-- cmp.setup.filetype('css', {
--     sources = {
--         { name = 'nvim_lsp', priority = 100 }, -- Highest priority for LSP completions (CSS properties)
--         { name = 'buffer',   priority = 90 },  -- Buffer completions
--         { name = 'path',     priority = 80 },  -- Path completions
--         { name = 'luasnip',  priority = 70 },  -- Snippets (lower priority)
--     },
-- })
