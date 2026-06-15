return {
    -- lazy
    {
        "askfiy/visual_studio_code",
        priority = 100,
        config = function()
            vim.cmd([[colorscheme visual_studio_code]])
        end,
    },

    -- "ellisonleao/gruvbox.nvim",
    -- priority = 1000,
    -- config = function()
        -- 	require("gruvbox").setup({
            -- 		-- Optional configuration
            -- 		terminal_colors = true, -- add neovim terminal colors
            -- 		undercurl = true,
            -- 		underline = true,
            -- 		bold = true,
            -- 		italic = {
                -- 			strings = true,
                -- 			emphasis = true,
                -- 			comments = true,
                -- 			operators = false,
                -- 			folds = true,
                -- 		},
                -- 		strikethrough = true,
                -- 		invert_selection = false,
                -- 		invert_signs = false,
                -- 		invert_tabline = false,
                -- 		invert_intend_guides = false,
                -- 		inverse = true, -- invert background for search, diffs, statuslines and errors
                -- 		contrast = "", -- can be "hard", "soft" or empty string
                -- 		palette_overrides = {},
                -- 		overrides = {
                    -- 			-- Make functions italic
                    -- 			["@function"] = { italic = true },
                    -- 			["@function.call"] = { italic = true, bold = true, fg = "#90D5FF" },
                    -- 			["@method"] = { italic = true },
                    -- 			["@method.call"] = { italic = true, bold = true },
                    -- 			["Function"] = { italic = true },
                    -- 			["@function.builtin"] = { italic = true },
                    -- 			["@constructor"] = { italic = true },
                    -- 		},
                    -- 		dim_inactive = false,
                    -- 		transparent_mode = false,
                    -- 	})
                    --
                    -- 	-- Set the colorscheme
                    -- 	vim.cmd("colorscheme gruvbox")
                    -- end,
                }
