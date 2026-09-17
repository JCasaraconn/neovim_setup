return {
	"catppuccin/nvim",
	name = "catppuccin",
	tag = "v2.0.0",
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			integrations = {
				fidget = true,
				harpoon = true,
				mason = true,
				snacks = { enabled = true },
				which_key = true,
			},
		})
		vim.cmd.colorscheme("catppuccin-nvim")

		-- catppuccin/alacritty's ANSI slots, so :terminal buffers match the outer terminal exactly
		local ansi_slots = {
			"surface1", "red", "green", "yellow", "blue", "pink", "teal", "subtext1",
			"surface2", "red", "green", "yellow", "blue", "pink", "teal", "subtext0",
		}
		local palette = require("catppuccin.palettes").get_palette("mocha")
		for slot, color in ipairs(ansi_slots) do
			vim.g["terminal_color_" .. (slot - 1)] = palette[color]
		end
	end,
}
