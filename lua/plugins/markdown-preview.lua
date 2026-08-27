return {
	"iamcco/markdown-preview.nvim",
	cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
	ft = "markdown",
	keys = {
		{ "<leader>mb", "<cmd>MarkdownPreviewToggle<cr>", desc = "[Markdown] Toggle browser preview" },
	},
	-- mkdp#util#install downloads a prebuilt server binary that segfaults here
	-- (exit 139): its bundled runtime targets a newer base than Ubuntu 20.04's
	-- glibc 2.31. Build from source instead so rpc.vim falls through to its
	-- system-node branch, which it only reaches when no prebuilt binary is present.
	build = function(plugin)
		local app = plugin.dir .. "/app"
		vim.fn.delete(app .. "/bin", "rf")
		local out = vim.fn.system({ "npx", "--yes", "yarn", "install", "--cwd", app })
		assert(vim.v.shell_error == 0, "markdown-preview.nvim: yarn install failed\n" .. out)
	end,
	init = function()
		-- Pinned so the preview URL, and any firewall or SSH-forward rule pointing at
		-- it, stay stable; mkdp otherwise derives a fresh port from the clock each
		-- session. 8765 is clear of 8091 and 9341, which are already in use here.
		vim.g.mkdp_port = "8765"

		if vim.env.DISPLAY and vim.env.DISPLAY ~= "" then
			return
		end
		-- No X display, so this is an SSH or bare console session and launching a
		-- browser here has nowhere to draw. Serve on 0.0.0.0 instead -- mkdp then fills
		-- the URL host from this machine's LAN address -- and hand the URL back rather
		-- than opening anything. Writing it to "+ pushes it through the OSC 52 provider
		-- onto the clipboard of whichever machine is driving the terminal.
		vim.g.mkdp_open_to_the_world = 1
		vim.g.mkdp_browserfunc = "MkdpPreviewUrl"
		vim.cmd([[
			function! MkdpPreviewUrl(url) abort
				let @+ = a:url
				echomsg 'Markdown preview (URL copied): ' . a:url
			endfunction
		]])
	end,
}
