return 	{
		"stevearc/conform.nvim",
        keys = {
            {
                "<leader>lf",
                function()
                    require("conform").format { async = true, lsp_format = "fallback" }
                end,
                mode = "",
            },
        },
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = {
						"ruff_fix",
						"ruff_format",
						"ruff_organize_imports",
					},
					-- Use a sub-list to run only the first available formatter
					-- javascript = { { "prettierd", "prettier" } },
				},
				formatters = {
					ruff_format = {
						command = "ruff",
						args = { "format", "--stdin-filename", "$FILENAME", "-" },
						stdin = true,
					},
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = false,
				},
			})
		end,
	}
