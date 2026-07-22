vim.pack.add({
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/stevearc/dressing.nvim" },
})

require("mason").setup()
require("dressing").setup({
    select = {
        enabled = true,
        backend = {
            "telescope",
        }
    }
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local servers = {
    bashls = {
        capabilities = capabilities,
        filetypes = { "sh", "bash", "zsh" },
        settings = {
            bashIde = {
                globPattern = "*@(.sh|.inc|.bash)",
            },
        },
    },
    clangd = { capabilities = capabilities },
    cssls = { capabilities = capabilities },
    dockerls = { capabilities = capabilities },
    gopls = { capabilities = capabilities },
    html = { capabilities = capabilities },
    jsonls = { capabilities = capabilities },
    lua_ls = {
        capabilities = capabilities,
        settings = {
            Lua = {
                diagnostics = { globals = { "vim" } },
                workspace = { checkThirdParty = false },
                telemetry = { enable = false },
            },
        },
    },
    pyright = {
        capabilities = capabilities,
        settings = {
            python = {
                analysis = {
                    typeCheckingMode = "basic",
                    autoSearchPaths = true,
                    useLibraryCodeForTypes = true,
                    diagnosticMode = "workspace",
                    autoImportCompletions = true,
                },
            },
        },
    },
    rust_analyzer = { capabilities = capabilities },
    ts_ls = { capabilities = capabilities },
    yamlls = { capabilities = capabilities },
}

for server, config in pairs(servers) do
    vim.lsp.config(server, config)
    vim.lsp.enable(server)
end

