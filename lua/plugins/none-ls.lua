return {
	"nvimtools/none-ls.nvim",
	config = function()
		local null_ls = require("null-ls")
		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua, -- Lua formatter
				null_ls.builtins.formatting.prettier, -- Formatter for various files
				null_ls.builtins.diagnostics.yamllint, -- YAML linter
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
