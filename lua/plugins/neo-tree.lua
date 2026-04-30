return {
	"nvim-neo-tree/neo-tree.nvim",
	event = "VimEnter",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
		"declancm/maximize.nvim",
	},
	config = function()
		require("neo-tree").setup({
			close_if_last_window = false,
			sort_by = "case_sensitive",
			renderer = {
				group_empty = true,
			},
			filters = {
				dotfiles = true,
			},
			filesystem = {
				window = {
					mappings = {
						["ga"] = "git_add_file",
						["gu"] = "git_unstage_file",
						["gA"] = "git_add_all",
						["gr"] = "git_revert_file",
						["gc"] = "git_commit",
						["gp"] = "git_push",
						["gg"] = "git_commit_and_push",
					},
				},
			},
		})
		require("nvim-web-devicons").setup({
			override = {
				zsh = {
					icon = "",
					color = "#428850",
					cterm_color = "65",
					name = "Zsh",
				},
			},
			color_icons = true,
			default = true,
			strict = true,
			override_by_filename = {
				[".gitignore"] = {
					icon = "",
					color = "#f1502f",
					name = "Gitignore",
				},
			},
			override_by_extension = {
				["log"] = {
					icon = "",
					color = "#81e043",
					name = "Log",
				},
				["txt"] = {
					icon = "",
					color = "#b0b0b0",
					name = "default",
				},
			},
		})
		vim.keymap.set("n", "<leader>nt", ":Neotree toggle<CR>", { desc = "[Neo-tree] Toggle file tree" })
		vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", { desc = "[Neo-tree] Buffers float" })
	end,
}
