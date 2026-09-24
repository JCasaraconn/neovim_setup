return {
	"mikavilpas/yazi.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = {
		{ "<leader>-", "<cmd>Yazi<cr>", mode = { "n", "v" }, desc = "[Yazi] Open at current file" },
		{ "<leader>cw", "<cmd>Yazi cwd<cr>", desc = "[Yazi] Open in working directory" },
		{ "<leader>yt", "<cmd>Yazi toggle<cr>", desc = "[Yazi] Resume last session" },
	},
	opts = {
		-- neo-tree owns `nvim .`
		open_for_directories = false,
		keymaps = {
			show_help = "<f1>",
		},
	},
}
