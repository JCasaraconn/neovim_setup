return {
	"nvim-neo-tree/neo-tree.nvim",
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
		require("maximize").setup({})
		vim.keymap.set("n", "<Leader>m", "<Cmd>lua require('maximize').toggle()<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<leader>nt", ":Neotree filesystem reveal left<CR>", {})
		vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", {})
		vim.cmd([[nnoremap \ :Neotree reveal<cr>]])
	end,
}
