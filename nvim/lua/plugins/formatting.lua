vim.pack.add({
    {
        src = "https://github.com/stevearc/conform.nvim"
    }
})


require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "black" }, -- conform will run multiple formatters sequentially
    rust = { "rustfmt", lsp_format = "fallback" }, -- you can customize some of the format options for the filetype (:help conform.format)
    javascript = { "prettierd", "prettier", stop_after_first = true }, -- conform will run the first available formatter
  },
})
