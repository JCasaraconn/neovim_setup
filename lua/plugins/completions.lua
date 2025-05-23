return {
	{
		"hrsh7th/cmp-nvim-lsp",
		lazy = true, -- we let nvim-cmp load this for us
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"neovim/nvim-lspconfig",
		},
	},
	{
		"L3MON4D3/LuaSnip",
		lazy = true, -- we let nvim-cmp load this too
		dependencies = {
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
	},
	{
		"hrsh7th/nvim-cmp",
		--event = "InsertEnter", -- load cmp after entering insert mode
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						print("Completion window visible:", cmp.visible())
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" }, -- For luasnip users.
				}, {
					{ name = "buffer" },
				}),
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Configure jedi-language-server
			lspconfig.python_lsp_server.setup({
				capabilities = capabilities,
				on_attach = function(client, bufnr)
					-- Example: Keymaps for LSP navigation
					local opts = { noremap = true, silent = true, buffer = bufnr }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
					vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, opts)
				end,
			})
		end,
	},
	{
		dir = "~/.config/nvim/lua/plugins/jedi-cmp", -- local plugin path
		ft = { "yaml", "yml" },
		config = function()
			local cmp = require("cmp")
			cmp.setup.filetype({ "yaml", "yml" }, {
				sources = {
					{ name = "jedi" },
					{ name = "buffer" },
					{ name = "path" },
				},
			})
		end,
	},
}
