return {
    "neovim/nvim-lspconfig",
    dependencies = {
        {
            "mason-org/mason.nvim",
            opts = {},
        },
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        -- Ensure Blink is loaded before we request its LSP capabilities.
        "saghen/blink.cmp",
        { "j-hui/fidget.nvim", opts = {} },
    },
    config = function()
        -- Advertise Blink's completion capabilities to language servers.
        -- This includes snippet support, which is needed by some servers (e.g. jsonls).
        local capabilities = require("blink.cmp").get_lsp_capabilities()

        local attach_group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true })
        local highlight_group = vim.api.nvim_create_augroup("user-lsp-highlight", { clear = true })
        local detach_group = vim.api.nvim_create_augroup("user-lsp-detach", { clear = true })

        vim.api.nvim_create_autocmd("LspDetach", {
            group = detach_group,
            callback = function(event)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = highlight_group, buffer = event.buf }
            end,
        })

        vim.api.nvim_create_autocmd("LspAttach", {
            group = attach_group,
            callback = function(event)
                local map = function(keys, func, desc, mode)
                    vim.keymap.set(mode or "n", keys, func, {
                        buffer = event.buf,
                        desc = "LSP: " .. desc,
                    })
                end

                -- Navigation and documentation
                map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
                map("grr", vim.lsp.buf.references, "[G]oto [R]eferences")
                map("grI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
                map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
                map("K", vim.lsp.buf.hover, "Hover Documentation")
                map("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")

                -- Refactoring and code actions
                map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
                map("gra", vim.lsp.buf.code_action, "Code [A]ction", { "n", "x" })

                local client = vim.lsp.get_client_by_id(event.data.client_id)
                if client and client:supports_method("textDocument/documentHighlight", event.buf) then
                    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                        group = highlight_group,
                        buffer = event.buf,
                        callback = vim.lsp.buf.document_highlight,
                    })
                    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                        group = highlight_group,
                        buffer = event.buf,
                        callback = vim.lsp.buf.clear_references,
                    })
                end

                if client and client:supports_method("textDocument/inlayHint", event.buf) then
                    map(
                        "<leader>th",
                        function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }, { bufnr = event.buf }) end,
                        "Toggle Inlay [H]ints"
                    )
                end
            end,
        })

        ---@type table<string, vim.lsp.Config>
        local servers = {
            -- JavaScript and TypeScript
            ts_ls = {},
            eslint = {},

            -- JSON and JSONC: validation, completion, and schema support
            jsonls = {
                settings = {
                    json = {
                        validate = { enable = true },
                        format = { enable = true },
                    },
                },
            },

            -- Web development
            html = {},
            cssls = {},
            svelte = { filetypes = { "svelte" } },
            tailwindcss = {},

            -- Other languages already used in this configuration
            rust_analyzer = {},
            gopls = {},
            pyright = {},

            -- Neovim's Lua configuration
            lua_ls = {
                on_init = function(client)
                    -- Formatting is handled by conform.nvim + StyLua.
                    client.server_capabilities.documentFormattingProvider = false

                    local folder = client.workspace_folders and client.workspace_folders[1]
                    local path = folder and folder.name
                    if path then
                        local has_project_config = vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc")
                        if path ~= vim.fn.stdpath "config" and has_project_config then return end
                    end

                    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
                        runtime = {
                            version = "LuaJIT",
                            path = { "lua/?.lua", "lua/?/init.lua" },
                        },
                        workspace = {
                            checkThirdParty = false,
                            library = {
                                vim.env.VIMRUNTIME,
                                "${3rd}/luv/library",
                                "${3rd}/busted/library",
                            },
                        },
                    })
                end,
                settings = {
                    Lua = {
                        format = { enable = false },
                    },
                },
            },
        }

        -- mason-tool-installer accepts LSP config names when mason-lspconfig is installed.
        -- The remaining entries are standalone formatters/linters, not LSP servers.
        local ensure_installed = vim.tbl_keys(servers)
        vim.list_extend(ensure_installed, {
            "stylua",
            "prettier",
            "markdownlint",
            "clj-kondo",
            "hadolint",
        })

        require("mason-tool-installer").setup {
            ensure_installed = ensure_installed,
        }

        for name, server in pairs(servers) do
            server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
            vim.lsp.config(name, server)
            vim.lsp.enable(name)
        end
    end,
}
