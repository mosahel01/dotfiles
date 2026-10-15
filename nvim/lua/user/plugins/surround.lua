return {
    "kylechui/nvim-surround",
    version = "^4.0.0", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    -- Optional: See `:h nvim-surround.configuration` and `:h nvim-surround.setup` for details
    config = function()
        require("nvim-surround").setup {
            --   surr*ound_words             ysiw)           (surround_words)
            --   surr*ound_words             ysiw(           ( surround_words )
            --   *make strings               ys$"            "make strings"
            --   [delete ar*ound me!]        ds]             delete around me!
            --   remove <b>HTML t*ags</b>    dst             remove HTML tags
            --   'change quot*es'            cs'"            "change quotes"
            --   <b>or tag* types</b>        csth1<CR>       <h1>or tag types</h1>
            --   delete(functi*on calls)     dsf             function calls
        }
    end,
}
