vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.number = true
vim.o.relativenumber = true
vim.o.clipboard = "unnamedplus"

vim.cmd.colorscheme("catppuccin")

vim.keymap.set("n", "-", vim.cmd.Ex)
