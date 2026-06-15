return {
    "stevearc/dressing.nvim",
    config = function ()
        require("dressing").setup({
            input = {
                enabled = true,
            },
            backend = {
                "telescope",
            }
        })
    end
}
