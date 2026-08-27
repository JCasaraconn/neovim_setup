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
		-- Pinned so the URL and the SSH forward aimed at it stay stable; mkdp otherwise
		-- derives a fresh port from the clock each session. 8765 is clear of 8091 and
		-- 9341, the only listeners in that range here.
		vim.g.mkdp_port = "8765"

		if vim.env.DISPLAY and vim.env.DISPLAY ~= "" then
			return
		end
		-- No X display, so this is an SSH or bare console session and a browser started
		-- here would have nowhere to draw. The server is left on its default 127.0.0.1
		-- and mkdp addresses it as localhost, so the note is never exposed to the
		-- network; reach it by forwarding the port from the machine running the browser:
		--     ssh -L 8765:localhost:8765 <this host>
		-- mkdp_browserfunc then hands the URL back instead of launching anything, and
		-- writing it to "+ pushes it through the OSC 52 provider onto that machine's
		-- clipboard.
		vim.g.mkdp_browserfunc = "MkdpPreviewUrl"
		vim.cmd([[
			function! MkdpPreviewUrl(url) abort
				let @+ = a:url
				echomsg 'Markdown preview (URL copied): ' . a:url
			endfunction
		]])
	end,
}
