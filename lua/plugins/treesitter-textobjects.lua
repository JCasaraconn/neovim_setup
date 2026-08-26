-- Syntax-aware select / move / swap. Deliberately on the `main` branch and
-- standalone: nvim-treesitter's `master` query module calls iter_matches with
-- the removed `all = false` option, so its textobjects path is broken on
-- Neovim 0.11+. This branch ships its own queries and uses the current API.
local select_obj = function(query, group)
	return function()
		require("nvim-treesitter-textobjects.select").select_textobject(query, group or "textobjects")
	end
end

local move_to = function(fn, query)
	return function()
		require("nvim-treesitter-textobjects.move")[fn](query, "textobjects")
	end
end

local swap_with = function(fn, query)
	return function()
		require("nvim-treesitter-textobjects.swap")[fn](query)
	end
end

local selects = {
	["aa"] = "@parameter.outer",
	["ia"] = "@parameter.inner",
	["af"] = "@function.outer",
	["if"] = "@function.inner",
	["ac"] = "@class.outer",
	["ic"] = "@class.inner",
}

local moves = {
	goto_next_start = { ["]m"] = "@function.outer", ["]]"] = "@class.outer" },
	goto_next_end = { ["]M"] = "@function.outer", ["]["] = "@class.outer" },
	goto_previous_start = { ["[m"] = "@function.outer", ["[["] = "@class.outer" },
	goto_previous_end = { ["[M"] = "@function.outer", ["[]"] = "@class.outer" },
}

return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("nvim-treesitter-textobjects").setup({
			select = { lookahead = true },
			move = { set_jumps = true },
		})

		for lhs, query in pairs(selects) do
			vim.keymap.set({ "x", "o" }, lhs, select_obj(query), { desc = "[Textobj] Select " .. query })
		end

		for fn, keys in pairs(moves) do
			for lhs, query in pairs(keys) do
				-- Filetypes whose ftplugin maps these (python, etc.) keep their
				-- buffer-local version, which does the equivalent jump; these
				-- apply everywhere else. Upstream suggests vim.g.no_plugin_maps
				-- to force the issue, but that disables every ftplugin mapping.
				vim.keymap.set({ "n", "x", "o" }, lhs, move_to(fn, query), { desc = "[Textobj] " .. fn .. " " .. query })
			end
		end

		-- Upstream uses <leader>a/<leader>A, which is claudecode.nvim's prefix.
		vim.keymap.set("n", "<leader>p", swap_with("swap_next", "@parameter.inner"), { desc = "[Textobj] Swap next parameter" })
		vim.keymap.set("n", "<leader>P", swap_with("swap_previous", "@parameter.inner"), { desc = "[Textobj] Swap previous parameter" })
	end,
}
