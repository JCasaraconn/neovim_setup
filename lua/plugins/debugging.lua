return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"rcarriga/nvim-dap-ui",
		"leoluz/nvim-dap-go",
		"tpope/vim-fugitive",
		"tpope/vim-rhubarb",
		"mfussenegger/nvim-dap-python",
		"theHamsta/nvim-dap-virtual-text",

		-- Detect tabstop and shiftwidth automatically
		"tpope/vim-sleuth",

		-- Useful plugin to show you pending keybinds.
		{ "folke/which-key.nvim", opts = {} },

		-- "gc" to comment visual regions/lines
		{ "numToStr/Comment.nvim", opts = {} },
	},
	config = function()
		require("dapui").setup()
		require("nvim-dap-virtual-text").setup({
			commented = true, -- Show virtual text alongside comment
		})
		require("dap-go").setup()

		local function get_conda_python()
			local env = os.getenv("CONDA_PREFIX")
			if env then
				return env .. "/bin/python"
			else
				return "python"
			end
		end

		require("dap-python").setup(get_conda_python())

		local dap, dapui = require("dap"), require("dapui")

		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		-- vim.keymap.set("n", "<Leader>dt", ":DapToggleBreakpoint<CR>")
		-- vim.keymap.set("n", "<Leader>dc", ":DapContinue<CR>")
		-- vim.keymap.set("n", "<Leader>dx", ":DapTerminate<CR>")
		-- vim.keymap.set("n", "<Leader>do", ":DapStepOver<CR>")

		vim.fn.sign_define("DapBreakpoint", {
			text = "",
			texthl = "DiagnosticSignError",
			linehl = "",
			numhl = "",
		})

		vim.fn.sign_define("DapBreakpointRejected", {
			text = "", -- or "❌"
			texthl = "DiagnosticSignError",
			linehl = "",
			numhl = "",
		})

		vim.fn.sign_define("DapStopped", {
			text = "", -- or "→"
			texthl = "DiagnosticSignWarn",
			linehl = "Visual",
			numhl = "DiagnosticSignWarn",
		})

		-- Automatically open/close DAP UI
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end

		local opts = { noremap = true, silent = true }

		-- Toggle breakpoint
		vim.keymap.set("n", "<leader>db", function()
			dap.toggle_breakpoint()
		end, { desc = "Toggle Breakpoint" }, opts)

		-- Continue / Start
		vim.keymap.set("n", "<leader>dc", function()
			dap.continue()
		end, { desc = "Continue" }, opts)

		-- Step Over
		vim.keymap.set("n", "<leader>do", function()
			dap.step_over()
		end, { desc = "Step Over" }, opts)

		-- Step Into
		vim.keymap.set("n", "<leader>di", function()
			dap.step_into()
		end, { desc = "Step In" }, opts)

		-- Step Out
		vim.keymap.set("n", "<leader>dO", function()
			dap.step_out()
		end, { desc = "Step Out" }, opts)

		-- Keymap to terminate debugging
		vim.keymap.set("n", "<leader>dq", function()
			require("dap").terminate()
		end, { desc = "Terminate Debugging" }, opts)

		-- Toggle DAP UI
		vim.keymap.set("n", "<leader>du", function()
			dapui.toggle()
		end, { desc = "Toggle DAP UI" }, opts)
	end,
}
