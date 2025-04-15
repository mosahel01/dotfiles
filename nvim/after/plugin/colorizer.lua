-- Setup for `nvim-colorizer.lua`
require("colorizer").setup({
    "*",                                                   -- Automatically apply to all filetypes
    css = { rgb_fn = true, RRGGBB = true },                -- Enable for CSS filetypes
    html = { names = true, rgb_fn = true, RRGGBB = true }, -- Enable for HTML
    -- tailwind = true,                                       -- Enable for Tailwind
    -- rgb_fn = true,                                         -- Enable RGB function support
})
