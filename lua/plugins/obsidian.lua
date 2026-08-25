return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	-- Upstream requires Neovim >= 0.11. This machine runs a 0.10.0-dev build where
	-- the plugin errors on load (vim.iter():flatten() is absent), so stay inert
	-- until Neovim is upgraded rather than breaking every startup.
	cond = vim.fn.has("nvim-0.11") == 1,
	ft = "markdown",
	cmd = "Obsidian",
	keys = {
		{ "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "[Obsidian] Quick switch note" },
		{ "<leader>on", "<cmd>Obsidian new<cr>", desc = "[Obsidian] New note" },
		{ "<leader>os", "<cmd>Obsidian search<cr>", desc = "[Obsidian] Search vault" },
		{ "<leader>ot", "<cmd>Obsidian today<cr>", desc = "[Obsidian] Today's daily note" },
		{ "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "[Obsidian] Yesterday's daily note" },
		{ "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "[Obsidian] Backlinks" },
		{ "<leader>og", "<cmd>Obsidian tags<cr>", desc = "[Obsidian] Tags" },
		{ "<leader>oT", "<cmd>Obsidian toc<cr>", desc = "[Obsidian] Table of contents" },
		{ "<leader>oc", "<cmd>Obsidian toggle_checkbox<cr>", desc = "[Obsidian] Toggle checkbox" },
		{ "<leader>ow", "<cmd>Obsidian workspace<cr>", desc = "[Obsidian] Switch workspace" },
		{ "<leader>ol", "<cmd>Obsidian link<cr>", mode = "v", desc = "[Obsidian] Link selection to note" },
	},
	---@module 'obsidian'
	---@type obsidian.config
	opts = {
		legacy_commands = false,
		workspaces = {
			{ name = "personal", path = "~/Documents/Obsidian Vault" },
		},
		picker = { name = "telescope.nvim" },
		-- enter_note runs after the plugin's own conceallevel check, so the warning it
		-- would emit is a false alarm -- suppress it rather than concealing all markdown.
		ui = { ignore_conceal_warn = true },
		callbacks = {
			-- Concealed link and reference syntax renders only at 'conceallevel' 1 or 2;
			-- scope it to vault notes so other markdown still shows literal syntax.
			enter_note = function()
				vim.opt_local.conceallevel = 2
			end,
		},
	},
}
