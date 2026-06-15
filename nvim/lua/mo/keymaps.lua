vim.g.mapleader = " "
vim.g.maplocalleader = " " 

vim.keymap.set("n", "-", vim.cmd.Oil)
vim.keymap.set("n", "<Esc>", vim.cmd.nohl)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "J", "mzJ`z")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<", "<gv")
vim.keymap.set("n", ">", ">gv")

vim.keymap.set("n", "=ap", "ma=ap'a")
vim.keymap.set("n", "<leader>rn", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

