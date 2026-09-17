local function bundle_flavour()
	local path = vim.fn.expand("~/.config/theme/nvim.lua")
	if not (vim.uv or vim.loop).fs_stat(path) then
		return "mocha"
	end

	local ok, bundle = pcall(dofile, path)
	if not ok or type(bundle) ~= "table" or type(bundle.flavour) ~= "string" then
		vim.notify(path .. ": no usable flavour, falling back to mocha", vim.log.levels.WARN)
		return "mocha"
	end
	return bundle.flavour
end

return {
	"catppuccin/nvim",
	name = "catppuccin",
	tag = "v2.0.0",
	priority = 1000,
	config = function()
		local flavour = bundle_flavour()

		require("catppuccin").setup({
			flavour = flavour,
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
		local palette = require("catppuccin.palettes").get_palette(flavour)
		for slot, color in ipairs(ansi_slots) do
			vim.g["terminal_color_" .. (slot - 1)] = palette[color]
		end
	end,
}
