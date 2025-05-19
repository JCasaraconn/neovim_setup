local uv = vim.loop
local cmp = require("cmp")

local M = {}
M.__index = M

-- Configuration
local LOG_ENABLED = false
local log_path = vim.fn.stdpath("config") .. "/jedi_source.log"
local python_cmd = vim.fn.trim(vim.fn.system("which python"))
local script_path = vim.fn.stdpath("config") .. "/lua/plugins/jedi-cmp/scripts/jedi_complete.py"

-- Logging utility
local function log(msg)
	if not LOG_ENABLED then
		return
	end
	local fd = uv.fs_open(log_path, "a", 438) -- 0o666
	if fd then
		uv.fs_write(fd, os.date("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
		uv.fs_close(fd)
	end
end

log("Using python at: " .. python_cmd)

-- Create a new Jedi completion source
function M.new()
	local self = setmetatable({}, M)

	self.stdin = uv.new_pipe(false)
	self.stdout = uv.new_pipe(false)
	self.stderr = uv.new_pipe(false)
	self.handle = nil
	self.buf = ""
	self.pending_callback = nil

	log("Starting Python Jedi daemon: " .. python_cmd .. " " .. script_path)

	-- Spawn the Python process
	self.handle = uv.spawn(python_cmd, {
		args = { script_path },
		stdio = { self.stdin, self.stdout, self.stderr },
	}, function(code, signal)
		log(string.format("Python Jedi daemon exited with code %d, signal %d", code, signal))
		if self.pending_callback then
			self.pending_callback({ items = {}, isIncomplete = false })
			self.pending_callback = nil
		end
		self.stdin:close()
		self.stdout:close()
		self.stderr:close()
		self.handle:close()
		self.handle = nil
	end)

	-- Handle stdout (line-based JSON messages)
	self.stdout:read_start(function(err, chunk)
		if err then
			log("Error reading stdout: " .. err)
			if self.pending_callback then
				self.pending_callback({ items = {}, isIncomplete = false })
				self.pending_callback = nil
			end
			return
		end
		if not chunk then
			return
		end

		self.buf = self.buf .. chunk
		while true do
			local nl_pos = self.buf:find("\n")
			if not nl_pos then
				break
			end

			local line = self.buf:sub(1, nl_pos - 1)
			self.buf = self.buf:sub(nl_pos + 1)

			if line == "" then
				log("Skipping empty line")
			else
				local ok, res = pcall(vim.json.decode, line)
				if ok then
					log("Received JSON response: " .. vim.inspect(res))
					if self.pending_callback then
						local items = {}
						for _, c in ipairs(res) do
							table.insert(items, {
								label = c.name,
								kind = cmp.lsp.CompletionItemKind[c.type:sub(1, 1):upper() .. c.type:sub(2)]
										or cmp.lsp.CompletionItemKind.Text,
								detail = c.signature ~= "" and c.signature or nil,
								documentation = {
									kind = "markdown",
									value = c.docstring,
								} or nil,
							})
						end
						self.pending_callback({ items = items, isIncomplete = false })
						log("Completion callback invoked with " .. tostring(#items) .. " items")
						self.pending_callback = nil
					else
						log("No pending callback")
					end
				else
					log("JSON parse failed: " .. tostring(res))
					log("Offending line: " .. line)
				end
			end
		end
	end)

	-- Handle stderr
	self.stderr:read_start(function(_, chunk)
		if chunk then
			log("Python stderr: " .. chunk:gsub("\n", " "))
		end
	end)

	return self
end

-- Completion entry point
function M:complete(request, callback)
	local line = request.context.cursor_before_line
	local cursor_col = request.context.cursor.col

	if not line:sub(cursor_col - 1, cursor_col - 1):match("%.") then
		return callback() -- only trigger after "."
	end

	log("Completion triggered on line: " .. line)

	if line == "" or not self.handle then
		log("No input or daemon not running")
		callback({ items = {}, isIncomplete = false })
		return
	end

	if self.pending_callback then
		log("Previous request still pending")
		callback({ items = {}, isIncomplete = false })
		return
	end

	self.pending_callback = callback
	log("Sending line to Jedi daemon: " .. line)
	self.stdin:write(line .. "\n")
end

-- Required methods for cmp source
function M:get_trigger_characters()
	return { "." }
end

function M:resolve(completion_item, callback)
	callback(completion_item)
end

function M:execute() end

return M
