return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"mason-org/mason.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	config = function()
		require("mason-null-ls").setup({
			ensure_installed = {
				-- stylua is deliberately absent: Mason picks the linux_x64_gnu
				-- asset, which needs glibc 2.32 while this host has 2.31, and a
				-- version pin here cannot survive a Mason update-all. The static
				-- musl build lives in ~/.local/bin instead:
				--   curl -Lo /tmp/s.zip https://github.com/JohnnyMorganz/StyLua/releases/latest/download/stylua-linux-x86_64-musl.zip
				--   unzip -p /tmp/s.zip stylua > ~/.local/bin/stylua && chmod +x ~/.local/bin/stylua
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
					-- none-ls can orphan mypy's shadow copies when nvim quits, so keep them out of the repo
					temp_dir = vim.fs.dirname(vim.fn.tempname()),
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
		end, { desc = "[Formatting] Format code" })
		vim.keymap.set("n", "<leader>td", function()
			local enabled = not vim.diagnostic.is_enabled()
			vim.diagnostic.enable(enabled)
			print(enabled and "Diagnostics Enabled" or "Diagnostics Disabled")
		end, { desc = "[Diagnostics] Toggle diagnostics" })
	end,
}
