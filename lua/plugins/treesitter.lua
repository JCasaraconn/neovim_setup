return {
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufReadPre", "BufNewFile" }, -- load when a buffer is opened or created
		build = ":TSUpdate",
		config = function()
			local config = require("nvim-treesitter.configs")
			config.setup({
				-- Add languages to be installed here that you want installed for treesitter
				ensure_installed = {
					"c",
					"cpp",
					"go",
					"lua",
					"python",
					"rust",
					"tsx",
					"typescript",
					"vim",
					"terraform",
					"hcl",
					"bash",
					"javascript",
					"json",
					"sql",
					"yaml",
					"markdown",
					"markdown_inline",
					"css",
					"html",
					"toml",
				},

				-- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
				auto_install = true,

				highlight = { enable = true },
				indent = { enable = true },
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<c-space>",
						node_incremental = "<c-space>",
						scope_incremental = "<c-s>",
						node_decremental = "<BS>",
					},
				},
			})
			-- nvim-treesitter master stops at Neovim 0.11 and registers its query
			-- directives with `all = false`, an option 0.12 removed. Handlers now get a
			-- list of nodes instead of one, so this directive throws and aborts every
			-- injection in the buffer -- a single fenced code block leaves the whole
			-- markdown file unhighlighted and unrendered.
			-- TODO(nvim-treesitter-main-migration): drop when treesitter moves to `main`.
			require("nvim-treesitter.query_predicates")
			local info_string_aliases = { ex = "elixir", pl = "perl", sh = "bash", uxn = "uxntal", ts = "typescript" }
			vim.treesitter.query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
				local node = match[pred[2]]
				node = type(node) == "table" and node[1] or node
				if not node then
					return
				end
				local alias = vim.treesitter.get_node_text(node, bufnr):lower()
				metadata["injection.language"] = vim.filetype.match({ filename = "a." .. alias })
					or info_string_aliases[alias]
					or alias
			end, { force = true })

			-- Diagnostic display
			vim.diagnostic.config({
				virtual_lines = true,
				virtual_text = false,
				underline = false,
			})

			-- Diagnostic keymaps
			if vim.diagnostic.jump then
				vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "[Diagnostics] Previous diagnostic" })
				vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "[Diagnostics] Next diagnostic" })
			else
				vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "[Diagnostics] Previous diagnostic" })
				vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "[Diagnostics] Next diagnostic" })
			end
			vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "[Diagnostics] Open float" })
			vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "[Diagnostics] Open list" })
		end,
	},
}
