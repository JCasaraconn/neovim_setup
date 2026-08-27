return {
	"obsidian-nvim/obsidian.nvim",
	-- Tracking main until a release past v3.16.6: that tag calls
	-- vim.pos.cursor(0), but Neovim 0.12 takes (buf, pos), so Obsidian toc
	-- throws "attempt to index local 'pos' (a nil value)". Fixed upstream in
	-- ead02ee. Return to version = "*" once a newer tag ships.
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
			{ name = "personal", path = require("vault") },
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
	config = function(_, opts)
		-- obsidian skips its own renderer whenever it finds render-markdown.nvim on the
		-- runtimepath, so drive ui.setup directly to keep the vault on obsidian's
		-- rendering while render-markdown handles every note outside it. Registered
		-- before setup() because the event fires during it. The plugin emits the
		-- misspelled pattern; its docs promise the other, so match both.
		vim.api.nvim_create_autocmd("User", {
			pattern = { "ObsidianWorkpspaceSet", "ObsidianWorkspaceSet" },
			callback = function()
				-- Read the workspace from the global, not the event payload: autocmd data
				-- loses metatables, and ui.setup needs Path.__tostring to build its
				-- "<vault>/**.md" pattern -- a stripped root yields "table: 0x..." and
				-- silently matches nothing.
				require("obsidian.ui").setup(Obsidian.workspace, Obsidian.opts.ui)
			end,
		})
		require("obsidian").setup(opts)
	end,
}
