return {
	"nvimtools/none-ls.nvim",
	event = { "BufReadPre", "BufNewFile" }, -- load the plugin when entering a buffer
	config = function()
		local null_ls = require("null-ls")
		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua, -- formatter for lua
				null_ls.builtins.formatting.yapf.with({
					args = { "--style=pep8" },
				}), -- formatter for python
				null_ls.builtins.formatting.isort, -- sort imports for python
				null_ls.builtins.formatting.prettier, -- formatter for lots of files
				null_ls.builtins.formatting.beautysh, -- formatter for shell
				null_ls.builtins.diagnostics.flake8, -- linter for python
				null_ls.builtins.diagnostics.yamllint, -- linter for yaml
				null_ls.builtins.diagnostics.shellcheck, -- linter for bash
			},
		})

		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
	end,
}
