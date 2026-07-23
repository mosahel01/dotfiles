vim.pack.add({
	{
		src = "https://github.com/stevearc/conform.nvim",
	},
})

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		-- python = { "isort", "black" }, -- ruff is faster
		python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
		json = { "biome", "prettierd", "prettier", stop_after_first = true },
		sh = { "shfmt" },
		bash = { "shfmt" },
		["_"] = { "trim_whitespace" }, -- use "_" to run formatters on filetypes that don't match any above
	},

	-- automatically format when saving a buffer
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback", -- use LSP formatter if tool in formatters_by_ft isn't installed
	},

	-- options for formatters
	formatters = {
		shfmt = {
			prepend_args = { "-i", "2" }, -- indent with 2 spaces for shell scripts
		},
	},
})

vim.keymap.set({ "n", "v" }, "<leader>lf", function()
	require("conform").format({
		lsp_format = "fallback",
		async = false,
		timeout_ms = 500,
	})
end, { desc = "Format file or range (in visual mode)" })
