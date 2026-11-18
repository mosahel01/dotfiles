-- Install Snacks using native vim.pack
vim.pack.add {
  { src = 'https://github.com/folke/snacks.nvim' },
}

-- Snacks configuration
require('snacks').setup {
  -- Explorer
  explorer = {
    enabled = true,
  },

  -- Picker (required by Explorer)
  picker = {
    enabled = true,

    sources = {
      explorer = {
        layout = {
          preset = 'sidebar',
          preview = true,
          layout = {
            position = 'right',
          },
        },
      },
    },
  },

  -- Disable everything else
  animate = { enabled = false },
  bigfile = { enabled = false },
  dashboard = { enabled = false },
  dim = { enabled = false },
  git = { enabled = false },
  gitbrowse = { enabled = false },
  gh = { enabled = false },
  image = { enabled = false },
  indent = { enabled = false },
  input = { enabled = false },
  lazygit = { enabled = false },
  notifier = { enabled = false },
  quickfile = { enabled = false },
  scope = { enabled = false },
  scratch = { enabled = false },
  scroll = { enabled = false },
  statuscolumn = { enabled = false },
  terminal = { enabled = false },
  toggle = { enabled = false },
  words = { enabled = false },
  zen = { enabled = false },
}

-- ==========================================
-- KEYMAPS
-- ==========================================

local map = vim.keymap.set

-- Explorer
map('n', '<leader>e', function() Snacks.explorer() end, { desc = 'File Explorer' })

-- Find
map('n', '<leader>ff', function() Snacks.picker.files() end, { desc = 'Find Files' })
map('n', '<leader>fg', function() Snacks.picker.grep() end, { desc = 'Live Grep (Project)' })
map({ 'n', 'x' }, '<leader>fw', function() Snacks.picker.grep_word() end, { desc = 'Find Word Under Cursor / Selection' })
map('n', '<leader>fG', function() Snacks.picker.git_files() end, { desc = 'Find Git Files' })
map('n', '<leader>fb', function() Snacks.picker.buffers() end, { desc = 'Find Buffers' })
map('n', '<leader>fr', function() Snacks.picker.recent() end, { desc = 'Recent Files' })
map('n', '<leader>fp', function() Snacks.picker.projects() end, { desc = 'Find Projects' })
map('n', '<leader>/', Snacks.picker.lines, { desc = 'find within current buffer' })
map('n', '<leader>fn', function()
  Snacks.picker.files {
    cwd = vim.fn.stdpath 'config',
  }
end, { desc = 'Find Neovim Config' })

-- Search
map('n', '<leader>f/', function() Snacks.picker.grep_buffers() end, { desc = 'Search Open Buffers' })
map('n', '<leader>f:', function() Snacks.picker.command_history() end, { desc = 'Command History' })
map('n', '<leader>fR', function() Snacks.picker.resume() end, { desc = 'Resume Last Picker' })

-- LSP
map('n', '<leader>fs', function() Snacks.picker.lsp_symbols() end, { desc = 'Document Symbols' })
map('n', '<leader>fS', function() Snacks.picker.lsp_workspace_symbols() end, { desc = 'Workspace Symbols' })
map('n', '<leader>fd', function() Snacks.picker.diagnostics() end, { desc = 'Diagnostics' })
map('n', '<leader>fh', function() Snacks.picker.help() end, { desc = 'Help Pages' })

-- Neovim
map('n', '<leader>fk', function() Snacks.picker.keymaps() end, { desc = 'Find Keymaps' })
map('n', '<leader>fC', function() Snacks.picker.commands() end, { desc = 'Find Commands' })
map('n', '<leader>fu', function() Snacks.picker.undo() end, { desc = 'Undo History' })

-- LSP pickers
map('n', 'grr', Snacks.picker.lsp_references, { desc = 'Goto References' })
map('n', 'gri', Snacks.picker.lsp_implementations, { desc = 'Goto Implementations' })
map('n', 'grd', Snacks.picker.lsp_definitions, { desc = 'Goto Definitions' })
map('n', 'gO', Snacks.picker.lsp_symbols, { desc = 'Document Symbols' })
map('n', 'gW', Snacks.picker.lsp_workspace_symbols, { desc = 'Workspace Symbols' })
map('n', 'grt', Snacks.picker.lsp_type_definitions, { desc = 'Type Definitions' })
