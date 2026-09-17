local venv = vim.fn.stdpath("data") .. "/nvim-ghost-venv"
local python = venv .. "/bin/python"

return {
	"subnut/nvim-ghost.nvim",
	-- The released binary bundles a runtime built against glibc 2.33, which
	-- Ubuntu 20.04's 2.31 cannot load, so the server dies the instant nvim spawns
	-- it. Script mode runs the same server from binary.py instead, off a venv
	-- pinned to the system python so it survives conda env switches. Falling
	-- through without that venv would only re-download the broken binary.
	build = function(plugin)
		local out = vim.fn.system({ "/usr/bin/python3", "-m", "venv", venv })
		assert(vim.v.shell_error == 0, "nvim-ghost.nvim: venv creation failed\n" .. out)
		out = vim.fn.system({ python, "-m", "pip", "install", "-r", plugin.dir .. "/requirements.txt" })
		assert(vim.v.shell_error == 0, "nvim-ghost.nvim: pip install failed\n" .. out)
	end,
	init = function()
		if vim.uv.fs_stat(python) then
			vim.g.nvim_ghost_use_script = 1
			vim.g.nvim_ghost_python_executable = python
		else
			vim.g.nvim_ghost_disabled = 1
		end
	end,
}
