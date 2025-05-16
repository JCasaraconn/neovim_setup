local source = {}

source.new = function()
	return setmetatable({}, { __index = source })
end

source.complete = function(self, request, callback)
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local before_cursor = line:sub(1, col)
	local expr = before_cursor:match("([%w_%.]+)$") or ""

	local script_path = vim.fn.stdpath("config") .. "/lua/scripts/jedi_complete.py"

	vim.fn.jobstart({ "python3", script_path, expr }, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if not data then
				return
			end

			local output = table.concat(data, "\n")
			if output == "" then
				return
			end

			local ok, decoded = pcall(vim.fn.json_decode, output)
			if not ok then
				vim.notify("JSON decode failed", vim.log.levels.ERROR)
				return
			end

			local items = {}
			for _, entry in ipairs(decoded) do
				table.insert(items, {
					label = entry.name,
					kind = require("cmp.types.lsp").CompletionItemKind[entry.type:upper()] or 1,
					documentation = entry.description,
				})
			end

			callback({ items = items, isIncomplete = false })
		end,

		on_stderr = function(_, data)
			if data then
				vim.notify("Jedi stderr: " .. table.concat(data, "\n"), vim.log.levels.WARN)
			end
		end,

		on_exit = function(_, code)
			if code ~= 0 then
				vim.notify("Jedi script failed with code: " .. code, vim.log.levels.ERROR)
			end
		end,
	})
end

return source
