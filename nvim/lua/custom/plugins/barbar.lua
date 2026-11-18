vim.pack.add {
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/romgrk/barbar.nvim' },
}

vim.g.barbar_auto_setup = false

require('barbar').setup {
  animation = false,
  auto_hide = false,
  clickable = true,
  icons = {
    buffer_index = false,
    buffer_number = false,
    button = '',
    diagnostics = {
      [vim.diagnostic.severity.ERROR] = { enabled = true },
      [vim.diagnostic.severity.WARN] = { enabled = true },
      [vim.diagnostic.severity.INFO] = { enabled = false },
      [vim.diagnostic.severity.HINT] = { enabled = false },
    },
    filetype = {
      enabled = true,
    },
    separator = {
      left = '',
      right = '',
    },
  },
}

-- Navigate between buffers
vim.keymap.set('n', '<Tab>', '<Cmd>BufferNext<CR>', {
  desc = 'Next buffer',
})

vim.keymap.set('n', '<S-Tab>', '<Cmd>BufferPrevious<CR>', {
  desc = 'Previous buffer',
})
