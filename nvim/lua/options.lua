vim.o.guicursor = ""

vim.o.number = true
vim.o.signcolumn = "yes:1"
vim.o.wrap = false
vim.o.clipboard = "unnamedplus"
vim.o.termguicolors = true
vim.o.ignorecase = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.list = false
vim.o.swapfile = false
vim.o.backup = false
vim.o.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.o.undofile = true
vim.opt.completeopt = { "menuone", "popup", "noinsert" }
vim.o.winborder = "rounded"
vim.o.pumborder = "rounded"

vim.cmd.filetype("plugin indent on") -- enable filetype detection, plugins and indentation
require('vim._core.ui2').enable()

