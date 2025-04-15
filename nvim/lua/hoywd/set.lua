vim.g.mapleader = " "

vim.opt.termguicolors = true
vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

-- vim.opt.clipboard.append("unnamedplus")
-- vim.opt.colorcolumn = "200"
vim.opt.colorcolumn = ""

vim.opt.wrap = false
vim.opt.cmdheight = 0

vim.opt.swapfile = false
vim.opt.backup = false
-- use with undotree plugin
-- vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
-- vim.opt.undofile = true
vim.opt.undofile = false

vim.opt.hlsearch = false
vim.opt.incsearch = true


vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.g.markdown_recommended_style = 0



-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
})
