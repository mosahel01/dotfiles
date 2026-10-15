vim.g.mapleader = " "
vim.g.maplocalleader = " "

local Keymap = vim.keymap.set

-- Better window navigation
Keymap("n", "<m-h>", "<C-w><C-h>")
Keymap("n", "<m-j>", "<C-w><C-j>")
Keymap("n", "<m-k>", "<C-w><C-k>")
Keymap("n", "<m-l>", "<C-w><C-l>")

-- Better life
Keymap("n", "<Esc>", ":nohl<cr>")

-- Better move around
Keymap("n", "J", "mzJ`z")
Keymap("v", "J", ":m '>+1<CR>gv=gv")
Keymap("v", "K", ":m '<-2<CR>gv=gv")

-- Center when jumping around in search mode
Keymap("n", "<C-d>", "<C-d>zz")
Keymap("n", "<C-u>", "<C-u>zz")
Keymap("n", "n", "nzz")
Keymap("n", "N", "Nzz")
Keymap("n", "*", "*zz")
Keymap("n", "#", "#zz")
Keymap("n", "g*", "g*zz")
Keymap("n", "g#", "g#zz")

-- Stay in indent mode after indenting
Keymap("n", ">", ">gv")
Keymap("n", "<", "<gv")

-- tailwind bearable to work with
Keymap({ "n", "x" }, "j", "gj")
Keymap({ "n", "x" }, "k", "gk")

Keymap("n", "<C-left>", ":vertical resize -2<CR>")
Keymap("n", "<C-right>", ":vertical resize +2<CR>")

Keymap("n", "<C-j>", ":cnext<cr>")
Keymap("n", "<C-k>", ":cprevious<cr>")

-- Escape terminal mode
Keymap("t", "<C-;>", "<C-\\><C-n>")

-- Better replace
Keymap("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
