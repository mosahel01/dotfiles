local options = {
formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    javascript = { "prettierd" },
    typescript = { "prettierd" },
    
    -- Added for React/TSX workflow
    javascriptreact = { "prettierd" },
    typescriptreact = { "prettierd" },
    
    -- Common TS ecosystem config & data formats
    json = { "prettierd" },
    jsonc = { "prettierd" }, -- Crucial for tsconfig.json files
    markdown = { "prettierd" },
    yaml = { "prettierd" },
    graphql = { "prettierd" },
  },

  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
