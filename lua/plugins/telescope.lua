return {
	{
		"nvim-telescope/telescope-ui-select.nvim",
		lazy = true,
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").setup({
				defaults = {
					mappings = {
						i = {
							["<C-u>"] = false,
							["<C-d>"] = false,
						},
					},
				},

				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			-- Enable telescope fzf native, if installed
			pcall(require("telescope").load_extension, "fzf")

			-- See `:help telescope.builtin`
			vim.keymap.set(
				"n",
				"<leader>?",
				require("telescope.builtin").oldfiles,
				{ desc = "[Telescope] Recent files" }
			)
			vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers, { desc = "[Telescope] Open buffers" })
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to telescope to change theme, layout, etc.
				require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[Telescope] Fuzzy in buffer" })

			vim.keymap.set("n", "<leader>sf", require("telescope.builtin").find_files, { desc = "[Telescope] Search files" })
			vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[Telescope] Search help" })
			vim.keymap.set("n", "<leader>sw", require("telescope.builtin").grep_string, { desc = "[Telescope] Search current word" })
			vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[Telescope] Live grep" })
			vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics, { desc = "[Telescope] Search diagnostics" })

			require("telescope").load_extension("ui-select")
		end,
	},
}
