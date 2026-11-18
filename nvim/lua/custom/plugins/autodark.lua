-- 1. Install plugins using Neovim 0.12 built-in vim.pack
vim.pack.add {
  'https://github.com/f-person/auto-dark-mode.nvim',
  'https://github.com/folke/tokyonight.nvim', -- Replace with your theme(s)
}

-- 2. Configure auto-dark-mode to watch GNOME's appearance setting
require('auto-dark-mode').setup {
  update_interval = 1000, -- Checks GNOME portal every 1000ms
  set_dark_mode = function()
    vim.api.nvim_set_option_value('background', 'dark', {})
    vim.cmd 'colorscheme tokyonight-night' -- Your dark theme
  end,
  set_light_mode = function()
    vim.api.nvim_set_option_value('background', 'light', {})
    vim.cmd 'colorscheme tokyonight-day' -- Your light theme
  end,
}
