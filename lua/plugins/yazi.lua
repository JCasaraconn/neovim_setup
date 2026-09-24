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
		hooks = {
			-- yazi skips the cwd file on Q (quit --no-cwd-file), which change_neovim_cwd_on_close ignores
			yazi_closed_successfully = function(chosen_file, config, state)
				if chosen_file == nil and vim.uv.fs_stat(config.cwd_file_path) then
					vim.cmd.cd(state.last_directory.filename)
				end
			end,
		},
	},
}
