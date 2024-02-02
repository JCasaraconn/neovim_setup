return {
	"nvimtools/none-ls.nvim",
	event = { "BufReadPre", "BufNewFile" }, -- load the plugin when entering a buffer
	config = function()
		local null_ls = require("null-ls")
		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.yapf,
				null_ls.builtins.formatting.isort,
				null_ls.builtins.diagnostics.flake8,
			},
		})

		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
	end,
}
