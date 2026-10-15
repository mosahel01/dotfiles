-- Linting for languages not already handled by a language server.
-- JavaScript/TypeScript lint diagnostics come from the ESLint LSP (eslint).
-- JSON syntax/schema diagnostics come from jsonls, so jsonlint is not duplicated here.

---@module 'lazy'
---@type LazySpec
return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local lint = require("lint")

        lint.linters_by_ft = {
            markdown = { "markdownlint" },
            clojure = { "clj-kondo" },
            dockerfile = { "hadolint" },
        }

        local lint_group = vim.api.nvim_create_augroup("user-lint", { clear = true })
        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            group = lint_group,
            callback = function()
                -- Avoid running linters in non-editable buffers such as LSP help popups.
                if vim.bo.modifiable and vim.bo.buftype == "" then
                    lint.try_lint()
                end
            end,
        })
    end,
}
