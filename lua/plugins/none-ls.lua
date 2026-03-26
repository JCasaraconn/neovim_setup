return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"williamboman/mason.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	config = function()
		require("mason").setup()
		require("mason-null-ls").setup({
			ensure_installed = {
				"stylua",
				"black",
				"isort",
				"gofumpt",
				"golangci_lint",
				"shfmt",
				"shellcheck",
				"prettier",
				"sqlfluff",
				"markdownlint",
			},
			automatic_installation = true,
		})
		local null_ls = require("null-ls")
		local conda_prefix = os.getenv("CONDA_PREFIX")
		local mypy_cmd = conda_prefix and (conda_prefix .. "/bin/mypy") or "mypy"

		null_ls.setup({
			should_attach = function(bufnr)
				return not vim.api.nvim_buf_get_name(bufnr):match("^fugitive://")
			end,
			sources = {
				-- Lua
				null_ls.builtins.formatting.stylua,
				-- Python
				null_ls.builtins.formatting.black,
				null_ls.builtins.formatting.isort.with({
					extra_args = { "--profile", "black" },
				}),
				null_ls.builtins.diagnostics.mypy.with({
					command = mypy_cmd,
					cwd = function()
						return vim.fn.getcwd()
					end,
				}),
				-- Go
				null_ls.builtins.formatting.gofumpt,
				null_ls.builtins.diagnostics.golangci_lint,
				-- Terraform
				null_ls.builtins.formatting.terraform_fmt,
				-- Bash (shellcheck diagnostics provided by bashls LSP)
				null_ls.builtins.formatting.shfmt.with({
					extra_args = { "-i", "0", "-ci" },
				}),
				-- shellharden is not in Mason — uses system binary
				null_ls.builtins.formatting.shellharden,
				-- JS, JSON, YAML, Markdown, CSS, HTML
				null_ls.builtins.formatting.prettier,
				-- CSS
				null_ls.builtins.diagnostics.stylelint,
				-- SQL
				null_ls.builtins.formatting.sqlfluff.with({
					extra_args = { "--dialect", "postgres" },
				}),
				null_ls.builtins.diagnostics.sqlfluff.with({
					extra_args = { "--dialect", "postgres" },
				}),
				-- TOML: handled by taplo LSP in lsp-config.lua
				-- Markdown
				null_ls.builtins.diagnostics.markdownlint,
			},
		})

		-- Example key mapping for formatting
		vim.keymap.set("n", "<leader>gf", function()
			vim.lsp.buf.format({ timeout_ms = 10000 })
		end, { desc = "Format code with LSP" })
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
