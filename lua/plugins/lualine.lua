return {
	{
		"nvim-lualine/lualine.nvim",
    event = "VeryLazy", -- load this after critical plugins
		config = function()
			require("lualine").setup({
				options = {
					theme = "onedark",
				},
			})
		end,
	},
}
