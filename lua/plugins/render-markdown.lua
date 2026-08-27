return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		-- obsidian.nvim renders vault notes; leave those buffers untouched so the two
		-- renderers never draw over each other.
		ignore = function(buf)
			local vault = vim.fs.normalize(require("vault"))
			local path = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
			return path:sub(1, #vault + 1) == vault .. "/"
		end,
		heading = { width = "block" },
		code = { width = "block" },
		sign = { enabled = false },
		latex = { enabled = false },
	},
	config = function(_, opts)
		require("render-markdown").setup(opts)
		vim.keymap.set(
			"n",
			"<leader>mp",
			"<cmd>RenderMarkdown buf_toggle<cr>",
			{ silent = true, desc = "[Markdown] Toggle rendered preview" }
		)
	end,
}
