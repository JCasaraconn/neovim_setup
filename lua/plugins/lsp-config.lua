-- Servers Mason keeps installed; the key set doubles as `ensure_installed`.
local servers = {
	clangd = {
		cmd = { "clangd", "-config-file=~/.config/clangd/config.yaml" },
	},
	gopls = {},
	terraformls = {},
	bashls = {
		settings = {
			bashIde = {
				shfmt = {
					caseIndent = true,
					binaryNextLine = false,
				},
			},
		},
	},
	pylsp = {
		settings = {
			pylsp = {
				plugins = {
					autopep8 = { enabled = false },
					yapf = { enabled = false },
					pycodestyle = { maxLineLength = 88 },
				},
			},
		},
	},
	yamlls = {},
	eslint = {},
	taplo = {},
	stylelint_lsp = {},
}

-- Configured but not in `ensure_installed`; Mason enables them once installed.
local on_demand_servers = {
	html = {
		-- Prettier formats HTML through none-ls; keep the server out of it.
		on_attach = function(client)
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end,
	},
}

local function map_lsp_keys(bufnr)
	local nmap = function(keys, func, desc)
		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "[LSP] " .. desc })
	end

	nmap("<leader>rn", vim.lsp.buf.rename, "Rename")
	nmap("<leader>ca", vim.lsp.buf.code_action, "Code action")

	nmap("gd", vim.lsp.buf.definition, "Goto definition")
	nmap("gr", require("telescope.builtin").lsp_references, "Goto references")
	nmap("gI", vim.lsp.buf.implementation, "Goto implementation")
	nmap("<leader>D", vim.lsp.buf.type_definition, "Type definition")
	nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "Document symbols")
	nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace symbols")

	-- See `:help K` for why this keymap
	nmap("K", vim.lsp.buf.hover, "Hover documentation")
	nmap("<C-k>", vim.lsp.buf.signature_help, "Signature documentation")

	-- Lesser used LSP functionality
	nmap("gD", vim.lsp.buf.declaration, "Goto declaration")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "List workspace folders")

	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		vim.lsp.buf.format()
	end, { desc = "Format current buffer with LSP" })
end

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			vim.lsp.config("*", {
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
			})

			for _, group in ipairs({ servers, on_demand_servers }) do
				for name, config in pairs(group) do
					vim.lsp.config(name, config)
				end
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach-keymaps", { clear = true }),
				callback = function(event)
					map_lsp_keys(event.buf)
				end,
			})
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			ensure_installed = vim.tbl_keys(servers),
			-- stylua ships an LSP mode that lspconfig now has a config for, so
			-- automatic_enable would start it. It is a none-ls formatter here.
			automatic_enable = { exclude = { "stylua" } },
		},
	},
}
