local function graphical_display()
	if vim.env.DISPLAY and vim.env.DISPLAY ~= "" then
		return vim.env.DISPLAY
	end
	-- A tmux server outlives the session that started it, so a pane attached at the
	-- console still carries the environment the server was born with -- here, an SSH
	-- session's, with no DISPLAY. Ask the X sockets who is logged in graphically
	-- instead of trusting what was inherited.
	local uid = vim.uv.getuid()
	local numbers = {}
	for name in vim.fs.dir("/tmp/.X11-unix") do
		local number = name:match("^X(%d+)$")
		local stat = number and vim.uv.fs_stat("/tmp/.X11-unix/" .. name)
		if stat and stat.uid == uid then
			table.insert(numbers, tonumber(number))
		end
	end
	table.sort(numbers)
	return numbers[1] and ":" .. numbers[1] or nil
end

_G.MkdpPreviewOpen = function(url)
	local display = graphical_display()
	if display then
		local browser = vim.g.mkdp_browser
		if not browser or browser == "" then
			browser = "xdg-open"
		end
		vim.system({ browser, url }, { env = { DISPLAY = display }, detach = true })
		return
	end
	-- Nowhere to draw, so this is a real SSH or bare console session. The server stays
	-- on its default 127.0.0.1 and mkdp addresses it as localhost, so the note is never
	-- exposed to the network; reach it by forwarding the port from the machine running
	-- the browser:
	--     ssh -L 8765:localhost:8765 <this host>
	-- Writing the URL to "+ pushes it through the OSC 52 provider onto that machine's
	-- clipboard.
	vim.fn.setreg("+", url)
	vim.notify("Markdown preview (URL copied): " .. url)
end

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

		-- mkdp's own opener would spawn the browser from the node server, which inherits
		-- nvim's environment and so hits the same missing DISPLAY.
		vim.g.mkdp_browserfunc = "MkdpOpenPreview"
		vim.cmd([[
			function! MkdpOpenPreview(url) abort
				call v:lua.MkdpPreviewOpen(a:url)
			endfunction
		]])
	end,
}
