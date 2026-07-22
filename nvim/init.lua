require("options")
require("keymaps")
require("autocmds")

local plugin_dir = vim.fn.stdpath("config") .. "/lua/plugins"

for _, file in ipairs(vim.fn.readdir(plugin_dir)) do
    if file:match("%.lua$") then
        local module = file:gsub("%.lua$", "")
        require("plugins." .. module)
    end
end
