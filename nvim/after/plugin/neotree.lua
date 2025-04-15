vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])

-- Keybinding to toggle Neo-tree
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle Neo-tree" })

require("neo-tree").setup({
  filesystem = {
    follow_current_file = { enabled = true },
    hijack_netrw_behavior = "open_default",
    use_libuv_file_watcher = true,
  },
  window = {
    mappings = {
      ["l"] = "open",         -- Expand directory or open file
      ["h"] = "close_node",   -- Collapse directory
      ["e"] = "",             -- Unbind if necessary
    },
  },
  default_component_configs = {
    indent = {
      with_expanders = true,
    },
  },
})

