return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"williamboman/mason.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	config = function()
		require("mason").setup()
		require("mason-null-ls").setup({
			ensure_installed = { "stylua", "black", "isort", "yamlfmt", "yamllint" },
			automatic_installation = true,
		})
		local null_ls = require("null-ls")
		local conda_prefix = os.getenv("CONDA_PREFIX")
		local mypy_cmd = conda_prefix and (conda_prefix .. "/bin/mypy") or "mypy"

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua, -- Lua formatter
				null_ls.builtins.formatting.black,
				null_ls.builtins.formatting.isort,
				null_ls.builtins.formatting.yamlfmt,
				null_ls.builtins.diagnostics.yamllint, -- YAML linter
				null_ls.builtins.diagnostics.mypy.with({
					command = mypy_cmd,
				}),
			},
		})

		-- Example key mapping for formatting
		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, { desc = "Format code with LSP" })
		local diagnostics_enabled = true

		vim.keymap.set("n", "<leader>td", function()
			diagnostics_enabled = not diagnostics_enabled
			if diagnostics_enabled then
				vim.diagnostic.enable()
				print("Diagnostics Enabled")
			else
				vim.diagnostic.disable()
				print("Diagnostics Disabled")
			end
		end, { desc = "Toggle Diagnostics" })
	end,
}
