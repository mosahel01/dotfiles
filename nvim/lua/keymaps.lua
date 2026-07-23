local map = vim.keymap.set
local opts = { silent = true }

vim.g.mapleader = " "

-- lsp
map("n", "grd", vim.lsp.buf.definition, { desc = "Go to definition" }, opts)

-- cd to current file's directory
map("n", "<leader>cd", vim.fn.chdir(vim.fn.expand("%:p:h")), opts)

-- move lines
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- center
map("n", "J", "mzJ`z", opts)
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- replace word under cursor
map("n", "<leader>rn", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], opts)

-- better move around
map("n", "<C-h>", "<C-w><C-h>", opts)
map("n", "<C-j>", "<C-w><C-j>", opts)
map("n", "<C-k>", "<C-w><C-k>", opts)
map("n", "<C-l>", "<C-w><C-l>", opts)
